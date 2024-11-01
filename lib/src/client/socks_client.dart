import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';

import '../../exceptions.dart';
import '../address_type.dart';
import '../enums/authentication_method.dart';
import '../enums/command_reply_code.dart';
import '../enums/socks_connection_type.dart';
import '../exceptions/client/connection_command_failed_exception.dart';
import '../mixin/byte_reader.dart';
import '../mixin/socket_mixin_.dart';
import '../mixin/stream_mixin.dart';
import '../shared/lookup.dart';
import '../shared/proxy_settings.dart';
import 'socks_command_response.dart';

class SocksClientInitializeResult {
  SocksClientInitializeResult(this.socket, this.response);

  final SocksSocket socket;
  final SocksCommandResponse response;

  @override
  String toString() => '$response';
}

class SocksSocket with StreamMixin<Uint8List>, SocketMixin, ByteReader {
  /// Internal constructor
  @protected
  SocksSocket.protected(this.socket, this.type);

  final SocksConnectionType type;

  /// Can be overridden/set to be custom domain lookup function.
  LookupFunction lookup = InternetAddress.lookup;

  @override
  Socket socket;

  ChunkedStreamReader<int>? _data;

  @override
  ChunkedStreamReader<int> get data => _data ??= ChunkedStreamReader(stream);

  /// Multi-subscription socket stream.
  Stream<Uint8List>? _broadcast;

  @override
  Stream<Uint8List> get stream => _broadcast ??= socket.asBroadcastStream();

  @internal
  static Future<SocksClientInitializeResult> initialize(
    List<ProxySettings> proxies,
    InternetAddress address,
    int port,
    SocksConnectionType type,
  ) async {
    if(proxies.isEmpty) {
      throw ArgumentError.value(proxies, 'proxies', 'empty');
    }
    final first = proxies.first;
    final Socket socket;
    if (first.context != null)
      socket = await SecureSocket.connect(first.host, first.port);
    else  
      socket = await Socket.connect(proxies.first.host, proxies.first.port);
  
    final client = SocksSocket.protected(socket, type);

    try {
      await client._handshake(proxies.first);

      for(var i = 1; i < proxies.length; i++) {
        await client._handleCommand(proxies[i].host, proxies[i].port, SocksConnectionType.connect);
        final response = await client._handleCommandResponse(SocksConnectionType.connect);
        if(response.address != InternetAddress('0.0.0.0') || response.port != 0) {
          throw UnimplementedError('Connect associated proxy not yet implemented.');
        }
        await client._handshake(proxies[i]);
      }

      await client._handleCommand(address, port, type);

      final response = await client._handleCommandResponse(type);
      
      return SocksClientInitializeResult(client, response);
    } on ByteReaderException catch (error, stackTrace) {
      socket.close().ignore();
      throw SocksClientConnectionClosedException((error: error, stackTrace: stackTrace));
    }
  }

  // Apply tls-over-http
  Future<SecureSocket> secure(dynamic host, {
    SecurityContext? context,
    bool Function(X509Certificate certificate)? onBadCertificate,
    void Function(String line)? keyLog,
    List<String>? supportedProtocols,
    }) async {
    final secureSocket = await SecureSocket.secure(socket,
      host: host, 
      context: context,
      onBadCertificate: onBadCertificate,
      keyLog: keyLog,
      supportedProtocols: supportedProtocols,
    );  
    socket = secureSocket;

    _broadcast = socket.asBroadcastStream();
    return secureSocket;
  }
 
  /// Socks handshake.
  Future<void> _handshake(ProxySettings proxy) async {
    final authenticationMethods = [
      AuthenticationMethod.noAuthenticationRequired,
    ];

    if (proxy.username != null && proxy.password != null) {
      authenticationMethods.add(AuthenticationMethod.password);
    }

    add(
      Uint8List.fromList([
        0x05,
        authenticationMethods.length,
        for (final method in authenticationMethods) method.byte,
      ]),
    );

    await flush();

    if (await readUint8() != 0x05) {
      close().ignore();
      throw Exception('Unsupported socks version.');
    }
    final authenticationMethod = await readUint8();

    if (authenticationMethod ==
        AuthenticationMethod.noAuthenticationRequired.byte) {
      return;
    } else if (authenticationMethod == AuthenticationMethod.password.byte) {
      return _auth(proxy.username!, proxy.password!);
    }

    return;
  }

  Future<void> _auth(String username, String password) async {
    final encodedUsername = utf8.encode(username);
    final encodedPassword = utf8.encode(password);

    add(
      Uint8List.fromList([
        0x01,
        encodedUsername.length,
        ...encodedUsername,
        encodedPassword.length,
        ...encodedPassword,
      ]),
    );
    await flush();

    // Checking authentication version.
    if (await readUint8() != 0x01) {
      close().ignore();
      throw Exception('Unsupported user/pass authentication version.');
    }
    // Checking authentication response, 0x00 - succeed, other - failed.
    if (await readUint8() != 0x00) {
      close().ignore();
      throw Exception('Authentication failed.');
    }
  }

  /// Handle socks command.
  Future<void> _handleCommand(
    InternetAddress targetAddress,
    int targetPort, 
    SocksConnectionType type,
  ) async {
    final addressType =
        AddressType.internetAddressTypeMap[targetAddress.type]!;
    final rawAddress = targetAddress.rawAddress;

    add(
      Uint8List.fromList([
        0x05, // Socks version.
        type.byte, // Socks connection type.
        0x00, // Reserved
        addressType.byte,
        // Encoding address, if domain adding length at the beginning.
        if (addressType == AddressType.domain) rawAddress.length,
        ...rawAddress,
        // Encoding port as big endian short.
        (targetPort & 0xff00) >> 8, targetPort & 0x00ff,
      ]),
    );
    await flush();
  }

  Future<SocksCommandResponse> _handleCommandResponse(SocksConnectionType type) async {
    final version = await readUint8();
    if(version != 0x05)
      throw Exception('Unsupported Socks Version');
    final commandResponse = CommandReplyCode.values[await readUint8()];
 
    if (commandResponse != CommandReplyCode.succeed) {
      close().ignore();
      throw SocksClientConnectionCommandFailedException(commandResponse);
    }

    // Read reserved byte.
    await readUint8();
    
    final addressType = AddressType.byteMap[await readUint8()]!;
    final address = await getAddress(addressType, lookup);
    final port = await readUint16();
    return SocksCommandResponse(version, commandResponse, addressType, address!, port);
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';

import '../address_type.dart';
import '../enums/authentication_method.dart';
import '../enums/command_reply_code.dart';
import '../enums/command_type.dart';
import '../enums/message.dart';
import '../enums/socks_connection_state.dart';
import '../enums/socks_connection_type.dart';
import '../mixin/byte_reader.dart';
import '../mixin/socket_mixin_.dart';
import '../mixin/stream_mixin.dart';
import '../shared/lookup.dart';
import 'auth_handler.dart';
import 'connection.dart';
import 'tcp_connection.dart';
import 'udp_connection.dart';

class SocksConnection with StreamMixin<Uint8List>, SocketMixin, ByteReader {
  SocksConnection(this.socket, {this.authHandler, this.lookup = InternetAddress.lookup});
  
  /// Can be overridden/set to be custom domain lookup function.
  LookupFunction lookup;

  @override
  final Socket socket;

  Stream<Uint8List>? _socketBroadcast;

  SocksConnectionType type = SocksConnectionType.none;
  SocksConnectionState state = SocksConnectionState.initial;

  late InternetAddress desiredAddress;

  late int desiredPort;

  @override
  Stream<Uint8List> get stream =>
      _socketBroadcast ??= socket.asBroadcastStream();

  ChunkedStreamReader<int>? _data;

  @override
  Future<void> close() async {
    await _data?.cancel();
    await super.close();
  }

  @override
  ChunkedStreamReader<int> get data => _data ??= ChunkedStreamReader(stream);

  /// Authentication handler.
  final AuthHandler? authHandler;

  /// Initialize connection.
  ///
  /// * Handshake
  /// * Authenticate
  /// * Handle command (connect/associate)
  Future<void> initialize() async {
    try {
      if (!await handshake()) {
        await reject(CommandReplyCode.connectionDenied);

        type = SocksConnectionType.none;

        return;
      }
      final response = await _handleCommand();
      if (response != null) {
        await reject(response);

        type = SocksConnectionType.none;

        return;
      }
    } catch (e) {
      return;
    } finally {
      await data.cancel();
      done.ignore();
    }
  }

  /// Socks handshake.
  Future<bool> handshake() async {
    if (state != SocksConnectionState.initial) {
      throw StateError(
        'Handshake cannot be called after initial negotiations is done.',
      );
    }

    state = SocksConnectionState.handshaking;
    await _checkSocksVersion();

    int authenticationMethodsCount;
    authenticationMethodsCount = await readUint8();

    List<int> authenticationMethods;
    authenticationMethods = await readBytes(authenticationMethodsCount);

    if (authHandler != null) {
      if (!authenticationMethods.contains(AuthenticationMethod.password.byte)) {
        // No available authentication methods
        add([
          0x05, // Socks version
          AuthenticationMethod.invalid.byte,
        ]);

        return false;
      } else {
        await _passwordAuth();
      }
    } else {
      // No auth
      await _noAuth();
    }

    return true;
  }

  /// Reject connection with optional [message].
  Future<void> reject([Message? message]) async {
    try {
      if (message != null) {
        add([
          0x05, // socks version
          message.byte, // response message
        ]); // error here
      }
    } finally {
      await close();
    }
  }

  Future<void> _checkSocksVersion() async {
    if (await readUint8() != 0x05) {
      throw Exception('Unsupported socks version.');
    }
  }

  /// Socks no authentication method.
  Future<void> _noAuth() async {
    state = SocksConnectionState.authenticating;

    add([
      0x05, // Socks version
      AuthenticationMethod.noAuthenticationRequired.byte,
    ]);
    await flush();

    state = SocksConnectionState.ready;

    return;
  }

  /// Socks password authentication method.
  Future<void> _passwordAuth() async {
    state = SocksConnectionState.authenticating;

    add([
      0x05, // Socks version
      AuthenticationMethod.password.byte,
    ]);
    await flush();

    if (await readUint8() != 0x01) {
      throw Exception('Unsupported username/password authentication version.');
    }

    final usernameLength = await readUint8();
    final username = utf8.decode(await readBytes(usernameLength));
    final passwordLength = await readUint8();
    final password = utf8.decode(await readBytes(passwordLength));

    if (!authHandler!(username, password)) {
      throw Exception('Authentication failed.');
    }

    add([
      0x01, // Authentication version
      0x00, // Succeeded
    ]);
    await flush();

    state = SocksConnectionState.ready;

    return;
  }

  /// Handle socks command.
  Future<CommandReplyCode?> _handleCommand() async {
    if (state != SocksConnectionState.ready) {
      throw StateError('Command handler called on unready state.');
    }

    await _checkSocksVersion();

    final commandByte = await readUint8();

    if (!CommandType.byteMap.containsKey(commandByte)) {
      return CommandReplyCode.unsupportedCommand;
    }
    final command = CommandType.byteMap[commandByte]!;

    switch (command) {
      case CommandType.connect:
        state = SocksConnectionState.connecting;
        type = SocksConnectionType.connect;
        break;
      case CommandType.associate:
        state = SocksConnectionState.associating;
        type = SocksConnectionType.associate;
        break;
      case CommandType.bind:
        // TODO: Bind command
        state = SocksConnectionState.binding;
        type = SocksConnectionType.bind;
        break;
    }

    // Read reserved byte
    if (await readUint8() != 0x00) 
      return CommandReplyCode.unsupportedCommand;

    final addressTypeByte = await readUint8();

    if (!AddressType.byteMap.containsKey(addressTypeByte)) {
      return CommandReplyCode.unsupportedAddressType;
    }

    final addressType = AddressType.byteMap[addressTypeByte]!;
    try {
      final address = await getAddress(addressType, lookup);
      if (address == null) 
        return CommandReplyCode.hostUnreachable;
      desiredAddress = address;
    } catch (e) {
      // Cannot lookup hostname
      return CommandReplyCode.hostUnreachable;
    }
    desiredPort = await readUint16();
    return null;
  }

  Connection getConnection() {
    switch (type) {
      case SocksConnectionType.connect:
        return this is TcpConnection
            ? this as TcpConnection
            : TcpConnection(this);
      case SocksConnectionType.associate:
        return this is UdpConnection
            ? this as UdpConnection
            : UdpConnection(this);
      default:
        throw UnimplementedError('Command.');
    }
  }

  @protected
  void absorbConnection(SocksConnection connection) {
    desiredAddress = connection.desiredAddress;
    desiredPort = connection.desiredPort;
    type = connection.type;
    state = connection.state;
    _socketBroadcast = connection._socketBroadcast;
    _data = connection._data;
  }
}

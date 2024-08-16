import 'dart:async';
import 'dart:io';

import '../client/socks_tcp_client.dart';
import '../enums/command_reply_code.dart';
import '../shared/proxy_settings.dart';
import 'connection.dart';
import 'socks_connection.dart';
import 'socks_server.dart';

/// Connected client connection emitted by [SocksServer] if client requested TCP connection.
class TcpConnection extends SocksConnection implements Connection {
  TcpConnection(this.connection, {super.authHandler, super.lookup}) : super(connection) {
    absorbConnection(connection);
  }

  final SocksConnection connection;

  @override
  Future<Socket?> accept({
    bool? connect,
    bool? allowIPv6,
  }) async {
    final Socket? target;

    final _connect = connect ?? false;
    final _allowIPv6 = allowIPv6 ?? false;

    if (_connect) {
      if(!_allowIPv6 && desiredAddress.type == InternetAddressType.IPv6) {
        add([
          0x05,
          CommandReplyCode.unsupportedAddressType.byte,
        ]);
        return null;
      }
      try {
        target = await Socket.connect(
          desiredAddress.type == InternetAddressType.unix
              ? ((await InternetAddress.lookup(desiredAddress.address))[0])
              : desiredAddress,
          desiredPort,
        );

        target.done.ignore();
      } catch (error) {
        print(error);
        await reject(CommandReplyCode.connectionRefused);
        return null;
      }
    } else {
      target = null;
    }

    add([
      0x05, // Socks version
      0x00, // Succeeded
      0x00, // Reserved byte
      0x01, // IPv4
      0x00, 0x00, 0x00, 0x00, // address 0.0.0.0
      0x00, 0x00, // port 0
    ]);
    await flush();

    return target;
  }

  @override
  Future<void> forward({
    bool? allowIPv6,
  }) async {
    // Accept proxy connection and connect to target
    final target = await accept(allowIPv6: allowIPv6, connect: true);
    if (target == null) 
      return;

    // "Link" streams
    unawaited(addStream(target)
      ..then((value) {
        close();  
      }).ignore(),);
    unawaited(target.addStream(this)
      ..then((value) {
        target.close();
      }).ignore(),);
  }

  @override
  Future<void> redirect(ProxySettings proxy) async {
    final client = await SocksTCPClient.connect([proxy], 
      desiredAddress.type == InternetAddressType.unix
        ? ((await InternetAddress.lookup(desiredAddress.address))[0])
        : desiredAddress,
      desiredPort,
      );
    
    add([
      0x05, // Socks version
      0x00, // Succeeded
      0x00, // Reserved byte
      0x01, // IPv4
      0x00, 0x00, 0x00, 0x00, // address 0.0.0.0
      0x00, 0x00, // port 0
    ]);
    await flush();

    // "Link" streams
    unawaited(addStream(client)
      ..then((value) {
        close();  
      }).ignore(),);
    unawaited(client.addStream(this)
      ..then((value) {
        client.close();
      }).ignore(),);
  }
}

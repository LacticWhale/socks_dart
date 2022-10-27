import 'dart:async';
import 'dart:io';

import '../../enums/command_reply_code.dart';
import '../client/socks_tcp_client.dart';
import '../shared/proxy_settings.dart';
import 'connection.dart';
import 'socks_connection.dart';

class TcpConnection extends SocksConnection implements Connection {
  TcpConnection(this.connection)
      : super(connection, connection.authHandler) {
    absorbConnection(connection);
  }

  final SocksConnection connection;

  @override
  Future<Socket?> accept([bool connect = false]) async {
    final Socket? target;

    if (connect) {
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
  Future<void> forward() async {
    // Accept proxy connection and connect to target
    final target = await accept(true);
    if (target == null) 
      return;

    // "Link" streams
    unawaited(addStream(target)
      ..then((value) {
        print('Target disconnects');
        close();
        // target.close();  
      }).catchError(() {}),);
    unawaited(target.addStream(this)
      ..then((value) {
        print('Client disconnects.');
        target.close();
        // close();
      }).catchError(() {}));
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
      }).catchError(() {}),);
    unawaited(client.addStream(this)
      ..then((value) {
        client.close();
      }).catchError(() {}));
  }
}

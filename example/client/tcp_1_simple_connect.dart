import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/enums.dart';
import 'package:socks5_proxy/exceptions.dart';
import 'package:socks5_proxy/socks_client.dart';

void main() async {
  const host = 'example.com';
  const port = 80;

  final address = InternetAddress(host, type: InternetAddressType.unix);

  final Socket proxySocket;
  try {
    // Connect to proxy
    proxySocket = await SocksTCPClient.connect(
      [
        ProxySettings(InternetAddress.loopbackIPv4, 1080, username: 'username', password: 'password'),
      ],
      address,
      port,
    );
  } on SocksClientConnectionClosedException catch (error) {
    // Underlying socket is already closed if it was opened by this point.
    
    // Be aware that other server (server of this packet tries to minimize this)
    // can close connection at any time without sending response to client.
    
    print(error);
    return;
  } on SocksClientConnectionCommandFailedException catch (error) {
    // Underlying socket is already closed if it was opened by this point.
    if (error.code == CommandReplyCode.connectionDenied) {
      print('Invalid username/password');
    } else {
      print(error);
    }

    return;
  }

  // Receive data from proxy
  proxySocket
    ..listen((event) {
      print(ascii.decode(event));

      exit(0);
    }, onError: (Object? error, StackTrace stackTrace) {
      print(error.runtimeType);
      print(stackTrace);
      exit(0);
    },)

    // Send data to client
    ..write(
      '''HEAD / HTTP/1.1
HOST: example.com
Connection: close


''',
    );

  Future.delayed(const Duration(seconds: 30), () {
    print('Timeout. Target haven\'t replied in given time.');
    exit(0);
  });
  try {
    await proxySocket.flush();
    await proxySocket.close();
  } catch (e, st) {
    print(e.runtimeType);
    print(st);
    exit(0);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:socks_proxy/socks_client.dart';

void main() async {
  const host = 'example.com';
  const port = 80;

  final InternetAddress address;
  try {
    // Lookup address
    address = (await InternetAddress.lookup(host))[0];
  } catch (e) {
    // Lookup failed
    return print(e);
  }

  final Socket proxySocket;
  try {
    // Connect to proxy
    proxySocket = await SocksTCPClient.connect(
      [
        ProxySettings(InternetAddress.loopbackIPv4, 1080),
      ],
      address,
      port,
    );
  } catch (e) {
    print(e);
    return;
  }

  // Receive data from proxy
  proxySocket
    ..listen((event) {
      print(ascii.decode(event));

      exit(0);
    })

    // Send data to client
    // proxyClient.add(Uint8List.fromList([0x01, 0x02, 0x03]));
    ..write(
      '''HEAD / HTTP/1.1
HOST: example.com
Connection: close


''',
    );
  await proxySocket.flush();
  await proxySocket.close();

  Future.delayed(const Duration(seconds: 30), () {
    print('Timeout. Target haven\'t replied in given time.');
    exit(0);
  });
}

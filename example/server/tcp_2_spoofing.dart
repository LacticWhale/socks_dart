import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/socks_server.dart';

void main() async {
  // Create server instance
  final proxy = SocksServer();
  final exampleIps = await InternetAddress.lookup('example.com');

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    if (connection is TcpConnection) {
      // Forward everything except connections to target
      if (!exampleIps.contains(connection.desiredAddress)) {
        // Apply default handler
        return connection.forward();
      }

      // Accept connection
      await connection.accept();

      const message =
          '<!doctype html><html><head><title>Spoofed</title></head><body>lol</body></html>';

      // Write headers and html
      connection.add(
        ascii.encode(
          '''HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Connection: close
Content-Length: ${message.length}

$message''',
        ),
      );

      // End client response
      await connection.close();
    } else {
      await connection.forward();
    }
  });

  // Bind servers
  await proxy.bind(InternetAddress.loopbackIPv4, 1080);
  await proxy.bind(InternetAddress.loopbackIPv4, 1081);
}

import 'dart:io';

import 'package:socks5_proxy/enums.dart';
import 'package:socks5_proxy/socks_server.dart';

void main() async {
  // Create server instance
  final proxy = SocksServer();
  final exampleDotComIps = await InternetAddress.lookup('example.com');

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    switch (connection.type) {
      case SocksConnectionType.connect:
        if (exampleDotComIps.contains(connection.desiredAddress)) {
          await connection.reject(CommandReplyCode.connectionDenied);
          print('Connection to example.com was blocked');
          return;
        }
        // Apply default handler
        await connection.forward();
      default:
        // Deny other type of connection
        await connection.reject(CommandReplyCode.unsupportedCommand);
    }
  });

  // Bind servers
  await proxy.bind(InternetAddress.loopbackIPv4, 1080);
  await proxy.bind(InternetAddress.loopbackIPv4, 1081);
}

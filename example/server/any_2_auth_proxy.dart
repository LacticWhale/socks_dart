import 'dart:async';
import 'dart:io';

import 'package:socks_proxy/secure_compare.dart';
import 'package:socks_proxy/socks_server.dart';

void main() {
  // Create server instance
  final proxy = SocksServer(
    authHandler: (username, password) =>
        // Secure compare only make sense with hashes!!!
        // It's not recommended to use it like below.
        secureCompare(username, 'abc') && secureCompare(password, '123'),
  );

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    // Apply default handler
    await connection.forward();
  });

  // Bind servers
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
}

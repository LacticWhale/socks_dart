import 'dart:async';
import 'dart:io';

import 'package:socks_proxy/socks_server.dart';

void main() {
  // Create server instance
  final proxy = SocksServer();

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    // Apply default handler
    await connection.forward();
  }).onError(print);

  // Bind servers
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
}

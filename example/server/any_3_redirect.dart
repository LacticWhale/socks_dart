import 'dart:async';
import 'dart:io';

import 'package:socks5_proxy/socks_server.dart';

Future<void> main() async {
  // Create server instance
  final proxy = SocksServer();
  final redirectProxy = SocksServer();

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    print('Direct ${connection.type.name}: ${connection.address.address}:${connection.port} -> ${connection.desiredAddress.address}:${connection.port}');    
    // Apply default handler
    await connection.redirect(ProxySettings(InternetAddress.loopbackIPv4, 1082));
  }).onError(print);

  redirectProxy.connections.listen((connection) async {
    print('Redirected ${connection.type.name}: ${connection.address.address}:${connection.port} -> ${connection.desiredAddress.address}:${connection.port}');    

    await connection.forward();
  });

  // Bind servers
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
  unawaited(redirectProxy.bind(InternetAddress.loopbackIPv4, 1082));
}

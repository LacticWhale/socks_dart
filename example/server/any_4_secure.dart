import 'dart:async';
import 'dart:io';

import 'package:socks5_proxy/socks_server.dart';

void main() {
  // Create server instance
  final proxy = SocksServer();

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    print('${connection.address.address}:${connection.port} ==> ${connection.desiredAddress.address}:${connection.desiredPort}');
    // Apply default handler
    await connection.forward(allowIPv6: false);
  }).onError(print);

  // Bind servers
  // Secured server.
  unawaited(proxy.bindSecure(InternetAddress.anyIPv6, 1080, SecurityContext()
    ..useCertificateChain('cert.pem')
    ..usePrivateKey('key.pem'),
    ),
  );
  // Unsecured server
  unawaited(proxy.bind(InternetAddress.anyIPv4, 1081));
}

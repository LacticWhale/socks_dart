import 'dart:async';
import 'dart:io';

import 'package:socks5_proxy/socks_server.dart';

void main() {
  // Create server instance
  final proxy = SocksServer(
    connectionTransform: 
      StreamTransformer.fromHandlers(
        handleData: (socket, sink) async => 
          sink.add(await SecureSocket.secureServer(socket, SecurityContext()/* Add certificate here */)),
      ),
    );

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    print('${connection.address.address}:${connection.port} ==> ${connection.desiredAddress.address}:${connection.desiredPort}');
    // Apply default handler
    await connection.forward(allowIPv6: false);
  }).onError(print);

  // Bind servers
  unawaited(proxy.bind(InternetAddress.anyIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.anyIPv4, 1081));
}

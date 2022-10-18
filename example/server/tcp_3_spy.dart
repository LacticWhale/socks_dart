import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:socks5_proxy/socks_server.dart';

StreamTransformer<Uint8List, Uint8List> printer(String prefix) =>
    StreamTransformer<Uint8List, Uint8List>.fromHandlers(
      handleData: (data, sink) {
        print(prefix);
        print(data);
        sink.add(data);
      },
    );

void main() {
  // Create server instance
  final proxy = SocksServer();

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    if (connection is TcpConnection) {
      final target = await connection.accept(true);
      if (target == null) 
        return;

      // "Link" streams
      target.addStream(connection.transform(printer('client: '))).ignore();
      connection.addStream(target.transform(printer('target: '))).ignore();
    } else {
      // Apply default handler
      await connection.forward();
    }
  });

  // Bind servers
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
}

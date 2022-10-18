import 'dart:async';
import 'dart:io';

import 'package:socks5_proxy/socks_server.dart';

void main() {
  // create server instance.
  final proxy = SocksServer();

  // Listen to all tcp and udp connections.
  proxy.connections.listen((connection) async {
    if (connection is TcpConnection) {
      await connection.forward();
    } else if (connection is UdpConnection) {
    final client = await connection.accept();
    // Create socket to listen data from client.
    final remote = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    // Listen for datagram from client.
    client.where((event) => event == RawSocketEvent.read).listen((event) {
      final packet = client.receiveSocksPacket();

      if (packet == null) 
        return;
      
      // Filter packets if client provided ip address and port.
      if (connection.desiredAddress.address == '0.0.0.0' &&
          (connection.desiredAddress != packet.clientAddress ||
              connection.desiredPort != packet.clientPort)) 
                return;

      remote.send(packet.data, packet.remoteAddress, packet.remotePort);
    });

    // Listen for datagram from remote.
    remote.where((event) => event == RawSocketEvent.read).listen((event) {
      final datagram = remote.receive();

      if (datagram == null) 
        return;

      // Create socks packet.
      final packet =
          SocksUpdPacket.create(datagram.address, datagram.port, datagram.data);
      
      // Send socks packet to proxy.
      client.send(packet.socksPacket, connection.desiredAddress, connection.desiredPort);
    });
    }
  });

  // Bind servers.
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
}

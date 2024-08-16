import 'dart:async';
import 'dart:io';

import '../client/socks_udp_client.dart';
import '../shared/proxy_settings.dart';
import '../shared/socks_udp_client_bound_socket.dart';
import '../shared/socks_udp_packet.dart';
import 'connection.dart';
import 'socks_connection.dart';
import 'socks_server.dart';

/// Connected client connection emitted by [SocksServer] if client requested UDP connection.
class UdpConnection extends SocksConnection implements Connection {
  UdpConnection(this.connection, {super.authHandler, super.lookup}) : super(connection) {
    absorbConnection(connection);
  }

  final SocksConnection connection;

  @override
  Future<SocksUdpClientBoundSocket> accept({
    bool? connect,
    bool? allowIPv6,
  }) async {
    final clientBoundSocket =
        SocksUdpClientBoundSocket(
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0),
    );

    add([
      0x05, // Socks version.
      0x00, // Succeeded.
      0x00, // Reserved byte.
      0x01, // IPv4 
      0x00, 0x00, 0x00, 0x00, // 0.0.0.0
      // Convert short port to big endian byte list.
      (clientBoundSocket.port & 0xff00) >> 8, clientBoundSocket.port & 0xff,
    ]);
    await flush();

    return clientBoundSocket;
  }

  @override
  Future<void> forward({
    bool? allowIPv6,
  }) async {
    final client = await accept();
    
    final remote =  await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    client.where((event) => event == RawSocketEvent.read).listen((event) {
      final packet = client.receiveSocksPacket();

      if (packet == null) 
        return;
      
      // Filter packets if client provided ip address and port.
      if (desiredAddress.address == '0.0.0.0' &&
          (desiredAddress != packet.clientAddress ||
              desiredPort != packet.clientPort)) 
                return;

      remote.send(packet.data, packet.remoteAddress, packet.remotePort);
    });

    remote.where((event) => event == RawSocketEvent.read).listen((event) {
      final datagram = remote.receive();

      if (datagram == null) 
        return;

      final packet =
          SocksUpdPacket.create(datagram.address, datagram.port, datagram.data);
      
      client.send(packet.socksPacket, desiredAddress, desiredPort);
    });
  }

  @override
  Future<void> redirect(ProxySettings proxy) async {
    final proxyClient = await SocksUDPClient.connect([proxy]);
    final client = await accept();


    client.transform(StreamTransformer<RawSocketEvent, SocksUpdPacket>.fromHandlers(
      handleData: (event, sink) {
        if(event != RawSocketEvent.read)
          return;
        
        final packet = client.receiveSocksPacket();
        if(packet == null) 
          return;

        sink.add(packet);
      },
    ),).listen((packet) => proxyClient.send(packet.socksPacket, proxy.host, proxy.port));

    proxyClient.transform(StreamTransformer<RawSocketEvent, SocksUpdPacket>.fromHandlers(
      handleData: (event, sink) {
        if(event != RawSocketEvent.read)
          return;
        
        final datagram = proxyClient.receive();
        if(datagram == null) 
          return;

        final packet = SocksUpdPacket.create(datagram.address, datagram.port, datagram.data);

        sink.add(packet);
      },
    ),).listen((packet) => proxyClient.send(packet.socksPacket, desiredAddress, desiredPort));
    

    throw UnimplementedError();
  }
}

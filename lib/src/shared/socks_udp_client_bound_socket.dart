import 'dart:io';

import '../mixin/raw_datagram_socket_mixin.dart';
import '../mixin/stream_mixin.dart';
import 'socks_udp_packet.dart';

class SocksUdpClientBoundSocket
    with StreamMixin<RawSocketEvent>, RawDatagramSocketMixin {
  SocksUdpClientBoundSocket(this.rawDatagramSocket);

  @override
  final RawDatagramSocket rawDatagramSocket;

  InternetAddress? clientAddress;
  int? clientPort;

  SocksUpdPacket? receiveSocksPacket() {
    final datagram = super.receive();
    if (datagram == null) 
      return null;

    final packet = SocksUpdPacket.tryParse(datagram.data);
    if (packet == null) 
      return null;

    packet
      ..clientAddress = datagram.address
      ..clientPort = datagram.port;
    return packet;
  }
  
  @override
  Stream<RawSocketEvent> get stream => rawDatagramSocket;
}

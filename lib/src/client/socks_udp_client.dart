import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../enums/socks_connection_type.dart';
import '../mixin/raw_datagram_socket_mixin.dart';
import '../mixin/stream_mixin.dart';
import '../shared/proxy_settings.dart';
import '../shared/socks_udp_packet.dart';
import 'socks_client.dart';
import 'socks_command_response.dart';

class SocksUDPClient with StreamMixin<RawSocketEvent>, RawDatagramSocketMixin {
  SocksUDPClient._internal(this.rawDatagramSocket, this.tcpSocket, this.commandResponse);

  final Socket tcpSocket;
  final SocksCommandResponse commandResponse;

  @override
  final RawDatagramSocket rawDatagramSocket;

  @override
  Stream<RawSocketEvent> get stream => rawDatagramSocket;

  @override
  void close() {
    unawaited(tcpSocket.close());
    super.close();
  }

  @override
  Datagram? receive() {
    final actual = super.receive();
    if (actual == null) 
      return null;
    final packet = SocksUpdPacket.parse(actual.data);
    return Datagram(packet.data, packet.remoteAddress, packet.remotePort);
  }

  // @override
  // int send(List<int> buffer, InternetAddress address, int port) => super.send(
  //     SocksUpdPacket.create(address, port, Uint8List.fromList(buffer)).socksPacket,
  //     commandResponse.address,
  //     commandResponse.port,
  //   );

  @override
  int send(List<int> buffer, InternetAddress address, int port) => super.send(
    SocksUpdPacket.create(address, port, Uint8List.fromList(buffer)).socksPacket,
    commandResponse.address,
    commandResponse.port,
  );

  static Future<SocksUDPClient> connect(List<ProxySettings> proxies) async {     
    final rawDatagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    final result = await SocksSocket.initialize(proxies, InternetAddress('0.0.0.0'), rawDatagramSocket.port, SocksConnectionType.associate);
    // return client.socket;

    print(result);

    return SocksUDPClient._internal(rawDatagramSocket, result.socket, result.response);
  }
}

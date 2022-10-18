import 'dart:io';
import 'dart:typed_data';

import '../address_type.dart';

class SocksUpdPacket {
  SocksUpdPacket.parse(List<int> packetData) {
    final uint8ListPacketData = Uint8List.fromList(packetData);
    final bytes = uint8ListPacketData.buffer.asByteData();
    var offset = 2;

    if (bytes.getUint8(offset++) != 0) {
      throw Exception('Fragmented packets not supported');
    }

    final remoteAddressType = bytes.getUint8(offset++);

    int length;
    if (remoteAddressType == AddressType.domain.byte) {
      length = bytes.getUint8(offset) + 1;
    } else {
      length = remoteAddressType == AddressType.ipv4.byte ? 4 : 16;
    }

    remoteAddress = InternetAddress.fromRawAddress(
      bytes.buffer.asUint8List(
        offset,
        length,
      ),
    );
    offset += length;

    remotePort = bytes.getUint16(offset);
    offset += 2;

    data = bytes.buffer.asUint8List(offset);
  }

  SocksUpdPacket.create(this.remoteAddress, this.remotePort, this.data);
  late InternetAddress remoteAddress;
  late int remotePort;
  late Uint8List data;

  InternetAddress? clientAddress;
  int? clientPort;

  static SocksUpdPacket? tryParse(List<int> packetData) {
    try {
      return SocksUpdPacket.parse(packetData);
    } catch (e) {
      return null;
    }
  }

  List<int> get socksPacket => [
        0x00, 0x00, // reserved bytes
        0x00, // fragment
        AddressType.internetAddressTypeMap[remoteAddress.type]!.byte,
        ...remoteAddress.rawAddress,
        ...[(remotePort & 0xff00) >> 8, remotePort & 0x00ff],
        ...data,
      ];
}

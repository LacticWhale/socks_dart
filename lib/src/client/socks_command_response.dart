import 'dart:io';

import '../../enums/command_reply_code.dart';
import '../address_type.dart';

class SocksCommandResponse {
  const SocksCommandResponse(this.version, this.commandResponse, this.addressType, this.address, this.port);

  final int version;
  final CommandReplyCode commandResponse;
  final AddressType addressType;
  final InternetAddress address;
  final int port;

  @override
  String toString() => 'Socks$version ResponseCode: $commandResponse\n$address:$port';
}

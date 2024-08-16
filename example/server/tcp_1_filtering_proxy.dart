import 'dart:io';
import 'dart:typed_data';

import 'package:socks5_proxy/socks_enums.dart';
import 'package:socks5_proxy/socks_server.dart';

bool testIPMask(InternetAddress address, List<int> mask) {
  // ignore: always_put_control_body_on_new_line
  if (mask.length != 4) throw RangeError('Mask size must be 4');

  final foldedRawAddress = foldToInt(address.rawAddress);

  return foldedRawAddress & foldToInt(mask) == foldedRawAddress;
}

// Fancy function to create int from Uint8List
int foldToInt(List<int> bytes, [Endian endian = Endian.big]) =>
    bytes.fold<List<int>>(
      <int>[
        0,
        if (endian == Endian.big) (bytes.length - 1) * 8 else 0,
      ],
      (previous, element) => <int>[
        previous[0] + (element << previous[1]),
        previous[1] + (endian == Endian.big ? -8 : 8),
      ],
    )[0];

void main() async {
  // Create server instance
  final proxy = SocksServer();
  final exampleDotComIps = await InternetAddress.lookup('example.com');

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    switch (connection.type) {
      case SocksConnectionType.connect:
        if (exampleDotComIps.contains(connection.desiredAddress)) {
          await connection.reject(CommandReplyCode.connectionDenied);
          print('Connection to example.com was blocked');
          return;
        }
        // Apply default handler
        await connection.forward();
      default:
        // Deny other type of connection
        await connection.reject(CommandReplyCode.unsupportedCommand);
        break;
    }
  });

  // Bind servers
  await proxy.bind(InternetAddress.loopbackIPv4, 1080);
  await proxy.bind(InternetAddress.loopbackIPv4, 1081);
}

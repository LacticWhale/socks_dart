import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:socks5_proxy/socks_server.dart';

final users = {
  'username': 'password'.hash(),
};

void main() {
  // Create server instance
  final proxy = SocksServer(
    authHandler: (username, password) => users[username]?.secureCompare(password.hash()) ?? false,
  );

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    // Apply default handler
    await connection.forward();
  });

  // Bind servers
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
}

/// Constant time comparison.
bool compareHashes(String a, String b) {
  if (a.codeUnits.length != b.codeUnits.length) {
    return false;
  }

  var r = 0;
  for (var i = 0; i < a.codeUnits.length; i++) {
    r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return r == 0;
}

extension on String {
  bool secureCompare(String other) => compareHashes(this, other);

  String hash() => sha256.convert(utf8.encode('password')).toString();
}

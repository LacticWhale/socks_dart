import 'dart:io';

/// Stores information to connect to socks server.
class ProxySettings {
  /// Creates proxy settings object
  ProxySettings(
    this.host,
    this.port, {
    this.password,
    this.username,
  });

  /// Proxy host
  final InternetAddress host;

  /// Proxy port
  final int port;

  /// Proxy password
  final String? password;

  /// Proxy username
  final String? username;

  @override
  String toString() {
    if (username != null || password != null) {
      return '$username:$username@$host:$port';
    } else {
      return '$host:$port';
    }
  }
}

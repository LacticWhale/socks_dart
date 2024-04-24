import 'dart:io';

class ProxySettings {
  /// Creates proxy settings object
  ProxySettings(
    this.host,
    this.port, {
    this.password,
    this.username,
  });

  /// Proxy host
  /// [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [connect] will perform a [InternetAddress.lookup] and try
  /// all returned [InternetAddress]es, until connected. Unless a
  /// connection was established, the error from the first failing connection is
  /// returned.
  final dynamic host;

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

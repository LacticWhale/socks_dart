import '../../client/socks_tcp_client.dart';
import '../../client/socks_udp_client.dart';

/// Exception thrown by [SocksTCPClient] or [SocksUDPClient].
abstract class SocksClientException implements Exception {
  const SocksClientException();
  
  String get message;

  @override
  String toString() => '[$runtimeType]: $message';
}

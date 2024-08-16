import '../../client/socks_client.dart';
import 'socks_client_exception.dart';


/// Exception thrown by [SocksSocket] if server closed connection during handshake.
class SocksClientConnectionClosedException extends SocksClientException {
  const SocksClientConnectionClosedException([this.originalException]);

  final ({Object? error, StackTrace stackTrace})? originalException;

  @override
  String get message => 'Server closed connection.';
}

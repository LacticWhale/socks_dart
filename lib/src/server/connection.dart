import '../../socks.dart';
import 'socks_connection.dart';

/// Generic socks connection interface.
abstract class Connection implements SocksConnection {
  /// Reject connection with optional [message].
  @override
  Future<void> reject([Message? message]);

  /// Accept connection.
  ///
  /// **TCP**: If [connect] is `true` this function will open connection
  /// to requested host.
  ///
  /// Mustn't throw any errors.
  Future<void> accept({
    bool? connect,
    bool? allowIPv6,
  });
  
  /// Redirects connection to given [proxy].
  Future<void> redirect(ProxySettings proxy);

  /// Apply default handler to connection.
  ///
  /// **TCP**: Forward connection to requested host.
  ///
  /// **UDP**: Forward connections to respective hosts.
  Future<void> forward({
    bool? allowIPv6,
  });
}

import 'dart:io';

import '../enums/socks_connection_type.dart';
import '../shared/proxy_settings.dart';
import 'socks_client.dart';


/// [Socket] wrapper for socks TCP connection.
class SocksTCPClient extends SocksSocket {
  SocksTCPClient._internal(Socket socket) : super.protected(socket, SocksConnectionType.connect);

  /// Assign http client connection factory to proxy connection.
  static void assignToHttpClient(
    HttpClient httpClient,
    List<ProxySettings> proxies,
  ) => assignToHttpClientWithSecureOptions(httpClient, proxies);

  /// Assign http client connection factory to proxy connection.
  /// 
  /// Applies [host], [context], [onBadCertificate],
  /// [keyLog] and [supportedProtocols] to [SecureSocket] if 
  /// connection is tls-over-http
  static void assignToHttpClientWithSecureOptions(
    HttpClient httpClient,
    List<ProxySettings> proxies,
    {
      dynamic host,
      SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      void Function(String line)? keyLog,
      List<String>? supportedProtocols,
    }
  ) {
    httpClient.connectionFactory =
      (uri, proxyHost, proxyPort) async {
        // Returns instance of SocksSocket which implements Socket
        final client = SocksTCPClient.connect(
          proxies,
          InternetAddress(uri.host, type: InternetAddressType.unix),
          uri.port,
        );
        
        // Secure connection after establishing Socks connection
        if(uri.scheme == 'https') {
          final Future<SecureSocket> secureClient;
          return ConnectionTask.fromSocket(secureClient = (await client).secure(
            uri.host, 
            context: context,
            onBadCertificate: onBadCertificate,
            keyLog: keyLog,
            supportedProtocols: supportedProtocols,
          ), () => _closeWhenConnected(secureClient),);
        }

        return ConnectionTask.fromSocket(client,
          () => _closeWhenConnected(client),);
      };
  }

  /// Closes the socket produced by [socket] once the connection completes.
  ///
  /// Used as the cancel callback of a [ConnectionTask]. [HttpClient] invokes
  /// it when a connection attempt times out or the client is closed while the
  /// attempt is still pending, and discards its result. A connection that
  /// subsequently fails therefore has no listener left for its error, so it is
  /// swallowed here instead of surfacing as an unhandled exception.
  static void _closeWhenConnected(Future<Socket> socket) =>
    socket.then((socket) => socket.close().ignore(), onError: (_) {}).ignore();

  /// Connects proxy client to given [proxies] with exit point of [host]\:[port].
  static Future<SocksSocket> connect(
    List<ProxySettings> proxies,
    InternetAddress host,
    int port,
  ) async {
    final client = await SocksSocket.initialize(proxies, host, port, SocksConnectionType.connect);
    return client.socket;
  }
}

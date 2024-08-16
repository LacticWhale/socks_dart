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
          ), () async => (await secureClient).close().ignore(),);
        }

        // SocketConnectionTask implements ConnectionTask<Socket>
        return ConnectionTask.fromSocket(client, 
          () async => (await client).close().ignore(),);
      };
  }

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

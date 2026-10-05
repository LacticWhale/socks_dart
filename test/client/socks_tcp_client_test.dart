import 'dart:async';
import 'dart:io';

import 'package:socks5_proxy/exceptions.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:test/test.dart';

/// Accepts connections and hands each socket to [onConnection] without
/// speaking any protocol unless told to.
class _ProxyStub {
  _ProxyStub(this.onConnection);

  final void Function(Socket socket) onConnection;
  late final ServerSocket _server;

  int get port => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(onConnection);
  }

  Future<void> stop() => _server.close();
}

HttpClient _proxiedClient(int proxyPort, {Duration? connectionTimeout}) {
  final client = HttpClient();
  if (connectionTimeout != null) {
    client.connectionTimeout = connectionTimeout;
  }
  SocksTCPClient.assignToHttpClient(client, [
    ProxySettings(InternetAddress.loopbackIPv4, proxyPort),
  ]);
  return client;
}

/// Gives a late failure on a cancelled connection time to surface. The test
/// zone reports any unhandled error as a test failure.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 200));

void main() {
  group('SocksTCPClient.assignToHttpClient cancellation', () {
    late _ProxyStub proxy;

    tearDown(() => proxy.stop());

    test('connection timeout followed by proxy disconnect', () async {
      final accepted = Completer<Socket>();
      proxy = _ProxyStub((socket) {
        socket.listen((_) {}); // Never answers the SOCKS greeting.
        accepted.complete(socket);
      });
      await proxy.start();

      final client = _proxiedClient(
        proxy.port,
        connectionTimeout: const Duration(milliseconds: 200),
      );
      await expectLater(
        client.getUrl(Uri.http('127.0.0.1', '/')),
        throwsA(isA<SocketException>()),
      );
      client.close(force: true);

      await (await accepted.future).close();
      await _settle();
    });

    test('client closed while SOCKS handshake is pending', () async {
      final accepted = Completer<Socket>();
      proxy = _ProxyStub((socket) {
        socket.listen((_) {});
        accepted.complete(socket);
      });
      await proxy.start();

      final client = _proxiedClient(proxy.port);
      final request = client.getUrl(Uri.http('127.0.0.1', '/'));
      final socket = await accepted.future;
      client.close(force: true);
      await socket.close();

      await expectLater(
        request,
        throwsA(isA<SocksClientConnectionClosedException>()),
      );
      await _settle();
    });

    test('client closed while TLS handshake is pending', () async {
      final tlsStarted = Completer<Socket>();
      proxy = _ProxyStub((socket) {
        var stage = 0;
        socket.listen((_) {
          switch (stage) {
            case 0:
              socket.add([0x05, 0x00]);
              stage = 1;
            case 1:
              socket.add([0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
              stage = 2;
            default:
              // TLS ClientHello arrived; never answer it.
              if (!tlsStarted.isCompleted) {
                tlsStarted.complete(socket);
              }
          }
        });
      });
      await proxy.start();

      final client = _proxiedClient(proxy.port);
      final request = client.getUrl(Uri.https('127.0.0.1', '/'));
      final socket = await tlsStarted.future;
      client.close(force: true);
      await socket.close();

      await expectLater(request, throwsA(isA<HandshakeException>()));
      await _settle();
    });
  });
}

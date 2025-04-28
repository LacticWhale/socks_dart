import 'dart:async';
import 'dart:developer';
import 'dart:io';

import '../shared/lookup.dart';
import 'auth_handler.dart';
import 'connection.dart';
import 'socks_connection.dart';

/// Socks server.
class SocksServer {
  /// Create new Socks server.
  SocksServer({this.authHandler, this.lookup = InternetAddress.lookup});

  /// Can be overridden/set to be custom domain lookup function.
  LookupFunction lookup;

  /// Connections controller.
  final _connectionsController = StreamController<Connection>();

  /// Client connections.
  Stream<Connection> get connections => _connectionsController.stream;

  /// Authentication handler.
  AuthHandler? authHandler;

  /// Map of proxy servers indexed by their port
  Map<int, ServerSocket> proxies = {};

  /// Map of proxy secure servers indexed by their port
  Map<int, SecureServerSocket> secureProxies = {};

  /// Setup listener for client connections.
  Future<void> _listenForClientConnections(Stream<Socket> server) async {
    server.listen(
      (client) async {
        SocksConnection? connection;

        connection = SocksConnection(
          client,
          authHandler: authHandler,
          lookup: lookup,
        );

        client.done.ignore();

        await connection.initialize();
        try {
          _connectionsController.add(connection.getConnection());
        } catch (e) {
          await connection.close();
        }
      },
      onError: (Object error, StackTrace stackTrace) =>
        log('_listenForClientConnections', error: error, stackTrace: stackTrace),
    );
  }

  /// Bind Socks server to given [address] and [port].
  Future<void> bind(InternetAddress address, int port) async {
    if (_isPortInUse(port))
      throw const SocketException('Port is already bound to a proxy server.');
    return addServerSocket(await ServerSocket.bind(address, port));
  }

  /// Bind Socks secure server to given [address] and [port].
  ///
  /// See [SecureServerSocket.bind] for detailed information on named arguments.
  Future<void> bindSecure(InternetAddress address, int port, SecurityContext context, {
    int backlog = 0,
    bool v6Only = false,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    List<String>? supportedProtocols,
    bool shared = false,
  }) async {
    if (_isPortInUse(port))
      throw const SocketException('Port is already bound to a proxy server.');
    return addSecureServerSocket(
      await SecureServerSocket.bind(address, port, context,
        backlog: backlog,
        v6Only: v6Only,
        requestClientCertificate: requestClientCertificate,
        requireClientCertificate: requireClientCertificate,
        supportedProtocols: supportedProtocols,
        shared: shared,
      ),
    );
  }

  /// Add already bound ServerSocket.
  Future<void> addServerSocket(ServerSocket server) async {
    if (_isPortInUse(server.port))
      throw const SocketException('Port is already bound to a proxy server.');
    proxies.addAll({server.port: server});
    unawaited(_listenForClientConnections(server));
  }

  /// Add already bound SecureServerSocket.
  Future<void> addSecureServerSocket(SecureServerSocket server) async {
    if (_isPortInUse(server.port))
      throw const SocketException('Port is already bound to a proxy server.');
    secureProxies.addAll({server.port: server});
    unawaited(_listenForClientConnections(server));
  }

  bool _isPortInUse(int port) => proxies.containsKey(port) || secureProxies.containsKey(port);

  /// Closes proxy server listening on [port]. To close all server use [closeAll] method.
  ///
  /// StreamController for [connections] will still be opened. To close it use [stop] method.
  Future<void> close(int port) async {
    await proxies[port]?.close();
  }

  /// Closes all proxy servers. To close specific server use [close] method.
  ///
  /// StreamController for [connections] will still be opened. To close it use [stop] method.
  Future<void> closeAll() async {
    for (final server in proxies.values)
      await server.close();

    proxies.clear();
  }

  /// Closes all connections and closes connection controller no more servers can be bound to this instance.
  ///
  /// Calls [closeAll] before closing [connections] stream.
  Future<void> stop() async {
    await closeAll();
    await _connectionsController.close();
  }
}

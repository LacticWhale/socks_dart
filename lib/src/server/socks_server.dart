import 'dart:async';
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

  /// Setup listener for client connections.
  Future<void> _listenForClientConnections(ServerSocket server) async {
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
      onError: (error, stackTrace) => null,
    );
  }

  /// Bind Socks server to given [address] and [port].
  Future<void> bind(InternetAddress address, int port) async {
    if (proxies.containsKey(port))
      throw const SocketException('Port is already bound to a proxy server.');
    return addServerSocket(await ServerSocket.bind(address, port));
  }

  /// Add already bound ServerSocket.
  Future<void> addServerSocket(ServerSocket server) async {
    if (proxies.containsKey(server.port))
      throw const SocketException('ServerSocket already in use.');
    proxies.addAll({server.port: server});
    unawaited(_listenForClientConnections(server));
  }

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

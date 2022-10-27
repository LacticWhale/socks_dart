import 'dart:async';
import 'dart:io';

import 'auth_handler.dart';
import 'connection.dart';
import 'socks_connection.dart';

/// Socks server.
class SocksServer {
  /// Create new Socks server.
  SocksServer({this.authHandler});

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


        connection = SocksConnection(client, authHandler);

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

    final server = await ServerSocket.bind(address, port);
    proxies.addAll({server.port: server});
    unawaited(_listenForClientConnections(server));
  }
}

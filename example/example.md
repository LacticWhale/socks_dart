```dart
import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/socks_client.dart';
import 'package:socks5_proxy/socks_server.dart';

Future<void> initServer() async {
    // Create server instance
    final proxy = SocksServer();

    // Listen to all tcp and udp connections
    proxy.connections.listen((connection) async {
        // Apply default handler or create own handler to spy on connections.
        await connection.forward();
    }).onError(print);

    // Bind servers
    await proxy.bind(InternetAddress.loopbackIPv4, 1080);
}

Future<void> main() async {
    // Initialize socks server.
    await initServer();

    // List of proxies
    final proxies = [
    ProxySettings(InternetAddress.loopbackIPv4, 1080),
    ];

    // Create HttpClient object
    final client = HttpClient();

    // Assign connection factory
    SocksTCPClient.assignToHttpClientWithSecureOptions(client, proxies, 
        // Log tls keys
        keyLog: print,
    );

    // GET request
    final request = await client.getUrl(Uri.parse('https://example.com'));
    final response = await request.close();
    // Print response
    print(await utf8.decodeStream(response));
    // Close client
    client.close();
}
```

See more [client examples](./client/)
See more [server examples](./server/)

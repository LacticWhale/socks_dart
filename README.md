# Socks5 proxy
## Features
- Easy to use proxy server (both tcp and udp) and client (only tcp).
- Server/Client password authentication.
- Chained proxy on client.
- Redirected proxy on server.
- Traffic spoofing.

## Usage
Import the package:
```dart
import 'package:socks_proxy/socks5.dart';
```
Creating proxy server:
```dart
import 'dart:async';
import 'dart:io';

import 'package:socks_proxy/socks_server.dart';

void main() {
  // Create server instance
  final proxy = SocksServer();

  // Listen to all tcp and udp connections
  proxy.connections.listen((connection) async {
    // Apply default handler
    await connection.forward();
  }).onError(print);

  // Bind servers
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1080));
  unawaited(proxy.bind(InternetAddress.loopbackIPv4, 1081));
}

```
Creating proxy client:
```dart
import 'dart:convert';
import 'dart:io';

import 'package:socks_proxy/socks_client.dart';

void main() {
    // Create HttpClient object
    final client = HttpClient();

    // Assign connection factory
    SocksTCPClient.assignToHttpClient(client, [
      ProxySettings(InternetAddress.loopbackIPv4, 1080),
    ]);

    // GET request
    final request = await client.getUrl(Uri.parse('https://example.com/'));
    final response = await request.close();
    // Print response
    print(await utf8.decodeStream(response));
    // Close client
    client.close();
}
```
See more usage at [example](/examples/) folder.

## License
- MIT License
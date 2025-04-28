import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/enums.dart';
import 'package:socks5_proxy/exceptions.dart';
import 'package:socks5_proxy/socks_client.dart';

void main() async {
  // Create HttpClient object
  final client = HttpClient();

  // Assign connection factory
  try {
    SocksTCPClient.assignToHttpClient(client, [
      ProxySettings(
        InternetAddress.loopbackIPv4,
        1080,
        context: SecurityContext(withTrustedRoots: false)
          ..setTrustedCertificates('cert.pem'),
      ),
    ]);
  } on SocksClientConnectionClosedException catch (error) {
    // Underlying socket is already closed if it was opened by this point.

    // Be aware that other server (server of this packet tries to minimize this)
    // can close connection at any time without sending response to client.

    print(error);
    return;
  } on SocksClientConnectionCommandFailedException catch (error) {
    // Underlying socket is already closed if it was opened by this point.
    if (error.code == CommandReplyCode.connectionDenied) {
      print('Invalid username/password');
    } else {
      print(error);
    }

    return;
  }

  // GET request
  final request = await client.getUrl(Uri.parse('http://example.com/'));
  final response = await request.close();
  // Print response
  print(await utf8.decodeStream(response));
  // Close client
  client.close();
}

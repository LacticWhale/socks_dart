import 'dart:convert';
import 'dart:io';

import 'package:socks5_proxy/socks_client.dart';

void main() async {
// List of proxies
final proxies = [
  ProxySettings(InternetAddress.loopbackIPv4, 1080),
];

// Create HttpClient object
final client = HttpClient();

// Assign connection factory
SocksTCPClient.assignToHttpClientWithSecureOptions(client, proxies, 
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

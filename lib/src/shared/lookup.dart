import 'dart:io';

typedef LookupFunction = Future<List<InternetAddress>> Function(String, {InternetAddressType type});

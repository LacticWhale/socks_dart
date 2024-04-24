import 'dart:io';

Future<InternetAddress> resolveAddress(dynamic address) async {
  InternetAddress resolvedAddress;
  if (address is String){
    resolvedAddress = (await InternetAddress.lookup(address)).first;
  }else if (address is InternetAddress){
    resolvedAddress = address;
  }else {
    throw AddressResolveException('The target Address must be a `String` (when you use a domain name) or an `InternetAddress` instance');
  }
  return resolvedAddress;
}

class AddressResolveException implements Exception {

  AddressResolveException(this.message);

  final String message;

  @override
  String toString() => 'AddressResolveException: $message';
}
import 'socks_client_exception.dart';

class ByteReaderException implements SocksClientException {
  const ByteReaderException(this.message);

  final String message;

  @override
  String toString() => message;
}

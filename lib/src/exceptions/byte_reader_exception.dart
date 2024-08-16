import '../mixin/byte_reader.dart';
import 'socks_client_exception.dart';


/// Exception thrown by [ByteReader] mixin
class ByteReaderException implements SocksClientException {
  const ByteReaderException(this.message);

  final String message;

  @override
  String toString() => message;
}

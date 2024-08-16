import '../mixin/byte_reader.dart';

/// Exception thrown by [ByteReader] mixin
class ByteReaderException implements Exception {
  const ByteReaderException(this.message);

  final String message;
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';

import '../../exceptions/byte_reader_exception.dart';
import '../address_type.dart';
import '../shared/lookup.dart';

/// [ChunkedStreamReader] helper.
mixin ByteReader {
  /// Client data reader.
  @protected
  ChunkedStreamReader<int> get data;

  /// Read single 8 bit unsigned integer.
  @protected
  Future<int> readUint8() async => (await readBytes(1))[0];

  /// Read single 16 bit unsigned integer in big endian.
  @protected
  Future<int> readUint16() async {
    final buffer = await readBytes(2);
    return (buffer[0] << 8) + buffer[1];
  }

  /// Read [size] bytes or throw [RangeError] if there's not enough data
  /// available from the [data].
  @protected
  Future<List<int>> readBytes(int size) async {
    final bytes = await data.readChunk(size);
    if (bytes.length != size) 
      throw ByteReaderException('stream has fewer bytes than expected. Size: ${bytes.length}, expected: $size.');
    
    return bytes;
  }

  /// Read various size bytes depending on [type] and parse IPv4/IPv6 address or lookup hostname.
  @protected
  Future<InternetAddress?> getAddress(AddressType type, [LookupFunction lookup = InternetAddress.lookup]) async {
    if (type == AddressType.domain) {   
      final length = await readUint8();
      final domain = await readBytes(length);

      final addresses = await lookup(ascii.decode(domain));
      if (addresses.isEmpty) 
        return null;
      return addresses[0];
    }

    return InternetAddress.fromRawAddress(
      Uint8List.fromList(
        await readBytes(type == AddressType.ipv4 ? 4 : 16),
      ),
    );
  }
}

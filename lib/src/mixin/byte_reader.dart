import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:meta/meta.dart';

import '../address_type.dart';

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
    if (bytes.length != size) {
      throw RangeError('_readBytes has fewer bytes than expected.');
    }
    return bytes;
  }

  /// Read various size bytes depending on [type] and parse IPv4/IPv6 address or lookup hostname.
  @protected
  Future<InternetAddress?> getAddress(AddressType type) async {
    if (type == AddressType.domain) {   
      final length = await readUint8();
      final chunk = await readBytes(length);

      final addresses = await InternetAddress.lookup(ascii.decode(chunk));
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

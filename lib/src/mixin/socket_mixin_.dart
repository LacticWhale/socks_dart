import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'stream_mixin.dart';

/// Implements [Socket] in terms of [socket].
mixin SocketMixin on StreamMixin<Uint8List> implements Socket {
  /// Target socket to which methods will be redirected.
  @protected
  Socket get socket;

  @override
  Stream<Uint8List> get stream => socket;

  @override
  Encoding get encoding => socket.encoding;

  @override
  set encoding(Encoding encoding) => socket.encoding = encoding;

  @override
  void add(List<int> data) => socket.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      socket.addError(error, stackTrace);

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) =>
      socket.addStream(stream);

  @override
  InternetAddress get address => socket.address;

  @override
  Future<dynamic> close() => socket.close();

  @override
  void destroy() => socket.destroy();

  @override
  Future<dynamic> get done => socket.done;

  @override
  Future<dynamic> flush() => socket.flush();

  @override
  Uint8List getRawOption(RawSocketOption option) => socket.getRawOption(option);

  @override
  int get port => socket.port;

  @override
  InternetAddress get remoteAddress => socket.remoteAddress;

  @override
  int get remotePort => socket.remotePort;

  @override
  bool setOption(SocketOption option, bool enabled) =>
      socket.setOption(option, enabled);

  @override
  void setRawOption(RawSocketOption option) => socket.setRawOption(option);

  @override
  void write(Object? object) => socket.write(object);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      socket.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => socket.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => socket.writeln(object);
}

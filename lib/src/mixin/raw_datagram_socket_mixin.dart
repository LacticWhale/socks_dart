import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'stream_mixin.dart';

mixin RawDatagramSocketMixin on StreamMixin<RawSocketEvent>
    implements RawDatagramSocket {
  @protected
  RawDatagramSocket get rawDatagramSocket;

  @override
  Stream<RawSocketEvent> get stream;

  @override
  bool get broadcastEnabled => rawDatagramSocket.broadcastEnabled;

  @override
  set broadcastEnabled(bool broadcastEnabled) =>
      rawDatagramSocket.broadcastEnabled = broadcastEnabled;

  @override
  int get multicastHops => rawDatagramSocket.multicastHops;

  @override
  set multicastHops(int multicastHops) =>
      rawDatagramSocket.multicastHops = multicastHops;

  @override
  NetworkInterface? get multicastInterface =>
      //
      // ignore: deprecated_member_use
      rawDatagramSocket.multicastInterface;

  @override
  set multicastInterface(NetworkInterface? multicastInterface) =>
      //
      // ignore: deprecated_member_use
      rawDatagramSocket.multicastInterface = multicastInterface;

  @override
  bool get multicastLoopback => rawDatagramSocket.multicastLoopback;

  @override
  set multicastLoopback(bool multicastLoopback) =>
      rawDatagramSocket.multicastLoopback = multicastLoopback;

  @override
  bool get readEventsEnabled => rawDatagramSocket.readEventsEnabled;

  @override
  set readEventsEnabled(bool readEventsEnabled) =>
      rawDatagramSocket.readEventsEnabled = readEventsEnabled;

  @override
  bool get writeEventsEnabled => rawDatagramSocket.writeEventsEnabled;

  @override
  set writeEventsEnabled(bool writeEventsEnabled) =>
      rawDatagramSocket.writeEventsEnabled = writeEventsEnabled;

  @override
  InternetAddress get address => rawDatagramSocket.address;

  @override
  void close() => rawDatagramSocket.close();

  @override
  Uint8List getRawOption(RawSocketOption option) => getRawOption(option);

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      rawDatagramSocket.joinMulticast(group, interface);

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      rawDatagramSocket.leaveMulticast(group, interface);

  @override
  int get port => rawDatagramSocket.port;

  @override
  Datagram? receive() => rawDatagramSocket.receive();

  @override
  int send(List<int> buffer, InternetAddress address, int port) =>
      rawDatagramSocket.send(buffer, address, port);

  @override
  void setRawOption(RawSocketOption option) =>
      rawDatagramSocket.setRawOption(option);
}

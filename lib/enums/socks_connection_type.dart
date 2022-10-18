/// Type of connection
enum SocksConnectionType {
  /// TCP connection.
  connect(0x01),
  /// Weird connection. Not yet implemented in packet.
  bind(0x02),
  /// UDP connection.
  associate(0x03),
  none(0x00);

  const SocksConnectionType(this.byte);
  final int byte;
}

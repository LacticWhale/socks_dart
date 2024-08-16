/// Socks command type.
enum CommandType {
  /// 0x01 - Connect command.
  connect,

  /// 0x02 - Bind command.
  bind,

  /// 0x03 - Associate command.
  associate;

  /// Byte to [CommandType] map.
  static Map<int, CommandType> get byteMap => const {
    0x01: CommandType.connect,
    0x02: CommandType.bind,
    0x03: CommandType.associate,
  };
}

import 'message.dart';

/// Socks command response.
enum CommandReplyCode implements Message {
  /// 0x00 - Succeeded.
  succeed,

  /// 0x01 - General SOCKS server failure.
  serverError,

  /// 0x02 - Connection not allowed by ruleset.
  connectionDenied,

  /// 0x03 - Network unreachable.
  networkUnreachable,

  /// 0x04 - Host unreachable.
  hostUnreachable,

  /// 0x05 - Connection refused.
  connectionRefused,

  /// 0x06 - TTL expired.
  ttlExpired,

  /// 0x07 - Command not supported.
  unsupportedCommand,

  /// 0x08 - Address type not supported.
  unsupportedAddressType;

  /// Create command response.
  const CommandReplyCode();

  @override
  int get byte => index;
}

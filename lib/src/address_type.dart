import 'dart:io';

/// Socks address type.
enum AddressType {
  /// 0x01 - IPv4 address.
  ipv4(0x01),

  /// 0x03 - Domain.
  domain(0x03),

  /// 0x04 - IPv6 address.
  ipv6(0x04);

  /// Create address type.
  const AddressType(this.byte);

  /// Byte representation.
  final int byte;

  /// Byte to [AddressType] map.
  static Map<int, AddressType> get byteMap => const {
        0x01: AddressType.ipv4,
        0x03: AddressType.domain,
        0x04: AddressType.ipv6,
      };

  /// [InternetAddressType] to [AddressType] map.
  static Map<InternetAddressType, AddressType> get internetAddressTypeMap =>
      const {
        InternetAddressType.IPv4: AddressType.ipv4,
        InternetAddressType.unix: AddressType.domain,
        InternetAddressType.IPv6: AddressType.ipv6,
      };
}

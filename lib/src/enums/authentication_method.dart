import 'message.dart';

/// Socks authentication method.
enum AuthenticationMethod implements Message {
  /// 0x00 - No authentication required.
  noAuthenticationRequired(0x00),

  /// 0x01 - GSSAPI.
  // ignore: constant_identifier_names
  GSSAPI(0x01),

  /// 0x02 - Username and password.
  password(0x02),

  /// 0xFF - No acceptable methods.
  invalid(0xff);

  /// Create authentication method.
  const AuthenticationMethod(this._value);

  /// Byte representation.
  final int _value;

  @override
  int get byte => _value;
}

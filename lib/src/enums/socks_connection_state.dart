/// Socks server state.
enum SocksConnectionState {
  /// Initial state.
  initial,

  /// Connection closed.
  closed,

  /// Handshaking with client.
  handshaking,

  /// Authenticating client.
  authenticating,

  /// Ready for command.
  ready,

  /// Establishing TCP connection
  connecting,

  /// Establishing TCP bind connection
  binding,

  /// Establishing UDP connection
  associating,

  /// TCP connection is established
  connected,

  /// TCP bind connection is established
  bound,

  /// UDP connection is established
  associated,
}

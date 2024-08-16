/// State of connection after establishing Socks handshake.
enum ConnectionState {
  none,
  accepted,
  forwarded,
  rejected,
}

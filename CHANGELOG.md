## 2.0.0

- Added `close`, `closeAll`, and `stop` methods to `SocksServer`.
- Added `SocksClientConnectionClosedException` and `SocksClientConnectionCommandFailedException`.
- Updated documentation.
- Updated server examples.
- BREAKING: `package:socks5_proxy/socks_enums.dart` was replaced with `package:socks5_proxy/enums.dart`.
- BREAKING: `package:socks5_proxy/enums/*.dart` and `package:socks5_proxy/exceptions/*.dart` were made private use `package:socks5_proxy/exceptions.dart` or `package:socks5_proxy/exceptions.dart` if you need to access them.

## 1.1.0

- BREAKING: `SocketConnectionTask` is replaced with built-in `ConnectionTask.fromSocket`. Original class is removed!

## 1.0.6

- Added `addServerSocket` method to `SocksServer` which allows to add custom server sockets.
- Added `ROADMAP.md`.

## 1.0.5+dev.2

- Added `ByteReaderException` which is thrown then server closes connection with clinet without stating the reason. 
- Added `lookup` argument to every place it can be relevant.


## 1.0.5+dev.1

- Remove unnecessary DNS resolve in socks_tcp_client.dart.

## 1.0.4+dev.4

- Remove print statement in socks_client.dart.

## 1.0.3+dev.3

- Fix typo in logic of allowIPv6.

## 1.0.3+dev.2

- AllowIPv6 argument for accept and forward methods.

## 1.0.3+dev.1

- Fixing problem with connections not closing in default handler.

## 1.0.2

- Problem with examples.

## 1.0.1

- Adding examples to `dart.pub`.

## 1.0.0

- Initial version.

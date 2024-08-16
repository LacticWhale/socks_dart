import '../../client/socks_client.dart';
import '../../enums/command_reply_code.dart';
import 'socks_client_exception.dart';


/// Exception thrown by [SocksSocket] if socks server response with something other than [CommandReplyCode.succeed].
class SocksClientConnectionCommandFailedException extends SocksClientException {
  const SocksClientConnectionCommandFailedException(this.code);

  final CommandReplyCode code;

  @override
  String get message => 'Command handling failed. With error: ${code.name}';
}

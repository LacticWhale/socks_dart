import 'dart:io';

class SocketConnectionTask implements ConnectionTask<Socket> {
  SocketConnectionTask(this.socket);
  @override
  final Future<Socket> socket;

  @override
  void cancel() => socket.ignore();
}

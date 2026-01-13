import 'dart:io';

List<Socket> clients = [];
Map<Socket, String> usernames = {};

void main(List<String> args) async {
  int port = 3000;
  if (args.isNotEmpty) {
    port = int.parse(args[0]);
  }

  final server = await ServerSocket.bind('0.0.0.0', port);
  print('Server avviato sulla porta $port');

  server.listen((socket) {
    clients.add(socket);
    print('Nuovo client connesso');

    socket.listen(
      (data) {
        handleMessage(socket, data);
      },
      onDone: () {
        handleDisconnect(socket);
      },
      onError: (err) {
        print('Errore socket');
        handleDisconnect(socket);
      },
    );
  });
}

void handleMessage(Socket socket, List<int> data) {
  String message = String.fromCharCodes(data).trim();
  if (message.isEmpty) return;

  // primo messaggio = username
  if (!usernames.containsKey(socket)) {
    usernames[socket] = message;
    print('$message si è collegato');
    return;
  }

  String? username = usernames[socket];
  if (username == null) return;

  String text = username + ': ' + message;
  print(text);
  broadcast(text);
}

void broadcast(String msg) {
  for (int i = 0; i < clients.length; i++) {
    clients[i].write(msg + '\n');
  }
}

void handleDisconnect(Socket socket) {
  String? username = usernames[socket];

  if (username != null) {
    print('$username disconnesso');
    broadcast('SYSTEM: $username ha lasciato la chat');
  }

  clients.remove(socket);
  usernames.remove(socket);
  socket.close();
}

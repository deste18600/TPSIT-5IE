import 'dart:io';

Future<void> main(List<String> args) async {
  String host = '127.0.0.1';
  int port = 3000;

  if (args.isNotEmpty) {
    host = args[0];
  }
  if (args.length > 1) {
    port = int.parse(args[1]);
  }

  stdout.write('Inserisci il tuo username: ');
  String? username = stdin.readLineSync();

  if (username == null || username.trim().isEmpty) {
    print('Username non valido');
    return;
  }

  username = username.trim();

  Socket socket;

  try {
    socket = await Socket.connect(host, port);
  } catch (e) {
    print('Errore di connessione');
    return;
  }

  print('Connesso al server');

  socket.listen((data) {
    String msg = String.fromCharCodes(data).trim();
    if (msg.isNotEmpty) {
      print(msg);
    }
  });

  socket.write(username + '\n');

  stdin.listen((data) {
    String msg = String.fromCharCodes(data).trim();
    if (msg == '/quit') {
      socket.close();
      exit(0);
    }
    socket.write(msg + '\n');
  });
}

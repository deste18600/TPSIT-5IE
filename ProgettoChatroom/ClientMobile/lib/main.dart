import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  Socket? socket;
  bool connected = false;

  // CONTROLLER INPUT
  TextEditingController ipController =
      TextEditingController(text: '127.0.0.1');
  TextEditingController portController =
      TextEditingController(text: '3000');
  TextEditingController usernameController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  List<String> messages = [];
  String myUsername = '';

  void connect() async {
    String ip = ipController.text.trim();
    String portText = portController.text.trim();
    String username = usernameController.text.trim();

    if (ip.isEmpty || portText.isEmpty || username.isEmpty) return;

    int port = int.tryParse(portText) ?? 0;
    if (port <= 0) return;

    try {
      socket = await Socket.connect(ip, port);
    } catch (e) {
      setState(() {
        messages.add('SYSTEM: errore di connessione');
      });
      return;
    }

    socket!.write(username + '\n');
    myUsername = username;

    setState(() {
      connected = true;
      messages.add('SYSTEM: connesso a $ip:$port come $myUsername');
    });

    socket!.listen(
      (data) {
        String text = String.fromCharCodes(data).trim();
        if (text.isEmpty) return;

        setState(() {
          if (text.startsWith('$myUsername:')) {
            messages.add(
              'Me: ${text.substring(myUsername.length + 1)}',
            );
          } else {
            messages.add(text);
          }
        });
      },
      onDone: () {
        setState(() {
          messages.add('SYSTEM: connessione chiusa');
          connected = false;
        });
        socket?.close();
      },
    );
  }

  void sendMessage() {
    String text = messageController.text.trim();
    if (text.isEmpty || !connected || socket == null) return;

    socket!.write(text + '\n');
    messageController.clear();
  }

  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Mobile')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            if (!connected) ...[
              TextField(
                controller: ipController,
                decoration: InputDecoration(labelText: 'IP Server'),
              ),
              TextField(
                controller: portController,
                decoration: InputDecoration(labelText: 'Porta'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: connect,
                child: Text('Connetti'),
              ),
            ],
            if (connected)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          String msg = messages[index];
                          bool isMe = msg.startsWith('Me:');

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.symmetric(vertical: 2),
                              color:
                                  isMe ? Colors.blue[200] : Colors.green[200],
                              child: Text(msg),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

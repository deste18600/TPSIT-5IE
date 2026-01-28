import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TodoBoardNotifier>(
      create: (_) => TodoBoardNotifier(),
      child: MaterialApp(
        title: 'zKeep',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        home: const TodoBoardPage(),
      ),
    );
  }
}

class TodoBoardPage extends StatelessWidget {
  const TodoBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<TodoBoardNotifier>().cards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo Board"),
        elevation: 4,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: cards.map((card) => TodoCardWidget(card: card)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TodoBoardNotifier>().addCard(),
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }
}


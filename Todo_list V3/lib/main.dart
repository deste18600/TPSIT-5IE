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
      create: (BuildContext context) {
        final notifier = TodoBoardNotifier();
        notifier.loadData();
        return notifier;
      },
      child: MaterialApp(
        title: 'zKeep',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
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
    final notifier = context.watch<TodoBoardNotifier>();
    final cards = notifier.cards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("zKeep"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: cards.isEmpty
          ? const Center(child: Text("Premi + per aggiungere una card"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final cardSingola = cards[index];
                return TodoCardWidget(card: cardSingola);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final notifierSenzaAscolto = context.read<TodoBoardNotifier>();
          notifierSenzaAscolto.addCard();
        },
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }
}
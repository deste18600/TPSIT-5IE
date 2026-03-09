import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final notifier = TodoBoardNotifier();
        notifier.loadData(); 
        return notifier;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.black,
          scaffoldBackgroundColor: Colors.white,
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
        title: const Text("zKeep"),
        centerTitle: true,
      ),

      body: cards.isEmpty
          ? const Center(
              child: Text("Crea la tua prima nota!"),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return TodoCardWidget(card: cards[index]);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final notifier = context.read<TodoBoardNotifier>();

          final newCardId = await notifier.addCard();

          final newCard = notifier.cards.firstWhere((c) => c.id == newCardId);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditNoteScreen(card: newCard),
            ),
          );
        },
        label: const Text("Nuova"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
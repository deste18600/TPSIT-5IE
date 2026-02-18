import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoBoardNotifier()..loadData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true, 
          colorSchemeSeed: Colors.red,
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
      appBar: AppBar(title: const Text("zKeep"), centerTitle: true),
      body: cards.isEmpty
          ? const Center(child: Text("Crea la tua prima nota!"))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: cards.length,
                itemBuilder: (context, index) => TodoCardWidget(card: cards[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<TodoBoardNotifier>().addCard(),
        label: const Text("Nuova"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
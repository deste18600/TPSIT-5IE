import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoBoardNotifier(),
      child: MaterialApp(
        title: 'zKeep Pro',
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

class TodoBoardPage extends StatefulWidget {
  const TodoBoardPage({super.key});

  @override
  State<TodoBoardPage> createState() => _TodoBoardPageState();
}

class _TodoBoardPageState extends State<TodoBoardPage> {
  @override
  void initState() {
    super.initState();
    // Carichiamo i dati all'avvio
    Future.microtask(() => context.read<TodoBoardNotifier>().loadData());
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<TodoBoardNotifier>().cards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("zKeep - My Cards"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: cards.isEmpty
          ? const Center(child: Text("Premi il tasto + per creare una nuova Card"))
          : ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) => TodoCardWidget(card: cards[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TodoBoardNotifier>().addCard(),
        tooltip: 'Aggiungi Card',
        child: const Icon(Icons.post_add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() async {
  // Necessario per inizializzare il database prima di runApp
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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
        home: const TodoListPage(),
      ),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carica i dati dal DB non appena il widget è montato
    Future.microtask(() => context.read<TodoBoardNotifier>().loadTodos());
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aggiungi Task"),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Cosa devi fare?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annulla")),
          ElevatedButton(
            onPressed: () {
              context.read<TodoBoardNotifier>().addTodo(_controller.text);
              _controller.clear();
              Navigator.pop(context);
            },
            child: const Text("Aggiungi"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoBoardNotifier>().todos;

    return Scaffold(
      appBar: AppBar(title: const Text("zKeep SQLite"), elevation: 2),
      body: todos.isEmpty
          ? const Center(child: Text("Nessun impegno? Rilassati!"))
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) => TodoItemWidget(todo: todos[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
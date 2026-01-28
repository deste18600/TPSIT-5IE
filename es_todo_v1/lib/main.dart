import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifier.dart';
import 'todo_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoNotifier(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TodoPage(),
      ),
    );
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo – Google Keep Style'),
      ),
      body: ListView.builder(
        itemCount: notifier.todos.length,
        itemBuilder: (context, index) {
          return TodoCard(todo: notifier.todos[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: notifier.addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
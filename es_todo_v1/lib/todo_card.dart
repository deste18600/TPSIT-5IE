import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoCard extends StatelessWidget {
  final Todo todo;

  const TodoCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: todo.completed,
              onChanged: (value) {
                context.read<TodoNotifier>().toggleTodo(todo);
              },
            ),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: todo.text),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Inserisci un compito',
                ),
                onChanged: (value) {
                  context.read<TodoNotifier>().updateText(todo, value);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                context.read<TodoNotifier>().deleteTodo(todo);
              },
            ),
          ],
        ),
      ),
    );
  }
}

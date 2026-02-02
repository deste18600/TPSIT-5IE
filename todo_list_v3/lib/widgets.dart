import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoItemWidget extends StatelessWidget {
  final Todo todo;

  const TodoItemWidget({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TodoBoardNotifier>();

    return ListTile(
      leading: Checkbox(
        value: todo.checked,
        onChanged: (_) => notifier.toggleTodo(todo),
      ),
      title: Text(
        todo.name,
        style: TextStyle(
          decoration: todo.checked ? TextDecoration.lineThrough : null,
          color: todo.checked ? Colors.grey : Colors.black,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent),
        onPressed: () => notifier.deleteTodo(todo),
      ),
    );
  }
}
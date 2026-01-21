import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoItem extends StatefulWidget {
  const TodoItem({required this.todo, super.key});

  final Todo todo;

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.todo.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;
    return const TextStyle(
      color: Colors.black45,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TodoListNotifier>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: widget.todo.checked,
              onChanged: (_) {
                notifier.changeTodo(widget.todo);
              },
            ),
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      autofocus: true,
                      onSubmitted: (value) {
                        notifier.updateTodo(widget.todo, value);
                        setState(() {
                          _isEditing = false;
                        });
                      },
                    )
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: Text(
                        widget.todo.name,
                        style: _getTextStyle(widget.todo.checked),
                      ),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                notifier.deleteTodo(widget.todo);
              },
            ),
          ],
        ),
      ),
    );
  }
}

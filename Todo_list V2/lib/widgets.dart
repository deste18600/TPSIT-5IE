import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoCardWidget extends StatelessWidget {
  final TodoCard card;
  const TodoCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TodoBoardNotifier>();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ...card.lines.map((line) => Row(
                  children: [
                    Checkbox(
                        value: line.checked,
                        onChanged: (_) => notifier.toggleLine(line)),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: line.text),
                        onSubmitted: (value) =>
                            notifier.updateLine(line, value),
                      ),
                    ),
                    IconButton(
                        onPressed: () => notifier.deleteLine(card, line),
                        icon: Icon(Icons.delete)),
                  ],
                )),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () => notifier.addLine(card),
                  icon: Icon(Icons.add)),
            )
          ],
        ),
      ),
    );
  }
}

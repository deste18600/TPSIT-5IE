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
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ...card.lines.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Checkbox(
                    value: line.checked,
                    onChanged: (_) => notifier.toggleLine(line),
                  ),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: line.text),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Scrivi qualcosa...",
                      ),
                      onSubmitted: (value) => notifier.updateLine(line, value),
                    ),
                  ),
                  IconButton(
                    onPressed: () => notifier.deleteLine(card, line),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => notifier.deleteCard(card),
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                ),
                TextButton.icon(
                  onPressed: () => notifier.addLine(card),
                  icon: const Icon(Icons.add),
                  label: const Text("Aggiungi riga"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

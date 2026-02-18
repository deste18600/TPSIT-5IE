import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoCardWidget extends StatelessWidget {
  final TodoCard card;
  const TodoCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditNoteScreen(card: card)),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.title.isNotEmpty)
                Text(card.title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              ...card.lines.take(5).map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(line.checked ? Icons.check_box : Icons.check_box_outline_blank, 
                         size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(line.text.isEmpty ? "Nota vuota" : line.text, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(
                          decoration: line.checked ? TextDecoration.lineThrough : null, 
                          color: line.checked ? Colors.grey : Colors.black87,
                          fontSize: 13
                        )),
                    ),
                  ],
                ),
              )),
              if (card.lines.length > 5) 
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("+ altri ${card.lines.length - 5}", 
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditNoteScreen extends StatelessWidget {
  final TodoCard card;
  const EditNoteScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    // Usiamo watch per reagire ai cambiamenti mentre modifichiamo
    final notifier = context.watch<TodoBoardNotifier>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              notifier.deleteCard(card);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: card.title,
                selection: TextSelection.collapsed(offset: card.title.length),
              ),
            ),
            onChanged: (val) => notifier.updateTitle(card, val),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(hintText: "Titolo", border: InputBorder.none),
          ),
          const SizedBox(height: 10),
          ...card.lines.map((line) => Row(
            children: [
              Checkbox(value: line.checked, onChanged: (_) => notifier.toggleLine(line)),
              Expanded(
                child: TextFormField(
                  initialValue: line.text,
                  onChanged: (val) => notifier.updateLine(line, val),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: "Nota"),
                ),
              ),
              IconButton(icon: const Icon(Icons.close), 
                onPressed: () => notifier.deleteLine(card, line)),
            ],
          )),
          const Divider(),
          TextButton.icon(
            onPressed: () => notifier.addLine(card),
            icon: const Icon(Icons.add),
            label: const Text("Aggiungi riga"),
          ),
        ],
      ),
    );
  }
}
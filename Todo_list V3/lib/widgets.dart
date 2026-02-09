import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

class TodoCardWidget extends StatelessWidget {
  final TodoCard card;
  const TodoCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    //context.read per accedere alle funzioni del notifier
    final notifier = context.read<TodoBoardNotifier>();

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Operatore spread (...) e map per generare la lista di righe
            ...card.lines.map((line) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: line.checked,
                      onChanged: (bool? value) {
                        // Cambia lo stato della riga (check/uncheck) e salva nel database
                        notifier.toggleLine(line);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: line.text),

                        onChanged: (String value) {
                          line.text = value;
                        },
                        // onTapOutside: salva nel database quando clicchi fuori dal testo
                        onTapOutside: (PointerDownEvent event) {
                          notifier.updateLine(line, line.text);
                          FocusScope.of(context).unfocus();
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Scrivi qualcosa...",
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Elimina solo la riga specifica
                        notifier.deleteLine(card, line);
                      },
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    // Elimina l'intera card e tutte le sue righe
                    notifier.deleteCard(card);
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Aggiunge una nuova riga vuota alla card
                    notifier.addLine(card);
                  },
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
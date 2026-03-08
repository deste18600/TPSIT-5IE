import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model.dart';
import 'notifier.dart';

// Todo Griglia
class TodoCardWidget extends StatelessWidget {
  final TodoCard card;
  const TodoCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return EditNoteScreen(card: card);
              },
            ),
          );
        },
        title: card.title.isNotEmpty
            ? Text(card.title,
                style: const TextStyle(fontWeight: FontWeight.bold))
            : null,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ...card.lines.map((line) {
              return Text(
                "• ${line.text}",
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  decoration:
                      line.checked ? TextDecoration.lineThrough : null,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// CARD TODO (La pagina di modifica completa)
class EditNoteScreen extends StatelessWidget {
  final TodoCard card;
  const EditNoteScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {

    final notifier = context.watch<TodoBoardNotifier>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(

        //elimina la nota    
            icon: const Icon(Icons.delete),
            onPressed: () {
              notifier.deleteCard(card);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Titolo della nota
          TextFormField(
            initialValue: card.title,
            decoration: const InputDecoration(
              hintText: "Titolo",
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (valoreInserito) {
              notifier.updateTitle(card, valoreInserito);
            },
          ),

          const Divider(),

          ...card.lines.map((line) {
            return ListTile(
              // Checkbox a sinistra
              leading: Checkbox(
                value: line.checked,
                onChanged: (nuovoStato) {
                  notifier.toggleLine(line);
                },
              ),

              title: TextFormField(
                initialValue: line.text,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onChanged: (nuovoTesto) {
                  notifier.updateLine(line, nuovoTesto);
                },
              ),

              // Tasto per eliminare la riga
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  notifier.deleteLine(card, line);
                },
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          //Aggiungi nuova riga
          TextButton.icon(
            onPressed: () {
              notifier.addLine(card);
            },
            icon: const Icon(Icons.add),
            label: const Text("Aggiungi riga"),
          ),
        ],
      ),
    );
  }
}
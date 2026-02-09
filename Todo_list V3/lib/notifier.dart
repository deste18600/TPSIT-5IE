import 'package:flutter/widgets.dart';
import 'model.dart';
import 'helper.dart';

class TodoBoardNotifier with ChangeNotifier {
  List<TodoCard> _cards = [];

  List<TodoCard> get cards => _cards;

  Future<void> loadData() async {
    _cards = await DatabaseHelper.getCards();
    notifyListeners();
  }

  void addCard() async {
    int cardId = await DatabaseHelper.insertCard();
    TodoLine newLine = TodoLine(cardId: cardId, text: ""); // Testo vuoto di default
    int lineId = await DatabaseHelper.insertLine(newLine);
    newLine.id = lineId;
    _cards.add(TodoCard(id: cardId, lines: [newLine]));
    notifyListeners();
  }

  void addLine(TodoCard card) async {
    TodoLine newLine = TodoLine(cardId: card.id, text: "");
    int lineId = await DatabaseHelper.insertLine(newLine);
    newLine.id = lineId;
    card.lines.add(newLine);
    notifyListeners();
  }

  void updateLine(TodoLine line, String newText) async {
    line.text = newText;
    await DatabaseHelper.updateLine(line); // Salva nel DB
    // Non chiamiamo notifyListeners qui per non disturbare la scrittura
  }

  void toggleLine(TodoLine line) async {
    line.checked = !line.checked;
    await DatabaseHelper.updateLine(line);
    notifyListeners();
  }

  void deleteLine(TodoCard card, TodoLine line) async {
    card.lines.remove(line);
    if (line.id != null) {
      await DatabaseHelper.deleteLine(line.id!);
    }
    notifyListeners();
  }

  void deleteCard(TodoCard card) async {
    if (card.id != null) {
      await DatabaseHelper.deleteCard(card.id!);
      _cards.remove(card);
      notifyListeners();
    }
  }
}
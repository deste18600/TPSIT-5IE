import 'package:flutter/widgets.dart';
import 'model.dart';
import 'helper.dart';

class TodoBoardNotifier with ChangeNotifier {
  List<TodoCard> _cards = [];

  List<TodoCard> get cards {
    return _cards;
  }

  Future<void> loadData() async {
    _cards = await DatabaseHelper.getCards();
    notifyListeners();
  }

  void addCard() async {
    int cardId = await DatabaseHelper.insertCard(); 
    TodoLine newLine = TodoLine(cardId: cardId, text: "Nuova riga");
    int lineId = await DatabaseHelper.insertLine(newLine);
    newLine.id = lineId; 
    _cards.add(TodoCard(id: cardId, lines: [newLine]));
    notifyListeners();
  }

  void addLine(TodoCard card) async {
    TodoLine newLine = TodoLine(cardId: card.id, text: "Nuova riga");
    int lineId = await DatabaseHelper.insertLine(newLine);
    newLine.id = lineId;
    card.lines.add(newLine);
    notifyListeners();
  }

  void updateLine(TodoLine line, String newText) {
    line.text = newText;
    DatabaseHelper.updateLine(line);
    notifyListeners();
  }

  void toggleLine(TodoLine line) {
    line.checked = !line.checked;
    DatabaseHelper.updateLine(line);
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

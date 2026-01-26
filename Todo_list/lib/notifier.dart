import 'package:flutter/widgets.dart';
import 'model.dart';

class TodoBoardNotifier with ChangeNotifier {
  final List<TodoCard> _cards = [];

  List<TodoCard> get cards => _cards;

  void addCard() {
    _cards.add(TodoCard(lines: [TodoLine(text: "Nuova riga")]));
    notifyListeners();
  }

  void addLine(TodoCard card) {
    card.lines.add(TodoLine(text: "Nuova riga"));
    notifyListeners();
  }

  void updateLine(TodoLine line, String newText) {
    line.text = newText;
    notifyListeners();
  }

  void toggleLine(TodoLine line) {
    line.checked = !line.checked;
    notifyListeners();
  }

  void deleteLine(TodoCard card, TodoLine line) {
    card.lines.remove(line);
    notifyListeners();
  }

  void deleteCard(TodoCard card) {
    _cards.remove(card);
    notifyListeners();
  }
}

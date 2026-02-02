import 'package:flutter/widgets.dart';
import 'model.dart';
import 'helper.dart';

class TodoBoardNotifier with ChangeNotifier {
  List<TodoCard> _cards = [];
  List<TodoCard> get cards => _cards;

  Future<void> loadData() async {
    final cardIds = await DatabaseHelper.getCardIds();
    List<TodoCard> tempCards = [];
    for (var id in cardIds) {
      final lines = await DatabaseHelper.getLinesForCard(id);
      tempCards.add(TodoCard(id: id, lines: lines));
    }
    _cards = tempCards;
    notifyListeners();
  }

  void addCard() async {
    final id = await DatabaseHelper.insertCard();
    _cards.add(TodoCard(id: id, lines: []));
    notifyListeners();
  }

  void deleteCard(TodoCard card) async {
    await DatabaseHelper.deleteCard(card.id!);
    _cards.remove(card);
    notifyListeners();
  }

  void addLine(TodoCard card) async {
    final newLine = TodoLine(cardId: card.id, text: "Nuova riga");
    final id = await DatabaseHelper.insertLine(newLine);
    newLine.id = id;
    card.lines.add(newLine);
    notifyListeners();
  }

  void updateLine(TodoLine line, String text) async {
    line.text = text;
    await DatabaseHelper.updateLine(line);
    notifyListeners();
  }

  void toggleLine(TodoLine line) async {
    line.checked = !line.checked;
    await DatabaseHelper.updateLine(line);
    notifyListeners();
  }

  void deleteLine(TodoCard card, TodoLine line) async {
    await DatabaseHelper.deleteLine(line.id!);
    card.lines.remove(line);
    notifyListeners();
  }
}
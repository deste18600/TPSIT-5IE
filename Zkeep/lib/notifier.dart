import 'package:flutter/material.dart';
import 'model.dart';
import 'helper.dart';

class TodoBoardNotifier with ChangeNotifier {
  List<TodoCard> _cards = [];
  List<TodoCard> get cards => _cards;

  Future<void> loadData() async {
    _cards = await DatabaseHelper.getCards();
    notifyListeners();
  }

Future<int> addCard() async {
  int id = await DatabaseHelper.insertCard();
  _cards.insert(0, TodoCard(id: id, lines: []));
  notifyListeners();
  return id; 
}

  Future<void> updateTitle(TodoCard card, String title) async {
    card.title = title;
    await DatabaseHelper.updateCardTitle(card.id!, title);
    notifyListeners();
  }

  Future<void> addLine(TodoCard card) async {
    TodoLine line = TodoLine(cardId: card.id, text: "");
    line.id = await DatabaseHelper.insertLine(line);
    card.lines.add(line);
    notifyListeners();
  }

  Future<void> updateLine(TodoLine line, String text) async {
    line.text = text;
    await DatabaseHelper.updateLine(line);
    notifyListeners();
  }

  Future<void> toggleLine(TodoLine line) async {
    line.checked = !line.checked;
    await DatabaseHelper.updateLine(line);
    notifyListeners();
  }

  Future<void> deleteLine(TodoCard card, TodoLine line) async {
    card.lines.remove(line);
    if (line.id != null) await DatabaseHelper.deleteLine(line.id!);
    notifyListeners();
  }

  Future<void> deleteCard(TodoCard card) async {
    if (card.id != null) {
      await DatabaseHelper.deleteCard(card.id!);
      _cards.remove(card);
      notifyListeners();
    }
  }
}
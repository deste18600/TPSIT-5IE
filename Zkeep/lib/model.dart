class TodoLine {
  int? id;
  int? cardId;
  String text;
  bool checked;

  TodoLine({this.id, this.cardId, required this.text, this.checked = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'text': text,
      'checked': checked ? 1 : 0,
    };
  }
}

class TodoCard {
  int? id;
  String title;
  List<TodoLine> lines;

  TodoCard({this.id, this.title = "", required this.lines});
}
class Todo {
  Todo({required this.name, required this.checked});
  
  String name;   
  bool checked;
}

class TodoLine {
  String text;
  bool checked;
  TodoLine({required this.text, this.checked = false});
}

class TodoCard {
  List<TodoLine> lines;
  TodoCard({required this.lines});
}

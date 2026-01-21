import 'package:flutter/widgets.dart';
import 'model.dart';

class TodoListNotifier with ChangeNotifier {
  final _todos = <Todo>[];

  int get length => _todos.length;

  void addTodo(String name) {
    _todos.add(Todo(name: name, checked: false));
    notifyListeners();
  }

  void changeTodo(Todo todo) {
    todo.checked = !todo.checked;
    notifyListeners();
  }

  void deleteTodo(Todo todo) {
    _todos.remove(todo);
    notifyListeners();
  }

  void updateTodo(Todo todo, String newName) {
    todo.name = newName;
    notifyListeners();
  }

  Todo getTodo(int i) => _todos[i];
}

import 'package:flutter/material.dart';
import 'model.dart';

class TodoNotifier with ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => _todos;

  void addTodo() {
    _todos.add(Todo(text: ''));
    notifyListeners();
  }

  void toggleTodo(Todo todo) {
    todo.completed = !todo.completed;
    notifyListeners();
  }

  void updateText(Todo todo, String value) {
    todo.text = value;
    notifyListeners();
  }

  void deleteTodo(Todo todo) {
    _todos.remove(todo);
    notifyListeners();
  }
}

import 'package:flutter/widgets.dart';
import 'model.dart';
import 'helper.dart';

class TodoBoardNotifier with ChangeNotifier {
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;

  // Carica i dati dal DB all'avvio
  Future<void> loadTodos() async {
    _todos = await DatabaseHelper.getTodos();
    notifyListeners();
  }

  Future<void> addTodo(String name) async {
    if (name.isEmpty) return;
    final newTodo = Todo(name: name);
    final id = await DatabaseHelper.insert(newTodo);
    newTodo.id = id;
    _todos.add(newTodo);
    notifyListeners();
  }

  Future<void> toggleTodo(Todo todo) async {
    todo.checked = !todo.checked;
    await DatabaseHelper.update(todo);
    notifyListeners();
  }

  Future<void> deleteTodo(Todo todo) async {
    if (todo.id != null) {
      await DatabaseHelper.delete(todo.id!);
      _todos.remove(todo);
      notifyListeners();
    }
  }
}
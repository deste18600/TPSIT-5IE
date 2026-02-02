import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'model.dart';

class DatabaseHelper {
  static Future<Database> _openDb() async {
    return openDatabase(
      join(await getDatabasesPath(), 'todo_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, checked INTEGER)',
        );
      },
      version: 1,
    );
  }

  static Future<int> insert(Todo todo) async {
    final db = await _openDb();
    return await db.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Todo>> getTodos() async {
    final db = await _openDb();
    final List<Map<String, dynamic>> maps = await db.query('todos');
    return List.generate(maps.length, (i) => Todo.fromMap(maps[i]));
  }

  static Future<void> update(Todo todo) async {
    final db = await _openDb();
    await db.update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  static Future<void> delete(int id) async {
    final db = await _openDb();
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
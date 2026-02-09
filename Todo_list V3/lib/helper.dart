import 'model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    String path = join(await getDatabasesPath(), 'zkeep.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY AUTOINCREMENT)');
        await db.execute('''
          CREATE TABLE lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id INTEGER,
            text TEXT,
            checked INTEGER,
            FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static Future<List<TodoCard>> getCards() async {
    final db = await _database;
    final List<Map<String, dynamic>> cardMaps = await db.query('cards');
    List<TodoCard> results = [];
    for (var cardMap in cardMaps) {
      int cardId = cardMap['id'];
      final List<Map<String, dynamic>> lineMaps = await db.query(
        'lines',
        where: 'card_id = ?',
        whereArgs: [cardId],
      );
      List<TodoLine> lines = lineMaps.map((l) => TodoLine(
            id: l['id'],
            cardId: l['card_id'],
            text: l['text'] ?? "",
            checked: l['checked'] == 1,
          )).toList();
      results.add(TodoCard(id: cardId, lines: lines));
    }
    return results;
  }

  static Future<int> insertCard() async {
    final db = await _database;
    return await db.insert('cards', {'id': null});
  }

  static Future<void> deleteCard(int id) async {
    final db = await _database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> insertLine(TodoLine line) async {
    final db = await _database;
    return await db.insert('lines', line.toMap());
  }

  static Future<void> updateLine(TodoLine line) async {
    final db = await _database;
    await db.update('lines', line.toMap(), where: 'id = ?', whereArgs: [line.id]);
  }

  static Future<void> deleteLine(int id) async {
    final db = await _database;
    await db.delete('lines', where: 'id = ?', whereArgs: [id]);
  }
}
import 'model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    String path = join(await getDatabasesPath(), 'zkeep.db');

    _database = await openDatabase(
      path,
      version: 2, 
      
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: (db, version) async {
     
        await db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT)');
        
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

    
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('ALTER TABLE cards ADD COLUMN title TEXT DEFAULT ""');
        }
      },
    );

    return _database!;
  }

  static Future<List<TodoCard>> getCards() async {
    final db = await getDatabase();
    
    final List<Map<String, Object?>> cardMaps = await db.query('cards', orderBy: 'id DESC');
    
    List<TodoCard> cards = [];

    for (var cardMap in cardMaps) {
      final cardId = cardMap['id'] as int;

      final lineMaps = await db.query(
        'lines', 
        where: 'card_id = ?', 
        whereArgs: [cardId],
      );

      cards.add(TodoCard(
        id: cardId,
        title: (cardMap['title'] ?? "") as String,
   
        lines: lineMaps.map((l) => TodoLine(
          id: l['id'] as int,
          cardId: l['card_id'] as int,
          text: (l['text'] ?? "") as String,
          checked: l['checked'] == 1,
        )).toList(),
      ));
    }
    return cards;
  }


  static Future<int> insertCard() async {
    final db = await getDatabase();
    return await db.insert('cards', {'title': ''});
  }

  static Future<int> insertLine(TodoLine line) async {
    final db = await getDatabase();
    return await db.insert('lines', line.toMap());
  }

  static Future<void> updateCardTitle(int id, String title) async {
    final db = await getDatabase();
    await db.update(
      'cards', 
      {'title': title}, 
      where: 'id = ?', 
      whereArgs: [id],
    );
  }

  static Future<void> updateLine(TodoLine line) async {
    final db = await getDatabase();
    await db.update(
      'lines', 
      line.toMap(), 
      where: 'id = ?', 
      whereArgs: [line.id],
    );
  }

  static Future<void> deleteLine(int id) async {
    final db = await getDatabase();
    await db.delete('lines', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteCard(int id) async {
    final db = await getDatabase();
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'pitch_master.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spartiti (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_file TEXT NOT NULL,
        percorso_file TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ricrea la tabella spartiti senza brano_id
      await db.execute('DROP TABLE IF EXISTS spartiti');
      await db.execute('DROP TABLE IF EXISTS brani');
      await db.execute('''
        CREATE TABLE spartiti (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome_file TEXT NOT NULL,
          percorso_file TEXT NOT NULL,
          note TEXT
        )
      ''');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllSpartiti() async {
    final db = await getDatabase();
    return await db.query('spartiti', orderBy: 'id DESC');
  }

  static Future<void> cacheSpartiti(List<Map<String, dynamic>> spartiti) async {
    final db = await getDatabase();
    final batch = db.batch();
    for (final s in spartiti) {
      batch.insert('spartiti', {
        'nome_file': s['nome_file'],
        'percorso_file': s['percorso_file'] ?? '',
        'note': s['note'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  static Future<void> insertSpartito(Map<String, dynamic> spartito) async {
    final db = await getDatabase();
    await db.insert('spartiti', {
      'nome_file': spartito['nome_file'],
      'percorso_file': spartito['percorso_file'] ?? '',
      'note': spartito['note'] ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateSpartito(int id, Map<String, dynamic> fields) async {
    final db = await getDatabase();
    await db.update('spartiti', fields, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteSpartito(int id) async {
    final db = await getDatabase();
    await db.delete('spartiti', where: 'id = ?', whereArgs: [id]);
  }
}
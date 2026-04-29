import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Gestisce il database SQLite locale.
/// Salva le sessioni di accordatura come cache offline.
class DatabaseHelper {
  static Database? _database;

  /// Restituisce l'istanza del database, creandola se necessario.
  static Future<Database> getDatabase() async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'pitch_master.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Crea le tabelle al primo avvio dell'app.
  static Future<void> _onCreate(Database db, int version) async {
    // Tabella sessioni di accordatura
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        instrument TEXT NOT NULL,
        string_name TEXT NOT NULL,
        target_frequency REAL NOT NULL,
        detected_frequency REAL NOT NULL,
        cents_offset REAL NOT NULL,
        tuned INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Salva una sessione di accordatura nel database.
  static Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await getDatabase();
    return await db.insert('sessions', session);
  }

  /// Recupera tutte le sessioni salvate, dalla più recente.
  static Future<List<Map<String, dynamic>>> getSessions() async {
    final db = await getDatabase();
    return await db.query('sessions', orderBy: 'id DESC');
  }

  /// Elimina una sessione per ID.
  static Future<void> deleteSession(int id) async {
    final db = await getDatabase();
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina tutte le sessioni.
  static Future<void> clearSessions() async {
    final db = await getDatabase();
    await db.delete('sessions');
  }
}
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
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE spartiti (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id     TEXT UNIQUE,
        nome_file     TEXT NOT NULL,
        percorso_file TEXT NOT NULL DEFAULT '',
        note          TEXT,
        synced        INTEGER NOT NULL DEFAULT 0,
        sync_pending  INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS spartiti');
    await db.execute('DROP TABLE IF EXISTS brani');
    await _onCreate(db, newVersion);
  }

  static Future<List<Map<String, dynamic>>> getAllSpartiti() async {
    final db = await getDatabase();
    return await db.query('spartiti', orderBy: 'id DESC');
  }

  /// Solo record non ancora sincronizzati E non in attesa di risposta dal server.
  /// sync_pending = 1 significa che la richiesta è già partita ma non ha ancora
  /// ricevuto risposta — evitiamo di reinviarli e creare duplicati.
  static Future<List<Map<String, dynamic>>> getUnsyncedSpartiti() async {
    final db = await getDatabase();
    return await db.query(
      'spartiti',
      where: 'synced = 0 AND sync_pending = 0',
      orderBy: 'id ASC',
    );
  }

  /// Marca il record come "invio in corso" prima di fare la chiamata HTTP.
  /// Così se l'app si chiude a metà, al riavvio non lo reinviamo.
  static Future<void> markSyncPending(int localId) async {
    final db = await getDatabase();
    await db.update(
      'spartiti',
      {'sync_pending': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Chiamata se la risposta del server fallisce: rimette il record in coda.
  static Future<void> unmarkSyncPending(int localId) async {
    final db = await getDatabase();
    await db.update(
      'spartiti',
      {'sync_pending': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Sincronizza la cache locale con la lista ricevuta dal server.
  /// - Aggiorna i record già presenti (per remote_id)
  /// - Inserisce i nuovi dal server SOLO se non esiste già un record
  ///   locale con lo stesso nome_file non ancora sincronizzato
  static Future<void> mergeSpartiti(List<Map<String, dynamic>> remoteList) async {
    final db = await getDatabase();

    // Raccoglie i nome_file dei record locali non sincronizzati
    // per evitare di inserire duplicati dal server
    final unsyncedRows = await db.query(
      'spartiti',
      columns: ['nome_file'],
      where: 'synced = 0',
    );
    final unsyncedNames = unsyncedRows
        .map((r) => r['nome_file']?.toString().toLowerCase() ?? '')
        .toSet();

    for (final s in remoteList) {
      final remoteId = s['id']?.toString() ?? '';
      if (remoteId.isEmpty) continue;

      final existing = await db.query(
        'spartiti',
        where: 'remote_id = ?',
        whereArgs: [remoteId],
        limit: 1,
      );

      final row = {
        'remote_id':     remoteId,
        'nome_file':     s['nome_file'] ?? '',
        'percorso_file': s['percorso_file'] ?? '',
        'note':          s['note'] ?? '',
        'synced':        1,
        'sync_pending':  0,
      };

      if (existing.isEmpty) {
        // Non inserire se c'è già un record locale non sincronizzato
        // con lo stesso nome — si sincronizzerà lui e prenderà questo remote_id
        final nomeNorm = (s['nome_file'] ?? '').toString().toLowerCase();
        if (unsyncedNames.contains(nomeNorm)) continue;

        await db.insert('spartiti', row, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        // Aggiorna solo se il record non è in attesa di sync (non sovrascrivere modifiche locali)
        final localSynced = existing.first['synced'] as int? ?? 0;
        if (localSynced == 1) {
          await db.update(
            'spartiti',
            row,
            where: 'remote_id = ?',
            whereArgs: [remoteId],
          );
        }
      }
    }
  }

  /// Inserisce uno spartito locale. Restituisce l'id SQLite.
  static Future<int> insertSpartito(Map<String, dynamic> spartito) async {
    final db = await getDatabase();
    return await db.insert(
      'spartiti',
      {
        'remote_id':     spartito['remote_id'],
        'nome_file':     spartito['nome_file'] ?? '',
        'percorso_file': spartito['percorso_file'] ?? '',
        'note':          spartito['note'] ?? '',
        'synced':        spartito['synced'] ?? 0,
        'sync_pending':  0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Marca come sincronizzato con il remote_id del server.
  static Future<void> markSynced(int localId, String remoteId) async {
    final db = await getDatabase();
    await db.update(
      'spartiti',
      {'synced': 1, 'sync_pending': 0, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> updateSpartito(int id, Map<String, dynamic> fields) async {
    final db = await getDatabase();
    await db.update('spartiti', fields, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteSpartito(int id) async {
    final db = await getDatabase();
    await db.delete('spartiti', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteSpartitoByRemoteId(String remoteId) async {
    final db = await getDatabase();
    await db.delete('spartiti', where: 'remote_id = ?', whereArgs: [remoteId]);
  }
}

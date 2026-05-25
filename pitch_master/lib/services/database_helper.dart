// ============================================================
// database_helper.dart
// Gestisce il database SQLite locale con DUE tabelle:
//
//   1. strumenti  → gli strumenti musicali (chitarra, basso…)
//   2. spartiti   → i file PDF/immagine degli spartiti
//
// La tabella "strumenti" è la più semplice possibile:
//   id      → numero univoco automatico
//   nome    → es. "Chitarra"
//   corde   → le note separate da virgola, es. "Mi2,La2,Re3,Sol3,Si3,Mi4"
//             (una stringa sola: più facile da salvare e leggere)
//   attivo  → 0 o 1: quale strumento è selezionato in questo momento
//
// Per cambiare strumento basta fare:
//   DatabaseHelper.impostaStrumentoAttivo(id)
// e leggere le corde con:
//   DatabaseHelper.getStrumentoAttivo()
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {

  static Database? _database;

  static Future<Database> getDatabase() async {
    _database ??= await _apriDatabase();
    return _database!;
  }

  static Future<Database> _apriDatabase() async {
    final percorso = join(await getDatabasesPath(), 'pitch_master.db');
    return await openDatabase(
      percorso,
      version: 4,                    // aumentato da 3 a 4: aggiunge la tabella strumenti
      onCreate:  _creaTabelle,
      onUpgrade: _aggiornaTabelle,
    );
  }


  // ── Crea entrambe le tabelle al primo avvio ───────────────
  static Future<void> _creaTabelle(Database db, int versione) async {

    // TABELLA 1: strumenti
    // "corde" è una stringa con le note separate da virgola.
    // Esempio: "Mi2,La2,Re3,Sol3,Si3,Mi4"
    // È la scelta più semplice: niente tabella extra, niente JOIN.
    // Per convertirla in lista basta: corde.split(',')
    await db.execute('''
      CREATE TABLE strumenti (
        id     INTEGER PRIMARY KEY AUTOINCREMENT,
        nome   TEXT NOT NULL,
        corde  TEXT NOT NULL,
        attivo INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // TABELLA 2: spartiti (uguale a prima)
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

    // Inserisce gli strumenti predefiniti al primo avvio.
    // Il primo (Chitarra) viene messo come attivo = 1.
    await _inserisciStrumentiDefault(db);
  }


  // ── Aggiorna schema (versione vecchia → nuova) ────────────
  static Future<void> _aggiornaTabelle(Database db, int vecchia, int nuova) async {
    await db.execute('DROP TABLE IF EXISTS strumenti');
    await db.execute('DROP TABLE IF EXISTS spartiti');
    await db.execute('DROP TABLE IF EXISTS brani');
    await _creaTabelle(db, nuova);
  }


  // ── Inserisce chitarra, basso e ukulele come dati iniziali ─
  static Future<void> _inserisciStrumentiDefault(Database db) async {
    final strumentiDefault = [
      {'nome': 'Chitarra', 'corde': 'Mi2,La2,Re3,Sol3,Si3,Mi4', 'attivo': 1},
      {'nome': 'Basso',    'corde': 'Mi1,La1,Re2,Sol2',          'attivo': 0},
      {'nome': 'Ukulele',  'corde': 'Sol4,Do4,Mi4,La4',          'attivo': 0},
    ];
    for (final s in strumentiDefault) {
      await db.insert('strumenti', s);
    }
  }


  // ══════════════════════════════════════════════════════════
  //  CRUD TABELLA STRUMENTI
  // ══════════════════════════════════════════════════════════

  // ── GET ALL: tutti gli strumenti ─────────────────────────
  static Future<List<Map<String, dynamic>>> getAllStrumenti() async {
    final db = await getDatabase();
    return await db.query('strumenti', orderBy: 'id ASC');
  }

  // ── GET ACTIVE: lo strumento attualmente selezionato ─────
  // Restituisce null solo se il database è completamente vuoto.
  static Future<Map<String, dynamic>?> getStrumentoAttivo() async {
    final db     = await getDatabase();
    final risultati = await db.query(
      'strumenti',
      where: 'attivo = 1',
      limit: 1,
    );
    return risultati.isEmpty ? null : risultati.first;
  }

  // ── SWITCH: cambia lo strumento attivo ───────────────────
  // Questo è il metodo più usato dall'accordatore.
  // Prima mette tutti a 0, poi mette a 1 solo quello scelto.
  // Due operazioni SQL, nessuna logica complicata.
  static Future<void> impostaStrumentoAttivo(int id) async {
    final db = await getDatabase();
    await db.update('strumenti', {'attivo': 0});          // tutti a 0
    await db.update('strumenti', {'attivo': 1},           // solo questo a 1
        where: 'id = ?', whereArgs: [id]);
  }

  // ── POST: aggiungi uno strumento personalizzato ───────────
  // "corde" deve essere una stringa con note separate da virgola.
  // Esempio: "Do3,Mi3,Sol3,Si3"
  static Future<int> insertStrumento(String nome, String corde) async {
    final db = await getDatabase();
    return await db.insert('strumenti', {
      'nome':   nome,
      'corde':  corde,
      'attivo': 0,    // nuovo strumento: non attivo di default
    });
  }

  // ── PUT: modifica nome e corde di uno strumento ──────────
  static Future<void> updateStrumento(int id, String nome, String corde) async {
    final db = await getDatabase();
    await db.update(
      'strumenti',
      {'nome': nome, 'corde': corde},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── DELETE: elimina uno strumento ────────────────────────
  // Se si elimina quello attivo, attiva automaticamente il primo rimasto.
  static Future<void> deleteStrumento(int id) async {
    final db = await getDatabase();

    // Controlla se è quello attivo
    final lista = await db.query('strumenti',
        where: 'id = ? AND attivo = 1', whereArgs: [id], limit: 1);
    final eraAttivo = lista.isNotEmpty;

    await db.delete('strumenti', where: 'id = ?', whereArgs: [id]);

    // Se era attivo, passa al primo strumento rimasto
    if (eraAttivo) {
      final rimasti = await db.query('strumenti', orderBy: 'id ASC', limit: 1);
      if (rimasti.isNotEmpty) {
        final primoId = rimasti.first['id'] as int;
        await db.update('strumenti', {'attivo': 1},
            where: 'id = ?', whereArgs: [primoId]);
      }
    }
  }


  // ══════════════════════════════════════════════════════════
  //  CRUD TABELLA SPARTITI (invariata)
  // ══════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getAllSpartiti() async {
    final db = await getDatabase();
    return await db.query('spartiti', orderBy: 'id DESC');
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedSpartiti() async {
    final db = await getDatabase();
    return await db.query('spartiti',
        where: 'synced = 0 AND sync_pending = 0', orderBy: 'id ASC');
  }

  static Future<void> markSyncPending(int idLocale) async {
    final db = await getDatabase();
    await db.update('spartiti', {'sync_pending': 1},
        where: 'id = ?', whereArgs: [idLocale]);
  }

  static Future<void> unmarkSyncPending(int idLocale) async {
    final db = await getDatabase();
    await db.update('spartiti', {'sync_pending': 0},
        where: 'id = ?', whereArgs: [idLocale]);
  }

  static Future<void> mergeSpartiti(List<Map<String, dynamic>> listaServer) async {
    final db = await getDatabase();

    final righeNonSync = await db.query('spartiti',
        columns: ['nome_file'], where: 'synced = 0');
    final nomiNonSync = righeNonSync
        .map((r) => r['nome_file']?.toString().toLowerCase() ?? '')
        .toSet();

    for (final s in listaServer) {
      final remoteId = s['id']?.toString() ?? '';
      if (remoteId.isEmpty) continue;

      final esistente = await db.query('spartiti',
          where: 'remote_id = ?', whereArgs: [remoteId], limit: 1);

      final dati = {
        'remote_id':     remoteId,
        'nome_file':     s['nome_file']     ?? '',
        'percorso_file': s['percorso_file'] ?? '',
        'note':          s['note']          ?? '',
        'synced':        1,
        'sync_pending':  0,
      };

      if (esistente.isEmpty) {
        final nomeNorm = (s['nome_file'] ?? '').toString().toLowerCase();
        if (nomiNonSync.contains(nomeNorm)) continue;
        await db.insert('spartiti', dati,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        if ((esistente.first['synced'] as int? ?? 0) == 1) {
          await db.update('spartiti', dati,
              where: 'remote_id = ?', whereArgs: [remoteId]);
        }
      }
    }
  }

  static Future<int> insertSpartito(Map<String, dynamic> spartito) async {
    final db = await getDatabase();
    return await db.insert('spartiti', {
      'remote_id':     spartito['remote_id'],
      'nome_file':     spartito['nome_file']     ?? '',
      'percorso_file': spartito['percorso_file'] ?? '',
      'note':          spartito['note']          ?? '',
      'synced':        spartito['synced']        ?? 0,
      'sync_pending':  0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> markSynced(int idLocale, String remoteId) async {
    final db = await getDatabase();
    await db.update('spartiti',
        {'synced': 1, 'sync_pending': 0, 'remote_id': remoteId},
        where: 'id = ?', whereArgs: [idLocale]);
  }

  static Future<void> updateSpartito(int id, Map<String, dynamic> campi) async {
    final db = await getDatabase();
    await db.update('spartiti', campi, where: 'id = ?', whereArgs: [id]);
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

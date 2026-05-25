// spartiti_screen.dart — offline-first
// Flusso: 1) mostra SQLite locale → 2) contatta server → 3) merge → 4) aggiorna UI

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class SpartitiScreen extends StatefulWidget {
  const SpartitiScreen({super.key});
  @override
  State<SpartitiScreen> createState() => _SpartitiScreenState();
}

class _SpartitiScreenState extends State<SpartitiScreen> {
  List<Map<String, dynamic>> _spartiti = [];
  bool _staCaricando = true; // mostra spinner finché non arriva la cache locale
  bool _eOnline      = false; // aggiorna l'icona cloud in AppBar

  // Colori centralizzati per evitare ripetizioni
  static const _oro   = Color(0xFFD4AF37);
  static const _scuro = Color(0xFF161616);
  static const _nero  = Color(0xFF0A0A0A);

  @override
  void initState() { super.initState(); _caricaSpartiti(); }

  // ══════════════════════════════════════════════════════════
  // CARICAMENTO — offline-first
  // ══════════════════════════════════════════════════════════

  Future<void> _caricaSpartiti() async {
    setState(() => _staCaricando = true);

    // Passo 1: leggi SQLite e mostra subito → l'utente non aspetta il server
    _spartiti = await DatabaseHelper.getAllSpartiti();
    setState(() => _staCaricando = false);

    // Passo 2: contatta il server (può fallire → rimane la cache)
    final dal = await ApiService.getAllSpartiti();
    if (dal == null) { setState(() => _eOnline = false); return; }

    // Passo 3: aggiorna SQLite con i dati del server + invia gli item rimasti offline
    await DatabaseHelper.mergeSpartiti(List<Map<String,dynamic>>.from(dal));
    await _sincronizzaOffline();

    // Passo 4: rileggi e mostra la lista finale
    if (mounted) setState(() { _spartiti = []; _eOnline = true; });
    final finale = await DatabaseHelper.getAllSpartiti();
    if (mounted) setState(() => _spartiti = finale);
  }

  // Invia al server tutti gli spartiti con synced=0 rimasti in coda.
  // IMPORTANTE: se lo spartito ha già un remote_id (es. file ricollegato dopo modifica)
  // usa PATCH per aggiornare il record esistente — non CREATE, che creerebbe un duplicato.
  Future<void> _sincronizzaOffline() async {
    for (final s in await DatabaseHelper.getUnsyncedSpartiti()) {
      final id       = s['id'] as int;
      final remoteId = s['remote_id']?.toString() ?? '';
      final percorso = s['percorso_file']?.toString() ?? '';
      await DatabaseHelper.markSyncPending(id); // anti-duplicati se l'app si chiude a metà

      // Se è un file locale, prova a caricarlo sul server
      String percorsoSrv = percorso;
      if (percorso.isNotEmpty && !percorso.startsWith('http')) {
        final url = await ApiService.uploadFile(percorso, p.basename(percorso), null);
        if (url != null) percorsoSrv = url;
      }

      final payload = {'nome_file': s['nome_file'], 'percorso_file': percorsoSrv, 'note': s['note'] ?? ''};
      bool successo = false;

      if (remoteId.isNotEmpty) {
        // Spartito già esistente sul server → aggiorna senza creare duplicati
        final res = await ApiService.patchSpartito(remoteId, payload);
        successo = res != null;
        if (successo) {
          await DatabaseHelper.markSynced(id, remoteId); // remote_id non cambia
          if (percorsoSrv != percorso)
            await DatabaseHelper.updateSpartito(id, {'percorso_file': percorsoSrv});
        }
      } else {
        // Spartito nuovo, non ancora sul server → crea
        final res = await ApiService.createSpartito(payload);
        successo = res?['id']?.toString().isNotEmpty == true;
        if (successo) {
          await DatabaseHelper.markSynced(id, res!['id'].toString());
          if (percorsoSrv != percorso)
            await DatabaseHelper.updateSpartito(id, {'percorso_file': percorsoSrv});
        }
      }

      // Fallimento in entrambi i casi: rimetti in coda per il prossimo avvio
      if (!successo) await DatabaseHelper.unmarkSyncPending(id);
    }
  }

  // ══════════════════════════════════════════════════════════
  // GESTIONE FILE
  // ══════════════════════════════════════════════════════════

  // Copia il file scelto nella cartella interna dell'app (così non sparisce se l'utente
  // cancella l'originale da Downloads). Aggiunge timestamp se il nome esiste già.
  Future<String?> _copiaFile(String src, String nome) async {
    try {
      final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'spartiti'));
      if (!await dir.exists()) await dir.create(recursive: true);
      var dest = p.join(dir.path, nome);
      if (await File(dest).exists()) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        dest = p.join(dir.path, '${p.basenameWithoutExtension(nome)}_$ts${p.extension(nome)}');
      }
      await File(src).copy(dest);
      return dest;
    } catch (_) { return null; }
  }

  // Apre lo spartito con tre tentativi in cascata:
  // 1) percorso diretto in DB  2) cerca per nome nella cartella app  3) URL remoto nel browser
  Future<void> _apriSpartito(Map<String, dynamic> s) async {
    final percorso = s['percorso_file']?.toString() ?? '';
    final nome     = s['nome_file']?.toString() ?? '';

    if (percorso.isNotEmpty && !percorso.startsWith('http') && await _apriLocale(percorso)) return;
    try {
      final f = p.join((await getApplicationDocumentsDirectory()).path, 'spartiti', nome);
      if (await File(f).exists() && await _apriLocale(f)) return;
    } catch (_) {}
    if (percorso.startsWith('http')) {
      final uri = Uri.tryParse(percorso);
      if (uri != null && await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); return; }
    }
    _mostraDialogoFileAssente(nome); // tutti i tentativi falliti
  }

  // Apre un file locale con l'app di sistema appropriata; restituisce true se riesce
  Future<bool> _apriLocale(String path) async {
    try {
      if (!await File(path).exists()) return false;
      return (await OpenFilex.open(path)).type == ResultType.done;
    } catch (_) { return false; }
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGO AGGIUNTA
  // ══════════════════════════════════════════════════════════

  void _mostraDialogoAggiunta() {
    final ctrlNome = TextEditingController();
    final ctrlNote = TextEditingController();
    String? percorso, nomeFile;

    showDialog(context: context, barrierDismissible: false, // impedisce chiusura accidentale
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
        backgroundColor: _scuro, shape: _bordoOro(),
        title: const Text('Nuovo Spartito', style: TextStyle(color: _oro, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Nome *'), _campo(ctrlNome, 'Es. Wish You Were Here...'),
          const SizedBox(height: 16),
          _label('Capotasto / Accordatura'),
          _campo(ctrlNote, 'Es. Capotasto al 2, Drop D...'),
          const SizedBox(height: 6),
          // Chip rapidi per accordature comuni
          Wrap(spacing: 6, children: ['Standard','Drop D','Open G','Open D','DADGAD'].map((t) =>
            GestureDetector(onTap: () { ctrlNote.text = t; set((){}); },
              child: Chip(label: Text(t, style: const TextStyle(fontSize: 11, color: _oro)),
                backgroundColor: _nero, side: BorderSide(color: _oro.withOpacity(0.3)),
                padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))).toList()),
          const SizedBox(height: 16),
          _label('File (PDF o immagine) *'),
          const SizedBox(height: 8),
          _selezioneFile(percorso, nomeFile, onTap: () async {
            final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','jpeg','png']);
            if (r?.files.single.path != null) set(() {
              percorso = r!.files.single.path; nomeFile = r.files.single.name;
              // Pre-compila il nome togliendo l'estensione se il campo è vuoto
              if (ctrlNome.text.isEmpty) ctrlNome.text = nomeFile!.replaceAll(RegExp(r'\.(pdf|jpg|jpeg|png)$', caseSensitive: false), '');
            });
          }, onClear: () => set(() { percorso = null; nomeFile = null; })),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _oro, foregroundColor: _nero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final nome = ctrlNome.text.trim();
              if (nome.isEmpty)     { _snack('Inserisci il nome.'); return; }
              if (percorso == null) { _snack('Seleziona un file.'); return; }
              final locale = await _copiaFile(percorso!, nomeFile!);
              if (locale == null)   { _snack('Errore nel salvataggio del file.'); return; }
              // Salva in SQLite con synced=0 e chiudi subito il dialogo (non aspetta il server)
              final id = await DatabaseHelper.insertSpartito({'nome_file': nome, 'percorso_file': locale, 'note': ctrlNote.text.trim(), 'synced': 0});
              Navigator.pop(ctx);
              final lista = await DatabaseHelper.getAllSpartiti();
              if (mounted) setState(() => _spartiti = lista);
              _inviaAlServer(id, nome, locale, nomeFile!, ctrlNote.text.trim()); // fire-and-forget
            }),
        ],
      )),
    );
  }

  // Tenta l'upload e la creazione sul server in background
  Future<void> _inviaAlServer(int id, String nome, String locale, String nomeFile, String note) async {
    await DatabaseHelper.markSyncPending(id);
    String srv = locale;
    final url = await ApiService.uploadFile(locale, nomeFile, null);
    if (url != null) srv = url;
    final res = await ApiService.createSpartito({'nome_file': nome, 'percorso_file': srv, 'note': note});
    if (res?['id']?.toString().isNotEmpty == true) {
      await DatabaseHelper.markSynced(id, res!['id'].toString());
      if (srv != locale) await DatabaseHelper.updateSpartito(id, {'percorso_file': srv});
      if (mounted) { final l = await DatabaseHelper.getAllSpartiti(); setState(() { _spartiti = l; _eOnline = true; }); }
    } else {
      await DatabaseHelper.unmarkSyncPending(id); // rimetti in coda
    }
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGO MODIFICA
  // ══════════════════════════════════════════════════════════

  void _mostraDialogoModifica(Map<String, dynamic> s) {
    if (s.isEmpty) return; // chiamata accidentale da firstWhere con orElse: () => {}
    final ctrlNome = TextEditingController(text: s['nome_file'] ?? '');
    final ctrlNote = TextEditingController(text: s['note'] ?? '');
    String? nuovoPercorso, nuovoNome;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      backgroundColor: _scuro, shape: _bordoOro(),
      title: const Text('Modifica', style: TextStyle(color: _oro, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Nome'), _campo(ctrlNome, 'Nome spartito'),
        const SizedBox(height: 12),
        _label('Capotasto / Accordatura'), _campo(ctrlNote, 'Es. Drop D...'),
        const SizedBox(height: 16),
        _label('Ricollega file (opzionale)'), // utile se il file locale è stato cancellato
        _selezioneFile(nuovoPercorso, nuovoNome,
          currentPath: s['percorso_file']?.toString(), // mostra il file attuale come placeholder
          onTap: () async {
            final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','jpeg','png']);
            if (r?.files.single.path != null) set(() { nuovoPercorso = r!.files.single.path; nuovoNome = r.files.single.name; });
          }, onClear: null),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)), child: const Text('Annulla')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _oro, foregroundColor: _nero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () async {
            final id       = s['id'] as int;
            final remoteId = s['remote_id']?.toString();
            final campi    = {'nome_file': ctrlNome.text.trim(), 'note': ctrlNote.text.trim()};
            if (nuovoPercorso != null) {
              final loc = await _copiaFile(nuovoPercorso!, nuovoNome!);
              if (loc != null) { campi['percorso_file'] = loc; campi['synced'] = '0'; } // forza ri-sync
            }
            await DatabaseHelper.updateSpartito(id, campi);
            // Aggiorna il server in background (fire-and-forget)
            if (remoteId?.isNotEmpty == true)
              ApiService.patchSpartito(remoteId!, {'nome_file': campi['nome_file'], 'note': campi['note']});
            Navigator.pop(ctx);
            _caricaSpartiti();
          }),
      ],
    )));
  }

  // ══════════════════════════════════════════════════════════
  // ELIMINAZIONE
  // ══════════════════════════════════════════════════════════

  Future<void> _eliminaSpartito(Map<String, dynamic> s) async {
    await DatabaseHelper.deleteSpartito(s['id'] as int); // locale subito
    final rid = s['remote_id']?.toString();
    if (rid?.isNotEmpty == true) ApiService.deleteSpartito(rid!); // server in background
    final lista = await DatabaseHelper.getAllSpartiti();
    if (mounted) setState(() => _spartiti = lista);
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGHI E NOTIFICHE
  // ══════════════════════════════════════════════════════════

  // Avvisa che il file non è disponibile e offre di ricollegarlo tramite modifica
  void _mostraDialogoFileAssente(String nome) => showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: _scuro, shape: _bordoOro(),
    title: Row(children: [Icon(Icons.cloud_off, color: _oro.withOpacity(0.8), size: 22), const SizedBox(width: 10),
      const Text('File non disponibile', style: TextStyle(color: _oro, fontWeight: FontWeight.bold, fontSize: 16))]),
    content: Text('Il file di "$nome" non è presente su questo dispositivo.\nPremi ✏️ per ricollegarlo.',
      style: const TextStyle(color: Colors.white70, fontSize: 14)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)), child: const Text('Chiudi')),
      ElevatedButton.icon(
        icon: const Icon(Icons.upload_file, size: 16), label: const Text('Ricarica file'),
        style: ElevatedButton.styleFrom(backgroundColor: _oro, foregroundColor: _nero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () { Navigator.pop(ctx); _mostraDialogoModifica(_spartiti.firstWhere((s) => s['nome_file'] == nome, orElse: () => {})); }),
    ]));

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: _scuro, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _oro.withOpacity(0.4)))));

  // ══════════════════════════════════════════════════════════
  // WIDGET HELPER — riusati nei dialoghi
  // ══════════════════════════════════════════════════════════

  // Bordo arrotondato dorato per tutti gli AlertDialog
  ShapeBorder _bordoOro() => RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _oro.withOpacity(0.25), width: 1.5));

  // Etichetta dorata sopra i campi
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t,
    style: const TextStyle(color: Color(0xFFC5A880), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4)));

  // Campo di testo con tema scuro
  Widget _campo(TextEditingController c, String hint) => TextField(controller: c,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
      filled: true, fillColor: _nero, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _oro, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _oro.withOpacity(0.2)))));

  // Area cliccabile per selezionare/deselezionare un file; bordo verde se file scelto
  Widget _selezioneFile(String? percorso, String? nome, {String? currentPath, required VoidCallback onTap, VoidCallback? onClear}) =>
    GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: _nero, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: percorso != null ? const Color(0xFF2ECC71) : _oro.withOpacity(0.3), width: 1.5)),
      child: Row(children: [
        Icon(percorso != null ? Icons.check_circle : Icons.upload_file,
          color: percorso != null ? const Color(0xFF2ECC71) : _oro, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(
          nome ?? (currentPath != null && currentPath.isNotEmpty ? '📎 ${currentPath.split('/').last}' : 'Tocca per scegliere un file...'),
          style: TextStyle(color: percorso != null ? Colors.white : Colors.white38, fontSize: 13),
          overflow: TextOverflow.ellipsis)),
        if (percorso != null && onClear != null) GestureDetector(onTap: onClear, child: const Icon(Icons.close, color: Colors.white38, size: 18)),
      ])));

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Spartiti'), actions: [
      // Icona cloud: verde = online, grigio = offline
      Padding(padding: const EdgeInsets.only(right: 12),
        child: Icon(_eOnline ? Icons.cloud_done : Icons.cloud_off, color: _eOnline ? const Color(0xFF2ECC71) : Colors.grey))]),
    body: _staCaricando
      ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_oro)))
      : _spartiti.isEmpty
        ? const Center(child: Text('Nessuno spartito.\nPremi + per aggiungerne uno!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC5A880))))
        // Pull-to-refresh per ricontattare il server manualmente
        : RefreshIndicator(color: _oro, onRefresh: _caricaSpartiti,
            child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _spartiti.length,
              itemBuilder: (ctx, i) {
                final s      = _spartiti[i];
                final haNota = s['note'] != null && s['note'].toString().isNotEmpty;
                final sync   = (s['synced'] as int? ?? 0) == 1;   // 1 = sincronizzato col server
                final locale = !(s['percorso_file']?.toString().startsWith('http') ?? false);
                return Card(
                  color: _scuro, margin: const EdgeInsets.only(bottom: 10), elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _oro.withOpacity(0.12))),
                  child: ListTile(
                    onTap: () => _apriSpartito(s),
                    leading: CircleAvatar(backgroundColor: _oro.withOpacity(0.1), child: const Icon(Icons.picture_as_pdf, color: _oro)),
                    title: Text(s['nome_file'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 4),
                      Row(children: [
                        // Icona diversa: cloud verde = sync, smartphone = solo locale, cloud = remoto non sync
                        Icon(sync ? Icons.cloud_done : (locale ? Icons.smartphone : Icons.cloud), size: 11, color: sync ? const Color(0xFF2ECC71) : Colors.white38),
                        const SizedBox(width: 4),
                        Text(sync ? 'Sincronizzato' : 'Solo locale', style: TextStyle(color: sync ? const Color(0xFF2ECC71) : Colors.white38, fontSize: 11)),
                      ]),
                      if (haNota) ...[const SizedBox(height: 4), Text('📝 ${s['note']}', style: const TextStyle(color: Colors.white54, fontSize: 11))],
                    ]),
                    isThreeLine: haNota, // allarga la card se c'è la nota
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: Color(0xFFC5A880)), onPressed: () => _mostraDialogoModifica(s)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.white38),  onPressed: () => _eliminaSpartito(s)),
                    ]),
                  ),
                );
              })),
    floatingActionButton: FloatingActionButton(
      onPressed: _mostraDialogoAggiunta, backgroundColor: _oro, foregroundColor: _nero,
      child: const Icon(Icons.add, size: 28)));
}

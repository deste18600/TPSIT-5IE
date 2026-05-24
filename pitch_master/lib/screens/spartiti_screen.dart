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
  bool _isLoading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadSpartiti();
  }

  /// Carica spartiti: prima mostra il locale, poi sincronizza col server.
  Future<void> _loadSpartiti() async {
    setState(() => _isLoading = true);

    // 1. Mostra subito la cache locale (risposta istantanea)
    final local = await DatabaseHelper.getAllSpartiti();
    setState(() {
      _spartiti = local;
      _isLoading = false;
    });

    // 2. Prova a contattare il server
    final remote = await ApiService.getAllSpartiti();
    if (remote == null) {
      setState(() => _isOnline = false);
      return;
    }

    // 3. Merge: aggiorna SQLite con i dati del server
    final remoteList = List<Map<String, dynamic>>.from(remote);
    await DatabaseHelper.mergeSpartiti(remoteList);

    // 4. Tenta di sincronizzare i record locali non ancora inviati
    await _syncUnsynced();

    // 5. Rileggi la lista finale (locale + aggiornata dal server)
    final merged = await DatabaseHelper.getAllSpartiti();
    if (mounted) {
      setState(() {
        _spartiti = merged;
        _isOnline = true;
      });
    }
  }

  /// Invia al server tutti gli spartiti con synced=0 e sync_pending=0.
  /// sync_pending evita di reinviare record la cui richiesta è già partita
  /// ma non ha ancora ricevuto risposta (prevenzione duplicati al riavvio).
  Future<void> _syncUnsynced() async {
    final unsynced = await DatabaseHelper.getUnsyncedSpartiti();
    for (final s in unsynced) {
      final localId = s['id'] as int;

      // Marca immediatamente come "invio in corso" prima della chiamata HTTP
      await DatabaseHelper.markSyncPending(localId);

      final percorso = s['percorso_file']?.toString() ?? '';
      String percorsoServer = percorso;
      if (percorso.isNotEmpty && !percorso.startsWith('http')) {
        final file = File(percorso);
        if (await file.exists()) {
          final url = await ApiService.uploadFile(percorso, p.basename(percorso), null);
          if (url != null) percorsoServer = url;
        }
      }

      final created = await ApiService.createSpartito({
        'nome_file':     s['nome_file'],
        'percorso_file': percorsoServer,
        'note':          s['note'] ?? '',
      });

      if (created != null) {
        final remoteId = created['id']?.toString() ?? '';
        if (remoteId.isNotEmpty) {
          await DatabaseHelper.markSynced(localId, remoteId);
          if (percorsoServer != percorso) {
            await DatabaseHelper.updateSpartito(localId, {'percorso_file': percorsoServer});
          }
        } else {
          // Risposta malformata: rimette in coda
          await DatabaseHelper.unmarkSyncPending(localId);
        }
      } else {
        // Server non raggiungibile: rimette in coda per il prossimo avvio
        await DatabaseHelper.unmarkSyncPending(localId);
      }
    }
  }

  Future<String?> _copyFileToAppDir(String sourcePath, String fileName) async {
    try {
      final appDir     = await getApplicationDocumentsDirectory();
      final spartitDir = Directory(p.join(appDir.path, 'spartiti'));
      if (!await spartitDir.exists()) await spartitDir.create(recursive: true);

      // Se esiste già un file con lo stesso nome, aggiunge un suffisso univoco
      // per evitare di sovrascrivere file di spartiti diversi
      String destName = fileName;
      String dest     = p.join(spartitDir.path, destName);
      if (await File(dest).exists()) {
        final ext      = p.extension(fileName);
        final baseName = p.basenameWithoutExtension(fileName);
        final suffix   = DateTime.now().millisecondsSinceEpoch;
        destName = '${baseName}_$suffix$ext';
        dest     = p.join(spartitDir.path, destName);
      }

      await File(sourcePath).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openFile(Map<String, dynamic> spartito) async {
    final percorso = spartito['percorso_file']?.toString() ?? '';
    final nomeFile = spartito['nome_file']?.toString() ?? '';

    // Prova prima il percorso diretto
    if (percorso.isNotEmpty && !percorso.startsWith('http')) {
      if (await _apriFileLocale(percorso)) return;
    }

    // Prova nella cartella spartiti dell'app
    try {
      final appDir    = await getApplicationDocumentsDirectory();
      final localPath = p.join(appDir.path, 'spartiti', nomeFile);
      if (await File(localPath).exists()) {
        if (await _apriFileLocale(localPath)) return;
      }
    } catch (_) {}

    // Fallback: apri URL remoto
    if (percorso.startsWith('http')) {
      final uri = Uri.tryParse(percorso);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // File non trovato né in locale né online — mostra dialogo informativo
    _showFileNotAvailableDialog(spartito['nome_file']?.toString() ?? 'questo spartito');
  }

  void _showFileNotAvailableDialog(String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.25), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: const Color(0xFFD4AF37).withOpacity(0.8), size: 22),
            const SizedBox(width: 10),
            const Text('File non disponibile',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Il file di "$nome" non è più presente su questo dispositivo.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFFC5A880).withOpacity(0.8), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Questa card funge da promemoria.\nPremi ✏️ per ricollegare il file.',
                      style: TextStyle(color: Color(0xFFC5A880), fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)),
            child: const Text('Chiudi'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(
                _spartiti.firstWhere((s) => s['nome_file'] == nome, orElse: () => {}),
              );
            },
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Ricarica file'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _apriFileLocale(String path) async {
    try {
      if (!await File(path).exists()) return false;
      final result = await OpenFilex.open(path);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF161616),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
    ));
  }

  void _showAddDialog() {
    final nomeController  = TextEditingController();
    final noteController  = TextEditingController();
    String? filePath;
    String? fileName;

    final accordaturePreset = ['Standard', 'Drop D', 'Open G', 'Open D', 'DADGAD'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: const Color(0xFFD4AF37).withOpacity(0.25), width: 1.5),
          ),
          title: const Text('Nuovo Spartito',
              style: TextStyle(
                  color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nome *'),
                _buildTextField(
                    controller: nomeController,
                    hint: 'Es. Wish You Were Here, Intro...'),
                const SizedBox(height: 16),

                _buildLabel('Capotasto / Accordatura (opzionale)'),
                _buildTextField(
                    controller: noteController,
                    hint: 'Es. Capotasto al 2, Drop D...'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: accordaturePreset
                      .map((preset) => GestureDetector(
                            onTap: () {
                              noteController.text = preset;
                              setDialogState(() {});
                            },
                            child: Chip(
                              label: Text(preset,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFD4AF37))),
                              backgroundColor: const Color(0xFF0A0A0A),
                              side: BorderSide(
                                  color: const Color(0xFFD4AF37)
                                      .withOpacity(0.3)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                _buildLabel('File (PDF o immagine) *'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null &&
                        result.files.single.path != null) {
                      setDialogState(() {
                        filePath = result.files.single.path;
                        fileName = result.files.single.name;
                        if (nomeController.text.isEmpty) {
                          nomeController.text = result.files.single.name
                              .replaceAll(
                                  RegExp(
                                      r'\.(pdf|jpg|jpeg|png)$',
                                      caseSensitive: false),
                                  '');
                        }
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: filePath != null
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          filePath != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: filePath != null
                              ? const Color(0xFF2ECC71)
                              : const Color(0xFFD4AF37),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName ?? 'Tocca per scegliere un file...',
                            style: TextStyle(
                              color: filePath != null
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (filePath != null)
                          GestureDetector(
                            onTap: () => setDialogState(
                                () { filePath = null; fileName = null; }),
                            child: const Icon(Icons.close,
                                color: Colors.white38, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC5A880)),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) {
                  _showSnack('Inserisci il nome.');
                  return;
                }
                if (filePath == null) {
                  _showSnack('Seleziona un file.');
                  return;
                }

                // 1. Copia il file nella cartella interna dell'app
                final localPath =
                    await _copyFileToAppDir(filePath!, fileName!);
                if (localPath == null) {
                  _showSnack('Errore nel salvataggio del file.');
                  return;
                }

                // 2. Salva in SQLite con synced = 0 (non ancora sul server)
                final localId = await DatabaseHelper.insertSpartito({
                  'nome_file':     nome,
                  'percorso_file': localPath,
                  'note':          noteController.text.trim(),
                  'synced':        0,
                });

                // Chiudi il dialog — l'utente non aspetta il server
                Navigator.pop(context);

                // Aggiorna la lista subito con il dato locale
                final updated = await DatabaseHelper.getAllSpartiti();
                if (mounted) setState(() => _spartiti = updated);

                // 3. In background: tenta upload + creazione sul server
                _pushToServer(
                  localId:   localId,
                  nome:      nome,
                  localPath: localPath,
                  fileName:  fileName!,
                  note:      noteController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0A0A0A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salva',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Invia un singolo spartito al server in background.
  /// Usa sync_pending per evitare duplicati se l'app viene chiusa a metà.
  Future<void> _pushToServer({
    required int localId,
    required String nome,
    required String localPath,
    required String fileName,
    required String note,
  }) async {
    // Marca subito come "invio in corso"
    await DatabaseHelper.markSyncPending(localId);

    String percorsoServer = localPath;
    final url = await ApiService.uploadFile(localPath, fileName, null);
    if (url != null) percorsoServer = url;

    final created = await ApiService.createSpartito({
      'nome_file':     nome,
      'percorso_file': percorsoServer,
      'note':          note,
    });

    if (created != null) {
      final remoteId = created['id']?.toString() ?? '';
      if (remoteId.isNotEmpty) {
        await DatabaseHelper.markSynced(localId, remoteId);
        if (percorsoServer != localPath) {
          await DatabaseHelper.updateSpartito(localId, {'percorso_file': percorsoServer});
        }
        if (mounted) {
          final updated = await DatabaseHelper.getAllSpartiti();
          setState(() { _spartiti = updated; _isOnline = true; });
        }
      } else {
        await DatabaseHelper.unmarkSyncPending(localId);
      }
    } else {
      // Offline: rimette in coda per il prossimo avvio
      await DatabaseHelper.unmarkSyncPending(localId);
    }
  }

  void _showEditDialog(Map<String, dynamic> spartito) {
    if (spartito.isEmpty) return;

    final nomeController = TextEditingController(text: spartito['nome_file'] ?? '');
    final noteController = TextEditingController(text: spartito['note'] ?? '');
    final percorsoAttuale = spartito['percorso_file']?.toString() ?? '';
    String? newFilePath;
    String? newFileName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.25), width: 1.5),
          ),
          title: const Text('Modifica',
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nome'),
                _buildTextField(controller: nomeController, hint: 'Nome spartito'),
                const SizedBox(height: 12),
                _buildLabel('Capotasto / Accordatura'),
                _buildTextField(controller: noteController, hint: 'Es. Capotasto al 3, Drop D...'),
                const SizedBox(height: 16),
                _buildLabel('Ricollega file (opzionale)'),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null && result.files.single.path != null) {
                      setDialogState(() {
                        newFilePath = result.files.single.path;
                        newFileName = result.files.single.name;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: newFilePath != null
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          newFilePath != null ? Icons.check_circle : Icons.upload_file,
                          color: newFilePath != null ? const Color(0xFF2ECC71) : const Color(0xFFD4AF37),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            newFileName ??
                                (percorsoAttuale.isNotEmpty
                                    ? '📎 ${percorsoAttuale.split('/').last}'
                                    : 'Tocca per aggiungere un file'),
                            style: TextStyle(
                              color: newFilePath != null ? Colors.white : Colors.white38,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final localId  = spartito['id'] as int;
                final remoteId = spartito['remote_id']?.toString();

                Map<String, dynamic> fields = {
                  'nome_file': nomeController.text.trim(),
                  'note':      noteController.text.trim(),
                };

                // Se l'utente ha scelto un nuovo file, copialo e aggiorna il percorso
                if (newFilePath != null && newFileName != null) {
                  final localPath = await _copyFileToAppDir(newFilePath!, newFileName!);
                  if (localPath != null) {
                    fields['percorso_file'] = localPath;
                    fields['synced'] = 0; // da risincronizzare
                  }
                }

                await DatabaseHelper.updateSpartito(localId, fields);

                if (remoteId != null && remoteId.isNotEmpty) {
                  ApiService.patchSpartito(remoteId, {
                    'nome_file': fields['nome_file'],
                    'note':      fields['note'],
                  });
                }

                Navigator.pop(context);
                _loadSpartiti();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0A0A0A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSpartito(Map<String, dynamic> spartito) async {
    final localId  = spartito['id'] as int;
    final remoteId = spartito['remote_id']?.toString();

    // Elimina prima in locale (risposta immediata)
    await DatabaseHelper.deleteSpartito(localId);

    // Poi prova a eliminare sul server (solo se sincronizzato)
    if (remoteId != null && remoteId.isNotEmpty) {
      ApiService.deleteSpartito(remoteId);
    }

    final updated = await DatabaseHelper.getAllSpartiti();
    if (mounted) setState(() => _spartiti = updated);
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
              color: Color(0xFFC5A880),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            )),
      );

  Widget _buildTextField(
          {required TextEditingController controller,
          required String hint}) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF0A0A0A),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: const Color(0xFFD4AF37).withOpacity(0.2)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spartiti'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color:
                  _isOnline ? const Color(0xFF2ECC71) : Colors.grey,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFD4AF37))))
          : _spartiti.isEmpty
              ? const Center(
                  child: Text(
                    'Nessuno spartito.\nPremi + per aggiungerne uno!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFC5A880)),
                  ))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _spartiti.length,
                  itemBuilder: (context, index) {
                    final spartito = _spartiti[index];
                    final hasNote  = spartito['note'] != null &&
                        spartito['note'].toString().isNotEmpty;
                    final isSynced = (spartito['synced'] as int? ?? 0) == 1;
                    final isLocal  = !(spartito['percorso_file']
                                ?.toString()
                                .startsWith('http') ??
                            false);

                    return Card(
                      color: const Color(0xFF161616),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color:
                                const Color(0xFFD4AF37).withOpacity(0.12),
                            width: 1.0),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => _openFile(spartito),
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFFD4AF37).withOpacity(0.1),
                          child: const Icon(Icons.picture_as_pdf,
                              color: Color(0xFFD4AF37)),
                        ),
                        title: Text(
                          spartito['nome_file'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(
                                isSynced
                                    ? Icons.cloud_done
                                    : (isLocal
                                        ? Icons.smartphone
                                        : Icons.cloud),
                                size: 11,
                                color: isSynced
                                    ? const Color(0xFF2ECC71)
                                    : Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSynced
                                    ? 'Sincronizzato'
                                    : 'Solo locale',
                                style: TextStyle(
                                  color: isSynced
                                      ? const Color(0xFF2ECC71)
                                      : Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ]),
                            if (hasNote) ...[
                              const SizedBox(height: 4),
                              Text('📝 ${spartito['note']}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                            ],
                          ],
                        ),
                        isThreeLine: hasNote,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFC5A880)),
                              onPressed: () => _showEditDialog(spartito),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.white38),
                              onPressed: () => _deleteSpartito(spartito),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: const Color(0xFF0A0A0A),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

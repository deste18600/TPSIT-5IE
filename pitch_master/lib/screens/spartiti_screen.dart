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

  Future<void> _loadSpartiti() async {
    setState(() => _isLoading = true);
    final remote = await ApiService.getAllSpartiti();
    if (remote != null) {
      final list = List<Map<String, dynamic>>.from(remote);
      await DatabaseHelper.cacheSpartiti(list);
      setState(() {
        _spartiti = list;
        _isOnline = true;
        _isLoading = false;
      });
    } else {
      final local = await DatabaseHelper.getAllSpartiti();
      setState(() {
        _spartiti = local;
        _isOnline = false;
        _isLoading = false;
      });
    }
  }

  Future<String?> _copyFileToAppDir(String sourcePath, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final spartitDir = Directory(p.join(appDir.path, 'spartiti'));
      if (!await spartitDir.exists()) await spartitDir.create(recursive: true);
      final dest = p.join(spartitDir.path, fileName);
      await File(sourcePath).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openFile(Map<String, dynamic> spartito) async {
    final percorso = spartito['percorso_file']?.toString() ?? '';
    final nomeFile = spartito['nome_file']?.toString() ?? '';

    if (percorso.isEmpty) { _showSnack('Nessun file disponibile.'); return; }

    if (!percorso.startsWith('http')) {
      if (await _apriFileLocale(percorso)) return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = p.join(appDir.path, 'spartiti', nomeFile);
      if (await File(localPath).exists()) {
        if (await _apriFileLocale(localPath)) return;
      }
    } catch (_) {}

    if (percorso.startsWith('http')) {
      final uri = Uri.tryParse(percorso);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    _showSnack('File non trovato.');
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
    final nomeController = TextEditingController();
    final noteController = TextEditingController();
    String? filePath;
    String? fileName;
    bool isUploading = false;

    final accordaturePreset = ['Standard', 'Drop D', 'Open G', 'Open D', 'DADGAD'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.25), width: 1.5),
          ),
          title: const Text('Nuovo Spartito',
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nome *'),
                _buildTextField(controller: nomeController, hint: 'Es. Wish You Were Here, Intro...'),
                const SizedBox(height: 16),

                _buildLabel('Capotasto / Accordatura (opzionale)'),
                _buildTextField(controller: noteController, hint: 'Es. Capotasto al 2, Drop D...'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: accordaturePreset.map((preset) => GestureDetector(
                    onTap: () { noteController.text = preset; setDialogState(() {}); },
                    child: Chip(
                      label: Text(preset, style: const TextStyle(fontSize: 11, color: Color(0xFFD4AF37))),
                      backgroundColor: const Color(0xFF0A0A0A),
                      side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                _buildLabel('File (PDF o immagine) *'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    );
                    if (result != null && result.files.single.path != null) {
                      setDialogState(() {
                        filePath = result.files.single.path;
                        fileName = result.files.single.name;
                        if (nomeController.text.isEmpty) {
                          nomeController.text = result.files.single.name
                              .replaceAll(RegExp(r'\.(pdf|jpg|jpeg|png)$', caseSensitive: false), '');
                        }
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: filePath != null ? const Color(0xFF2ECC71) : const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          filePath != null ? Icons.check_circle : Icons.upload_file,
                          color: filePath != null ? const Color(0xFF2ECC71) : const Color(0xFFD4AF37),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName ?? 'Tocca per scegliere un file...',
                            style: TextStyle(
                              color: filePath != null ? Colors.white : Colors.white38,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (filePath != null)
                          GestureDetector(
                            onTap: () => setDialogState(() { filePath = null; fileName = null; }),
                            child: const Icon(Icons.close, color: Colors.white38, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),

                if (isUploading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(color: Color(0xFFD4AF37), backgroundColor: Color(0xFF222222)),
                  const SizedBox(height: 6),
                  const Text('Salvataggio...', style: TextStyle(color: Color(0xFFC5A880), fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                final nome = nomeController.text.trim();
                if (nome.isEmpty) { _showSnack('Inserisci il nome.'); return; }
                if (filePath == null) { _showSnack('Seleziona un file.'); return; }

                setDialogState(() => isUploading = true);

                // 1. Copia locale immediata — nessun delay
                final localPath = await _copyFileToAppDir(filePath!, fileName!);
                if (localPath == null) {
                  setDialogState(() => isUploading = false);
                  _showSnack('Errore nel salvataggio del file.');
                  return;
                }

                // 2. Salva subito in SQLite (istantaneo, non aspetta il server)
                final spartitoCache = {
                  'nome_file': nome,
                  'percorso_file': localPath,
                  'note': noteController.text.trim(),
                };
                await DatabaseHelper.insertSpartito(spartitoCache);

                // Chiudi subito il dialog — l'utente non aspetta
                Navigator.pop(context);
                _loadSpartiti();

                // 3. Prova upload server in background (non blocca l'UI)
                ApiService.uploadFile(filePath!, fileName!, null).then((uploaded) {
                  ApiService.createSpartito({
                    'nome_file': nome,
                    'percorso_file': uploaded ?? localPath,
                    'note': noteController.text.trim(),
                  });
                });
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

  void _showEditDialog(Map<String, dynamic> spartito) {
    final nomeController = TextEditingController(text: spartito['nome_file'] ?? '');
    final noteController = TextEditingController(text: spartito['note'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.25), width: 1.5),
        ),
        title: const Text('Modifica',
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nome'),
            _buildTextField(controller: nomeController, hint: 'Nome spartito'),
            const SizedBox(height: 12),
            _buildLabel('Capotasto / Accordatura'),
            _buildTextField(controller: noteController, hint: 'Es. Capotasto al 3, Drop D...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5A880)),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rawId = spartito['id'];
              final dbId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
              final fields = {
                'nome_file': nomeController.text.trim(),
                'note': noteController.text.trim(),
              };
              await DatabaseHelper.updateSpartito(dbId, fields);
              ApiService.patchSpartito(rawId, fields);
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
    );
  }

  Future<void> _deleteSpartito(Map<String, dynamic> spartito) async {
    final rawId = spartito['id'];
    final dbId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    await DatabaseHelper.deleteSpartito(dbId);
    ApiService.deleteSpartito(rawId);
    _loadSpartiti();
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(
      color: Color(0xFFC5A880), fontSize: 12,
      fontWeight: FontWeight.w600, letterSpacing: 0.4,
    )),
  );

  Widget _buildTextField({required TextEditingController controller, required String hint}) =>
    TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2)),
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
              color: _isOnline ? const Color(0xFF2ECC71) : Colors.grey,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))))
          : _spartiti.isEmpty
              ? const Center(child: Text(
                  'Nessuno spartito.\nPremi + per aggiungerne uno!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFC5A880))))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _spartiti.length,
                  itemBuilder: (context, index) {
                    final spartito = _spartiti[index];
                    final hasNote = spartito['note'] != null &&
                        spartito['note'].toString().isNotEmpty;
                    final isLocal = !(spartito['percorso_file']
                            ?.toString().startsWith('http') ?? false);

                    return Card(
                      color: const Color(0xFF161616),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.12), width: 1.0),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => _openFile(spartito),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37)),
                        ),
                        title: Text(
                          spartito['nome_file'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(isLocal ? Icons.smartphone : Icons.cloud,
                                  size: 11, color: isLocal ? Colors.white38 : const Color(0xFF2ECC71)),
                              const SizedBox(width: 4),
                              Text(isLocal ? 'Locale' : 'Server',
                                  style: TextStyle(
                                    color: isLocal ? Colors.white38 : const Color(0xFF2ECC71),
                                    fontSize: 11,
                                  )),
                            ]),
                            if (hasNote) ...[
                              const SizedBox(height: 4),
                              Text('📝 ${spartito['note']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ],
                        ),
                        isThreeLine: hasNote,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFFC5A880)),
                              onPressed: () => _showEditDialog(spartito),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white38),
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

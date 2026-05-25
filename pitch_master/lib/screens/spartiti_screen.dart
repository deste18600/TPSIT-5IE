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
  State<SpartitiScreen> createState() {
    return _SpartitiScreenState();
  }
}

class _SpartitiScreenState extends State<SpartitiScreen> {
  List<Map<String, dynamic>> _spartiti = [];
  bool _staCaricando = true; 
  bool _eOnline      = false; 

  static const _oro   = Color(0xFFD4AF37);
  static const _scuro = Color(0xFF161616);
  static const _nero  = Color(0xFF0A0A0A);

  @override
  void initState() { 
    super.initState(); 
    _caricaSpartiti(); 
  }

  Future<void> _caricaSpartiti() async {
    setState(() {
      _staCaricando = true;
    });

    _spartiti = await DatabaseHelper.getAllSpartiti();
    
    setState(() {
      _staCaricando = false;
    });

    final dal = await ApiService.getAllSpartiti();
    if (dal == null) { 
      setState(() {
        _eOnline = false;
      }); 
      return; 
    }

    await DatabaseHelper.mergeSpartiti(List<Map<String,dynamic>>.from(dal));
    await _sincronizzaOffline();

    if (mounted) {
      _spartiti = await DatabaseHelper.getAllSpartiti();
      setState(() {
        _eOnline = true;
      });
    }
  }

  Future<void> _sincronizzaOffline() async {
    for (final s in await DatabaseHelper.getUnsyncedSpartiti()) {
      final id = s['id'] as int;
      String remoteId = s['remote_id']?.toString() ?? '';
      final percorso = s['percorso_file']?.toString() ?? '';
      
      await DatabaseHelper.markSyncPending(id);

      String percorsoSrv = percorso;
      if (percorso.isNotEmpty && !percorso.startsWith('http')) {
        final url = await ApiService.uploadFile(percorso, p.basename(percorso), null);
        if (url != null) {
          percorsoSrv = url;
        }
      }

      final payload = {'nome_file': s['nome_file'], 'percorso_file': percorsoSrv, 'note': s['note'] ?? ''};
      bool successo = false;

      if (remoteId.isNotEmpty) {
        successo = (await ApiService.patchSpartito(remoteId, payload)) != null;
      } else {
        final res = await ApiService.createSpartito(payload);
        if (res?['id'] != null) {
          remoteId = res!['id'].toString();
          successo = true;
        }
      }

      if (successo) {
        await DatabaseHelper.markSynced(id, remoteId);
        if (percorsoSrv != percorso) {
          await DatabaseHelper.updateSpartito(id, {'percorso_file': percorsoSrv});
        }
      } else {
        await DatabaseHelper.unmarkSyncPending(id);
      }
    }
  }

  Future<void> _inviaAlServer(int id, String nome, String locale, String nomeFile, String note) async {
    await DatabaseHelper.markSyncPending(id);
    String srv = locale;
    
    final url = await ApiService.uploadFile(locale, nomeFile, null);
    if (url != null) {
      srv = url;
    }
    
    final res = await ApiService.createSpartito({'nome_file': nome, 'percorso_file': srv, 'note': note});
    
    if (res?['id'] != null) {
      await DatabaseHelper.markSynced(id, res!['id'].toString());
      if (srv != locale) {
        await DatabaseHelper.updateSpartito(id, {'percorso_file': srv});
      }
      if (mounted) { 
        _spartiti = await DatabaseHelper.getAllSpartiti(); 
        setState(() {
          _eOnline = true;
        }); 
      }
    } else {
      await DatabaseHelper.unmarkSyncPending(id);
    }
  }

  Future<void> _eliminaSpartito(Map<String, dynamic> s) async {
    await DatabaseHelper.deleteSpartito(s['id'] as int);
    final rid = s['remote_id']?.toString();
    if (rid?.isNotEmpty == true) {
      ApiService.deleteSpartito(rid!);
    }
    
    final lista = await DatabaseHelper.getAllSpartiti();
    if (mounted) {
      setState(() {
        _spartiti = lista;
      });
    }
  }

  Future<String?> _copiaFile(String src, String nome) async {
    try {
      final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'spartiti'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      var dest = p.join(dir.path, nome);
      if (await File(dest).exists()) {
        dest = p.join(dir.path, '${p.basenameWithoutExtension(nome)}_${DateTime.now().millisecondsSinceEpoch}${p.extension(nome)}');
      }
      await File(src).copy(dest);
      return dest;
    } catch (_) { 
      return null; 
    }
  }

  Future<void> _apriSpartito(Map<String, dynamic> s) async {
    final percorso = s['percorso_file']?.toString() ?? '';
    final nome     = s['nome_file']?.toString() ?? '';

    if (percorso.isNotEmpty && !percorso.startsWith('http') && await File(percorso).exists()) {
      if ((await OpenFilex.open(percorso)).type == ResultType.done) {
        return;
      }
    }
    
    final f = p.join((await getApplicationDocumentsDirectory()).path, 'spartiti', nome);
    if (await File(f).exists()) {
      if ((await OpenFilex.open(f)).type == ResultType.done) {
        return;
      }
    }

    if (percorso.startsWith('http')) {
      final uri = Uri.tryParse(percorso);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
 
    _mostraDialogoFileAssente(nome);
  }

  void _mostraDialogoAggiunta() {
    final ctrlNome = TextEditingController();
    final ctrlNote = TextEditingController();
    String? percorso, nomeFile;

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, set) {
            return AlertDialog(
              backgroundColor: _scuro, 
              title: const Text('Nuovo Spartito', style: TextStyle(color: _oro)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    TextField(controller: ctrlNome, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nome *', labelStyle: TextStyle(color: _oro))),
                    TextField(controller: ctrlNote, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Capotasto/Note', labelStyle: TextStyle(color: _oro))),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(percorso == null ? Icons.upload_file : Icons.check, color: percorso == null ? _oro : Colors.green),
                      label: Text(nomeFile ?? 'Seleziona File PDF/IMG', style: const TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','jpeg','png']);
                        if (r?.files.single.path != null) {
                          set(() {
                            percorso = r!.files.single.path; 
                            nomeFile = r.files.single.name;
                            if (ctrlNome.text.isEmpty) {
                              ctrlNome.text = p.basenameWithoutExtension(nomeFile!);
                            }
                          });
                        }
                      },
                    ),
                  ]
                )
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  }, 
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _oro, foregroundColor: _nero),
                  child: const Text('Salva'),
                  onPressed: () async {
                    if (ctrlNome.text.trim().isEmpty || percorso == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compila nome e seleziona un file')));
                      return;
                    }
                    
                    final locale = await _copiaFile(percorso!, nomeFile!);
                    if (locale == null) {
                      return;
                    }
                    
                    final nome = ctrlNome.text.trim();
                    final note = ctrlNote.text.trim();
                    final id = await DatabaseHelper.insertSpartito({'nome_file': nome, 'percorso_file': locale, 'note': note, 'synced': 0});
                    
                    Navigator.pop(ctx);
                    final lista = await DatabaseHelper.getAllSpartiti();
                    if (mounted) {
                      setState(() {
                        _spartiti = lista;
                      });
                    }
                    
                    _inviaAlServer(id, nome, locale, nomeFile!, note);
                  }
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _mostraDialogoModifica(Map<String, dynamic> s) {
    final ctrlNome = TextEditingController(text: s['nome_file'] ?? '');
    final ctrlNote = TextEditingController(text: s['note'] ?? '');
    String? nuovoPercorso, nuovoNome;

    showDialog(
      context: context, 
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, set) {
            return AlertDialog(
              backgroundColor: _scuro, 
              title: const Text('Modifica', style: TextStyle(color: _oro)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    TextField(controller: ctrlNome, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Nome', labelStyle: TextStyle(color: _oro))),
                    TextField(controller: ctrlNote, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Capotasto/Note', labelStyle: TextStyle(color: _oro))),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: Icon(nuovoPercorso == null ? Icons.upload_file : Icons.check, color: nuovoPercorso == null ? _oro : Colors.green),
                      label: Text(nuovoNome ?? 'Ricollega file ', style: const TextStyle(color: Colors.white)),
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','jpeg','png']);
                        if (r?.files.single.path != null) {
                          set(() { 
                            nuovoPercorso = r!.files.single.path; 
                            nuovoNome = r.files.single.name; 
                          });
                        }
                      }
                    ),
                  ]
                )
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  }, 
                  child: const Text('Annulla', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _oro, foregroundColor: _nero),
                  child: const Text('Salva'),
                  onPressed: () async {
                    final id = s['id'] as int;
                    final remoteId = s['remote_id']?.toString();
                    final campi = {'nome_file': ctrlNome.text.trim(), 'note': ctrlNote.text.trim()};
                    
                    if (nuovoPercorso != null) {
                      final loc = await _copiaFile(nuovoPercorso!, nuovoNome!);
                      if (loc != null) { 
                        campi['percorso_file'] = loc; 
                        campi['synced'] = '0'; 
                      }
                    }
                    
                    await DatabaseHelper.updateSpartito(id, campi);
                    if (remoteId?.isNotEmpty == true) {
                      ApiService.patchSpartito(remoteId!, {'nome_file': campi['nome_file'], 'note': campi['note']});
                    }
                      
                    Navigator.pop(ctx);
                    _caricaSpartiti(); 
                  }
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _mostraDialogoFileAssente(String nome) {
    showDialog(
      context: context, 
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _scuro, 
          title: const Text('File non trovato', style: TextStyle(color: _oro)),
          content: Text('Il file di "$nome" non è sul dispositivo.', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              }, 
              child: const Text('Chiudi', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _oro, foregroundColor: _nero),
              child: const Text('Ricollega file'),
              onPressed: () { 
                Navigator.pop(ctx); 
                _mostraDialogoModifica(_spartiti.firstWhere((s) {
                  return s['nome_file'] == nome;
                }, orElse: () {
                  return {};
                })); 
              }
            ),
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spartiti'), 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(_eOnline ? Icons.cloud_done : Icons.cloud_off, color: _eOnline ? Colors.green : Colors.grey)
          )
        ]
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostraDialogoAggiunta, 
        backgroundColor: _oro, 
        foregroundColor: _nero,
        child: const Icon(Icons.add, size: 28)
      )
    );
  }

  Widget _buildBody() {
    if (_staCaricando) {
      return const Center(child: CircularProgressIndicator(color: _oro));
    }
    
    if (_spartiti.isEmpty) {
      return const Center(child: Text('Nessuno spartito disponibile', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC5A880))));
    }
    
    return RefreshIndicator(
      color: _oro, 
      onRefresh: _caricaSpartiti,
      child: ListView.builder(
        padding: const EdgeInsets.all(12), 
        itemCount: _spartiti.length,
        itemBuilder: (ctx, i) {
          return _buildSpartitoCard(_spartiti[i]);
        },
      )
    );
  }

  Widget _buildSpartitoCard(Map<String, dynamic> s) {
    final haNota = s['note'] != null && s['note'].toString().isNotEmpty;
    final sync   = (s['synced'] as int? ?? 0) == 1;
    final locale = !(s['percorso_file']?.toString().startsWith('http') ?? false);
    
    return Card(
      color: _scuro, 
      margin: const EdgeInsets.only(bottom: 10), 
      child: ListTile(
        onTap: () {
          _apriSpartito(s);
        },
        leading: const Icon(Icons.picture_as_pdf, color: _oro),
        title: Text(s['nome_file'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(children: [
              Icon(sync ? Icons.cloud_done : (locale ? Icons.smartphone : Icons.cloud), size: 12, color: sync ? Colors.green : Colors.white38),
              const SizedBox(width: 4),
              Text(sync ? 'Sincronizzato' : 'Solo locale', style: TextStyle(color: sync ? Colors.green : Colors.white38, fontSize: 12)),
            ]),
            if (haNota) Text(s['note'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFC5A880)), 
              onPressed: () {
                _mostraDialogoModifica(s);
              }
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white38),  
              onPressed: () {
                _eliminaSpartito(s);
              }
            ),
          ]
        ),
      ),
    );
  }
}
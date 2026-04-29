import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

/// Mostra lo storico delle sessioni di accordatura salvate.
/// I dati vengono prima cercati sul server REST,
/// se non disponibile usa il database SQLite locale.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    // Prova prima dal server
    final remote = await ApiService.getSessions();

    if (remote != null) {
      setState(() {
        _sessions = List<Map<String, dynamic>>.from(remote);
        _isOnline = true;
        _isLoading = false;
      });
    } else {
      // Fallback al database locale
      final local = await DatabaseHelper.getSessions();
      setState(() {
        _sessions = local;
        _isOnline = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final id = session['id'];

    // Elimina dal server se online
    if (_isOnline && id != null) {
      await ApiService.deleteSession(id);
    }

    // Elimina sempre dal database locale
    await DatabaseHelper.deleteSession(id);

    // Aggiorna lista
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Storico Accordature'),
        actions: [
          // Indicatore connessione
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(
                  child: Text(
                    'Nessuna sessione salvata',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final tuned = session['tuned'] == 1;
                    final cents =
                        (session['cents_offset'] as num).toDouble();

                    return Card(
                      color: const Color(0xFF2A2A3E),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              tuned ? Colors.green : Colors.redAccent,
                          child: Icon(
                            tuned ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${session['instrument']} - ${session['string_name']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Target: ${(session['target_frequency'] as num).toStringAsFixed(1)} Hz  '
                          'Rilevato: ${(session['detected_frequency'] as num).toStringAsFixed(1)} Hz\n'
                          'Offset: ${cents.toStringAsFixed(1)} cents  •  ${session['created_at']}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white38),
                          onPressed: () => _deleteSession(session),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSessions,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
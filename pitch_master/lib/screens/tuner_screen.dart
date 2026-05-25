// ============================================================
// tuner_screen.dart
// Schermata dell'accordatore.
//
// Lo strumento attivo viene letto dal database (tabella strumenti).
// Per cambiare strumento l'utente tocca il nome in cima:
//   si apre un pannello → tocca uno strumento → chiuso.
// Una riga di codice fa il cambio: impostaStrumentoAttivo(id).
//
// Le corde sono salvate come stringa "Mi2,La2,Re3,Sol3,Si3,Mi4".
// Per usarle come lista: corde.split(',')
// ============================================================

import 'package:flutter/material.dart';
import '../models/instrument.dart';
import '../services/audio_service.dart';
import '../services/database_helper.dart';
import '../widgets/frequency_gauge.dart';
import '../widgets/string_selector.dart';


class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}


class _TunerScreenState extends State<TunerScreen> {

  final AudioService _audioService = AudioService();

  // Nome e corde dello strumento attivo (caricati dal DB)
  String       _nomeStrumento = '';
  List<String> _corde         = [];
  int          _idStrumento   = -1;    // id SQLite dello strumento attivo

  // Lista di tutti gli strumenti (per il menu)
  List<Map<String, dynamic>> _tuttiGliStrumenti = [];

  int    _indiceCorda       = 0;
  double _frequenzaRilevata = 0.0;
  double _scostamentoCents  = 0.0;


  // ── Avvio ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _caricaStrumentoAttivo(); // legge il DB e imposta le variabili

    _audioService.frequencyStream.listen((freq) {
      final target = _ottieniFrequenzaTarget();
      final cents  = AudioService.calculateCents(freq, target);
      setState(() {
        _frequenzaRilevata = freq;
        _scostamentoCents  = cents.clamp(-100.0, 100.0);
      });
    });
  }


  // ── Carica strumento attivo dal database ──────────────────
  // Legge la riga con attivo=1 dalla tabella strumenti,
  // poi splitta la stringa corde in lista.
  Future<void> _caricaStrumentoAttivo() async {
    final tutti  = await DatabaseHelper.getAllStrumenti();
    final attivo = await DatabaseHelper.getStrumentoAttivo();

    if (attivo == null) return;

    // "Mi2,La2,Re3" → ['Mi2', 'La2', 'Re3']
    final corde = attivo['corde'].toString().split(',');

    setState(() {
      _tuttiGliStrumenti = tutti;
      _idStrumento       = attivo['id'] as int;
      _nomeStrumento     = attivo['nome'].toString();
      _corde             = corde;
      _indiceCorda       = 0;       // torna alla prima corda quando si cambia strumento
    });

    _audioService.setTargetFrequency(_ottieniFrequenzaTarget());
  }


  // ── Cambia strumento ──────────────────────────────────────
  // UNA SOLA chiamata al DB: imposta attivo=1 su questo, 0 su tutti gli altri.
  // Poi ricarica i dati. Semplice.
  Future<void> _cambiaStrumento(int nuovoId) async {
    await DatabaseHelper.impostaStrumentoAttivo(nuovoId);
    await _caricaStrumentoAttivo();
  }


  // ── Corda selezionata ─────────────────────────────────────
  void _cambiaCorda(int nuovoIndice) {
    setState(() => _indiceCorda = nuovoIndice);
    _audioService.setTargetFrequency(_ottieniFrequenzaTarget());
  }

  double _ottieniFrequenzaTarget() {
    if (_corde.isEmpty) return 110.0;
    final nota = _corde[_indiceCorda];
    return noteFrequencies[nota] ?? 110.0;
  }


  // ── Testo e colore di stato ───────────────────────────────
  String _statoTesto() {
    if (_frequenzaRilevata == 0)       return 'Inizia a suonare';
    if (_scostamentoCents.abs() <= 5)  return 'Accordato! ✓';
    if (_scostamentoCents < 0)         return 'Accordare più in alto';
    return                                    'Accordare più in basso';
  }

  Color _statoColore() {
    if (_frequenzaRilevata == 0)       return Colors.white70;
    if (_scostamentoCents.abs() <= 5)  return Colors.green;
    if (_scostamentoCents.abs() <= 20) return Colors.orange;
    return                                    Colors.redAccent;
  }


  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }


  // ══════════════════════════════════════════════════════════
  //  INTERFACCIA
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {

    // Se il DB non è ancora caricato, mostra uno spinner
    if (_corde.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    final notaTarget = _corde[_indiceCorda];
    final freqTarget  = _ottieniFrequenzaTarget();

    return Scaffold(
      appBar: AppBar(
        title:       _costruisciSelettoreStrumento(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Nota target
                Text(notaTarget,
                    style: const TextStyle(
                        color: Color(0xFFD4AF37), fontSize: 42, fontWeight: FontWeight.bold)),

                // Frequenza target
                Text('${freqTarget.toStringAsFixed(1)} Hz',
                    style: const TextStyle(color: Color(0xFFC5A880), fontSize: 14)),

                const SizedBox(height: 12),

                FrequencyGauge(centsOffset: _scostamentoCents),

                const SizedBox(height: 12),

                // Frequenza rilevata
                Text(
                  _frequenzaRilevata > 0
                      ? '${_frequenzaRilevata.toStringAsFixed(1)} Hz'
                      : '0.0 Hz',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                // Messaggio stato
                Text(_statoTesto(),
                    style: TextStyle(color: _statoColore(), fontSize: 16, fontWeight: FontWeight.w600)),

                const SizedBox(height: 16),

                // Pulsante microfono
                GestureDetector(
                  onTap: () async {
                    if (_audioService.isListening) {
                      await _audioService.stopListening();
                      setState(() { _frequenzaRilevata = 0; _scostamentoCents = 0; });
                    } else {
                      await _audioService.startListening();
                      setState(() {});
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _audioService.isListening
                          ? const Color(0xFFE74C3C).withOpacity(0.15)
                          : const Color(0xFFD4AF37).withOpacity(0.10),
                      border: Border.all(
                        color: _audioService.isListening
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFFD4AF37),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _audioService.isListening ? Icons.stop : Icons.mic,
                      size:  26,
                      color: _audioService.isListening
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFFD4AF37),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selettore corde: passa la lista già splittata
                StringSelector(
                  strings:       _corde,
                  selectedIndex: _indiceCorda,
                  onSelected:    _cambiaCorda,
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ── Selettore strumento (barra in cima) ───────────────────
  Widget _costruisciSelettoreStrumento() {
    return GestureDetector(
      onTap: _mostraMenuStrumenti,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color:        const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_nomeStrumento,
                style: const TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37), size: 20),
          ],
        ),
      ),
    );
  }


  // ── Menu per cambiare strumento ──────────────────────────
  void _mostraMenuStrumenti() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Strumento',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            // Una voce per ogni strumento: solo il nome
            ..._tuttiGliStrumenti.map((s) {
              final bool eAttivo = s['id'] == _idStrumento;
              return ListTile(
                title: Text(
                  s['nome'].toString(),
                  style: TextStyle(
                    color:      eAttivo ? const Color(0xFFD4AF37) : Colors.white70,
                    fontWeight: eAttivo ? FontWeight.bold : FontWeight.normal,
                    fontSize:   16,
                  ),
                ),
                trailing: eAttivo
                    ? const Icon(Icons.check, color: Color(0xFFD4AF37))
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _cambiaStrumento(s['id']);
                },
              );
            }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/instrument.dart';
import '../services/audio_service.dart';
import '../services/database_helper.dart';
import '../widgets/frequency_gauge.dart';
import '../widgets/string_selector.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() {
    return _TunerScreenState();
  }
}

class _TunerScreenState extends State<TunerScreen> {
  final AudioService _audioService = AudioService();

  String _nomeStrumento = '';
  List<String> _corde = [];
  int _idStrumento = -1;

  List<Map<String, dynamic>> _tuttiGliStrumenti = [];

  int _indiceCorda = 0;
  double _frequenzaRilevata = 0.0;
  double _scostamentoCents = 0.0;

  @override
  void initState() {
    super.initState();
    _caricaStrumentoAttivo();

    _audioService.frequencyStream.listen((freq) {
      final target = _ottieniFrequenzaTarget();
      final cents = AudioService.calculateCents(freq, target);
      setState(() {
        _frequenzaRilevata = freq;
        _scostamentoCents = cents.clamp(-100.0, 100.0);
      });
    });
  }

  Future<void> _caricaStrumentoAttivo() async {
    final tutti = await DatabaseHelper.getAllStrumenti();
    final attivo = await DatabaseHelper.getStrumentoAttivo();

    if (attivo == null) {
      return;
    }

    final corde = attivo['corde'].toString().split(',');

    setState(() {
      _tuttiGliStrumenti = tutti;
      _idStrumento = attivo['id'] as int;
      _nomeStrumento = attivo['nome'].toString();
      _corde = corde;
      _indiceCorda = 0;
    });

    _audioService.setTargetFrequency(_ottieniFrequenzaTarget());
  }

  Future<void> _cambiaStrumento(int nuovoId) async {
    await DatabaseHelper.impostaStrumentoAttivo(nuovoId);
    await _caricaStrumentoAttivo();
  }

  void _cambiaCorda(int nuovoIndice) {
    setState(() {
      _indiceCorda = nuovoIndice;
    });
    _audioService.setTargetFrequency(_ottieniFrequenzaTarget());
  }

  double _ottieniFrequenzaTarget() {
    if (_corde.isEmpty) {
      return 110.0;
    }
    final nota = _corde[_indiceCorda];
    return noteFrequencies[nota] ?? 110.0;
  }

  String _statoTesto() {
    if (_frequenzaRilevata == 0) {
      return 'Inizia';
    }
    if (_scostamentoCents.abs() <= 5) {
      return 'Accordato';
    }
    if (_scostamentoCents < 0) {
      return 'Accordare più in alto';
    }
    return 'Accordare più in basso';
  }

  Color _statoColore() {
    if (_frequenzaRilevata == 0) {
      return Colors.white70;
    }
    if (_scostamentoCents.abs() <= 5) {
      return Colors.green;
    }
    if (_scostamentoCents.abs() <= 20) {
      return Colors.orange;
    }
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_corde.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37))
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildSelettoreStrumento(),
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
                _buildTargetDisplay(),
                const SizedBox(height: 12),
                FrequencyGauge(centsOffset: _scostamentoCents),
                const SizedBox(height: 12),
                _buildDetectedDisplay(),
                const SizedBox(height: 16),
                _buildMicButton(),
                const SizedBox(height: 16),
                _buildStringSelector(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetDisplay() {
    final notaTarget = _corde[_indiceCorda];
    final freqTarget = _ottieniFrequenzaTarget();

    return Column(
      children: [
        Text(
          notaTarget,
          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 42, fontWeight: FontWeight.bold)
        ),
        Text(
          '${freqTarget.toStringAsFixed(1)} Hz',
          style: const TextStyle(color: Color(0xFFC5A880), fontSize: 14)
        ),
      ],
    );
  }

  Widget _buildDetectedDisplay() {
    String frequenzaFormattata = '0.0 Hz';
    if (_frequenzaRilevata > 0) {
      frequenzaFormattata = '${_frequenzaRilevata.toStringAsFixed(1)} Hz';
    }

    return Column(
      children: [
        Text(
          frequenzaFormattata,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 4),
        Text(
          _statoTesto(),
          style: TextStyle(color: _statoColore(), fontSize: 16, fontWeight: FontWeight.w600)
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    Color borderColor = const Color(0xFFD4AF37);
    Color backgroundColor = const Color(0xFFD4AF37).withOpacity(0.10);
    IconData buttonIcon = Icons.mic;

    if (_audioService.isListening) {
      borderColor = const Color(0xFFE74C3C);
      backgroundColor = const Color(0xFFE74C3C).withOpacity(0.15);
      buttonIcon = Icons.stop;
    }

    return GestureDetector(
      onTap: () async {
        if (_audioService.isListening) {
          await _audioService.stopListening();
          setState(() { 
            _frequenzaRilevata = 0; 
            _scostamentoCents = 0; 
          });
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
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Icon(buttonIcon, size: 26, color: borderColor),
      ),
    );
  }

  Widget _buildStringSelector() {
    return StringSelector(
      strings: _corde,
      selectedIndex: _indiceCorda,
      onSelected: _cambiaCorda,
    );
  }

  Widget _buildSelettoreStrumento() {
    return GestureDetector(
      onTap: () {
        _mostraMenuStrumenti();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _nomeStrumento,
              style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37), size: 20),
          ],
        ),
      ),
    );
  }

  void _mostraMenuStrumenti() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Strumento',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)
              ),
              const SizedBox(height: 8),
              ..._tuttiGliStrumenti.map((s) {
                final bool eAttivo = s['id'] == _idStrumento;
                Color textColor = Colors.white70;
                FontWeight textWeight = FontWeight.normal;
                
                if (eAttivo) {
                  textColor = const Color(0xFFD4AF37);
                  textWeight = FontWeight.bold;
                }

                Widget? trailingIcon;
                if (eAttivo) {
                  trailingIcon = const Icon(Icons.check, color: Color(0xFFD4AF37));
                }

                return ListTile(
                  title: Text(
                    s['nome'].toString(),
                    style: TextStyle(color: textColor, fontWeight: textWeight, fontSize: 16),
                  ),
                  trailing: trailingIcon,
                  onTap: () async {
                    Navigator.pop(context);
                    await _cambiaStrumento(s['id']);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }
}


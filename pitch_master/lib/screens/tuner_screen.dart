import 'package:flutter/material.dart';
import '../models/instrument.dart';
import '../services/audio_service.dart';
import '../widgets/frequency_gauge.dart';
import '../widgets/string_selector.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final AudioService _audioService = AudioService();

  Instrument _selectedInstrument = defaultInstruments[0];
  int _selectedStringIndex = 0;
  double _detectedFrequency = 0.0;
  double _centsOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTargetFrequency();

    _audioService.frequencyStream.listen((frequency) {
      final target = _getTargetFrequency();
      final cents = AudioService.calculateCents(frequency, target);

      setState(() {
        _detectedFrequency = frequency;
        _centsOffset = cents.clamp(-100.0, 100.0);
      });
    });
  }

  double _getTargetFrequency() {
    final note = _selectedInstrument.strings[_selectedStringIndex];
    return noteFrequencies[note] ?? 110.0;
  }

  void _updateTargetFrequency() {
    _audioService.setTargetFrequency(_getTargetFrequency());
  }

  void _onStringSelected(int index) {
    setState(() => _selectedStringIndex = index);
    _updateTargetFrequency();
  }

  void _onInstrumentChanged(Instrument instrument) {
    setState(() {
      _selectedInstrument = instrument;
      _selectedStringIndex = 0;
    });
    _updateTargetFrequency();
  }

  String _getTuningStatus() {
    if (_detectedFrequency == 0) return 'Inizia a suonare';
    if (_centsOffset.abs() <= 5) return 'Accordato! ✓';
    if (_centsOffset < 0) return 'Accordare più in alto';
    return 'Accordare più in basso';
  }

  Color _getStatusColor() {
    if (_detectedFrequency == 0) return Colors.white70;
    if (_centsOffset.abs() <= 5) return Colors.green;
    if (_centsOffset.abs() <= 20) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetNote = _selectedInstrument.strings[_selectedStringIndex];
    final targetFreq = _getTargetFrequency();

    return Scaffold(
      appBar: AppBar(
        title: _buildInstrumentSelector(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Nota target
                Text(
                  targetNote,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37), // Oro per la nota principale
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${targetFreq.toStringAsFixed(1)} Hz',
                  style: const TextStyle(
                    color: Color(0xFFC5A880), // Oro morbido per frequenza target
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Gauge analogico dorato
                FrequencyGauge(centsOffset: _centsOffset),

                const SizedBox(height: 12),

                // Frequenza rilevata
                Text(
                  _detectedFrequency > 0
                      ? '${_detectedFrequency.toStringAsFixed(1)} Hz'
                      : '0.0 Hz',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Status accordatura
                Text(
                  _getTuningStatus(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // Bottone microfono integrato ed elegante (non più floating button che si sovrappone)
                GestureDetector(
                  onTap: () async {
                    if (_audioService.isListening) {
                      await _audioService.stopListening();
                      setState(() {
                        _detectedFrequency = 0;
                        _centsOffset = 0;
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
                      color: _audioService.isListening
                          ? const Color(0xFFE74C3C).withOpacity(0.15)
                          : const Color(0xFFD4AF37).withOpacity(0.1),
                      border: Border.all(
                        color: _audioService.isListening
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFFD4AF37),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _audioService.isListening
                              ? const Color(0xFFE74C3C).withOpacity(0.2)
                              : const Color(0xFFD4AF37).withOpacity(0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _audioService.isListening ? Icons.stop : Icons.mic,
                      size: 26,
                      color: _audioService.isListening
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFFD4AF37),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Selettore corde
                StringSelector(
                  strings: _selectedInstrument.strings,
                  selectedIndex: _selectedStringIndex,
                  onSelected: _onStringSelected,
                ),
                
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstrumentSelector() {
    return GestureDetector(
      onTap: _showInstrumentPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.08),
              blurRadius: 6,
              spreadRadius: 1,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedInstrument.name,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFD4AF37),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showInstrumentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra dorata di drag estetica
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Seleziona Strumento',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              ...defaultInstruments.map((instrument) {
                final isSelected = _selectedInstrument.name == instrument.name;
                return ListTile(
                  title: Text(
                    instrument.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFD4AF37) : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(
                    Icons.music_note,
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white30,
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFFD4AF37))
                      : null,
                  onTap: () {
                    _onInstrumentChanged(instrument);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
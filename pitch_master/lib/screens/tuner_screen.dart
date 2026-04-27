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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: _buildInstrumentSelector(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Nota target
          Text(
            targetNote,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${targetFreq.toStringAsFixed(1)} Hz',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),

          const SizedBox(height: 16),

          // Gauge
          FrequencyGauge(centsOffset: _centsOffset),

          const SizedBox(height: 16),

          // Frequenza rilevata
          Text(
            _detectedFrequency > 0
                ? '${_detectedFrequency.toStringAsFixed(1)} Hz'
                : '0.0 Hz',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Status
          Text(
            _getTuningStatus(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 32),

          // Selettore corde
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StringSelector(
              strings: _selectedInstrument.strings,
              selectedIndex: _selectedStringIndex,
              onSelected: _onStringSelected,
            ),
          ),
        ],
      ),

      // Bottone microfono
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_audioService.isListening) {
              _audioService.stopListening();
              _detectedFrequency = 0;
              _centsOffset = 0;
            } else {
              _audioService.startListening();
            }
          });
        },
        backgroundColor:
            _audioService.isListening ? Colors.redAccent : Colors.blueAccent,
        child: Icon(
          _audioService.isListening ? Icons.stop : Icons.mic,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInstrumentSelector() {
    return GestureDetector(
      onTap: () => _showInstrumentPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedInstrument.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showInstrumentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A3E),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: defaultInstruments.map((instrument) {
            return ListTile(
              title: Text(
                instrument.name,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _selectedInstrument.name == instrument.name
                  ? const Icon(Icons.check, color: Colors.blueAccent)
                  : null,
              onTap: () {
                _onInstrumentChanged(instrument);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}

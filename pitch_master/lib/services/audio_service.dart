import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class AudioService {
  bool _isListening = false;
  Timer? _timer;
  final StreamController<double> _frequencyController =
      StreamController<double>.broadcast();

  Stream<double> get frequencyStream => _frequencyController.stream;
  bool get isListening => _isListening;

  // Frequenza target per simulazione (cambia quando selezioni la corda)
  double _targetFrequency = 110.0;

  void setTargetFrequency(double freq) {
    _targetFrequency = freq;
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    // Simula rilevamento frequenza ogni 100ms
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Genera frequenza vicina al target con piccola variazione
      final variation = (Random().nextDouble() - 0.5) * 30;
      final frequency = _targetFrequency + variation;
      _frequencyController.add(frequency);
    });
  }

  void stopListening() {
    _isListening = false;
    _timer?.cancel();
    _timer = null;
  }

  // Calcola offset in cents tra frequenza rilevata e target
  static double calculateCents(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * (log(detected / target) / log(2));
  }

  void dispose() {
    stopListening();
    _frequencyController.close();
  }
}

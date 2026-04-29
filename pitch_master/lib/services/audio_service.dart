import 'dart:async';
import 'dart:math';

class AudioService {
  bool _isListening = false;
  Timer? _timer;
  final StreamController<double> _frequencyController =
      StreamController<double>.broadcast();

  Stream<double> get frequencyStream => _frequencyController.stream;
  bool get isListening => _isListening;

  double _targetFrequency = 110.0;

  void setTargetFrequency(double freq) {
    _targetFrequency = freq;
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    // Simula rilevamento frequenza ogni 100ms
    // In produzione qui andrebbe il vero input dal microfono
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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

  /// Calcola la differenza in cents tra frequenza rilevata e target.
  /// Formula: 1200 * log2(rilevata / target)
  /// - Risultato negativo = troppo bassa (flat)
  /// - Risultato positivo = troppo alta (sharp)
  static double calculateCents(double detected, double target) {
    if (detected <= 0 || target <= 0) return 0;
    return 1200 * (log(detected / target) / log(2));
  }

  void dispose() {
    stopListening();
    _frequencyController.close();
  }
}
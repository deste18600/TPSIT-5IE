import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  bool _isListening = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<double> _frequencyController =
      StreamController<double>.broadcast();

  StreamController<Uint8List>? _audioController;

  Stream<double> get frequencyStream => _frequencyController.stream;
  bool get isListening => _isListening;

  double _targetFrequency = 110.0;

  void setTargetFrequency(double freq) {
    _targetFrequency = freq;
  }

  Future<void> startListening() async {
    if (_isListening) return;

    // Chiedi permesso microfono
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    await _recorder.openRecorder();

    _audioController = StreamController<Uint8List>();

    List<int> buffer = [];

    // Ascolta i dati audio grezzi
    _audioController!.stream.listen((data) {
      buffer.addAll(data);

      if (buffer.length >= 8192) {
        final samples = buffer.sublist(0, 8192);
        buffer = buffer.sublist(8192);

        final doubles = _pcm16ToDoubles(Uint8List.fromList(samples));
        final frequency = _detectFrequency(doubles);

        if (frequency > 40 && frequency < 1500) {
          _frequencyController.add(frequency);
        }
      }
    });

    // Avvia registrazione
    await _recorder.startRecorder(
      toStream: _audioController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );

    _isListening = true;
  }

  /// Converte dati PCM16 raw in lista di double normalizzati tra -1.0 e 1.0
  List<double> _pcm16ToDoubles(Uint8List bytes) {
    final result = <double>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      int sample = bytes[i] | (bytes[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      result.add(sample / 32768.0);
    }
    return result;
  }

  /// Rileva la frequenza dominante usando autocorrelazione.
  /// Funziona trovando il periodo che si ripete di più nel segnale.
  double _detectFrequency(List<double> samples) {
    const sampleRate = 44100;
    const minFreq = 40;
    const maxFreq = 1500;

    final minLag = (sampleRate / maxFreq).round();
    final maxLag = (sampleRate / minFreq).round();

    double bestCorrelation = -1;
    int bestLag = minLag;

    for (int lag = minLag; lag <= maxLag && lag < samples.length; lag++) {
      double correlation = 0;
      for (int i = 0; i < samples.length - lag; i++) {
        correlation += samples[i] * samples[i + lag];
      }
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestLag = lag;
      }
    }

    return sampleRate / bestLag;
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    await _audioController?.close();
    _audioController = null;
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
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  bool _isListening = false;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  final StreamController<double> _frequencyController = StreamController<double>.broadcast();
  StreamController<Uint8List>? _audioController;

  double _targetFrequency = 110.0;

  Stream<double> get frequencyStream {
    return _frequencyController.stream;
  }

  bool get isListening {
    return _isListening;
  }

  void setTargetFrequency(double freq) {
    _targetFrequency = freq;
  }

  Future<void> startListening() async {
    if (_isListening) {
      return;
    }

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      return;
    }

    await _recorder.openRecorder();
    _audioController = StreamController<Uint8List>();

    List<int> buffer = [];

    _audioController!.stream.listen((incomingBytes) {
      buffer.addAll(incomingBytes);

      if (buffer.length >= 8192) {
        final sampleBytes = buffer.sublist(0, 8192);
        buffer = buffer.sublist(8192);

        final decimalSamples = _convertiPCM16InDecimali(Uint8List.fromList(sampleBytes));
        final detectedFrequency = _calcolaFrequenza(decimalSamples);

        if (detectedFrequency > 40 && detectedFrequency < 1500) {
          _frequencyController.add(detectedFrequency);
        }
      }
    });

    await _recorder.startRecorder(
      toStream: _audioController!.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );

    _isListening = true;
  }

  List<double> _convertiPCM16InDecimali(Uint8List byteData) {
    final result = <double>[];

    for (int i = 0; i < byteData.length - 1; i += 2) {
      int sample = byteData[i] | (byteData[i + 1] << 8);

      if (sample > 32767) {
        sample -= 65536;
      }

      result.add(sample / 32768.0);
    }

    return result;
  }

  double _calcolaFrequenza(List<double> samples) {
    const int sampleRate = 44100;
    const int minFreq = 40;
    const int maxFreq = 1500;

    final int minLag = (sampleRate / maxFreq).round();
    final int maxLag = (sampleRate / minFreq).round();

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
    if (!_isListening) {
      return;
    }

    _isListening = false;

    await _recorder.stopRecorder();
    await _recorder.closeRecorder();

    await _audioController?.close();
    _audioController = null;
  }

  static double calculateCents(double detectedFrequency, double targetFrequency) {
    if (detectedFrequency <= 0 || targetFrequency <= 0) {
      return 0;
    }

    return 1200 * (log(detectedFrequency / targetFrequency) / log(2));
  }

  void dispose() {
    stopListening();
    _frequencyController.close();
  }
}

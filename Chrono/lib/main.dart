import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Chrono(),
    );
  }
}

class Chrono extends StatefulWidget {
  const Chrono({super.key});

  @override
  State<Chrono> createState() => _ChronoState();
}

class _ChronoState extends State<Chrono> {
  late StreamController<int> _secondiController;
  late Stream<int> _secondiStream;

  int _secondiInterni = 0;
  bool _isPaused = false;
  CronoState _cronoState = CronoState.STOP;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _secondiController = StreamController<int>.broadcast();
    _secondiStream = _secondiController.stream;
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _secondiController.close();
    super.dispose();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cronoState == CronoState.START && !_isPaused) {
        _secondiInterni++;
        _secondiController.add(_secondiInterni);
      }
    });
  }

  void _stopTicker() {
    _tickerTimer?.cancel();
  }

  void _resetTicker() {
    _secondiInterni = 0;
    _secondiController.add(0);
  }

  void _toggleCronoState() {
    setState(() {
      switch (_cronoState) {
        case CronoState.START:
          _cronoState = CronoState.STOP;
          _stopTicker();
          break;
        case CronoState.STOP:
          _cronoState = CronoState.RESET;
          _resetTicker();
          break;
        case CronoState.RESET:
          _cronoState = CronoState.START;
          _startTicker();
          break;
      }
    });
  }

  void _togglePauseState() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  // tempo suddiviso in min/Sec
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronometro'),
        centerTitle: true,
      ),
      body: Center(
        child: StreamBuilder<int>(
          stream: _secondiStream,
          builder: (context, snapshot) {
            final secondi = snapshot.data ?? _secondiInterni;
            final tempoFormattato = _formatTime(secondi);
            return Text(
              tempoFormattato,
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "cronoBtn",
            onPressed: _toggleCronoState,
            child: Text(_cronoState.name),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "pauseBtn",
            onPressed: _togglePauseState,
            child: Text(_isPaused ? 'RESUME' : 'PAUSE'),
          ),
        ],
      ),
    );
  }
}

enum CronoState { START, STOP, RESET }
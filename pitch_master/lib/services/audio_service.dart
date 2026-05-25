// ============================================================
// audio_service.dart
// Questo file gestisce tutto quello che riguarda il microfono:
//   1. Chiede il permesso di usarlo
//   2. Accende/spegne la registrazione
//   3. Trasforma l'audio grezzo in numeri
//   4. Calcola la frequenza della nota suonata
//   5. Invia la frequenza trovata al resto dell'app
// ============================================================

import 'dart:async';          // per i "stream" (flussi di dati in tempo reale)
import 'dart:math';           // per la funzione log() usata nel calcolo dei cents
import 'dart:typed_data';     // per Uint8List (array di byte grezzi dell'audio)
import 'package:flutter_sound/flutter_sound.dart';       // libreria per registrare audio
import 'package:permission_handler/permission_handler.dart'; // libreria per chiedere permessi


class AudioService {

  // ── VARIABILI INTERNE ─────────────────────────────────────

  // Dice se il microfono è acceso in questo momento
  bool _isListening = false;

  // L'oggetto che fa davvero la registrazione (viene dalla libreria flutter_sound)
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  // Un "StreamController" è come un tubo: da un lato ci buttano i dati (la frequenza),
  // dall'altro lato chiunque si mette in ascolto li riceve in tempo reale.
  final StreamController<double> _frequencyController = StreamController<double>.broadcast();

  // Questo secondo "tubo" riceve i byte grezzi dell'audio dal microfono
  StreamController<Uint8List>? _audioController;

  // La frequenza della nota che vogliamo raggiungere (es. 110 Hz per La2)
  double _targetFrequency = 110.0;


  // ── PROPRIETÀ PUBBLICHE ───────────────────────────────────
  // Queste due cose possono essere lette dall'esterno (da altri file)
  // ma non possono essere modificate direttamente

  // Lo "stream" a cui altri widget si collegano per ricevere la frequenza rilevata
  Stream<double> get frequencyStream => _frequencyController.stream;

  // Dice se il microfono è acceso (true) o spento (false)
  bool get isListening => _isListening;


  // ── METODO: aggiorna la frequenza target ─────────────────
  // Viene chiamato ogni volta che l'utente cambia corda o strumento
  void setTargetFrequency(double freq) {
    _targetFrequency = freq;
  }


  // ── METODO: accendi il microfono ─────────────────────────
  Future<void> startListening() async {

    // Se il microfono è già acceso, non fare nulla
    if (_isListening) return;

    // Chiedi all'utente il permesso di usare il microfono.
    // Se l'utente dice "No", ci fermiamo subito.
    final permesso = await Permission.microphone.request();
    if (!permesso.isGranted) return;

    // Apri il registratore (lo "prepara" senza ancora registrare)
    await _recorder.openRecorder();

    // Crea il "tubo" che riceverà i byte audio dal microfono
    _audioController = StreamController<Uint8List>();

    // Buffer = lista temporanea dove accumuliamo i byte audio
    // prima di analizzarli. Aspettiamo di averne abbastanza (8192).
    List<int> buffer = [];

    // Ogni volta che arrivano nuovi byte audio, questo codice viene eseguito
    _audioController!.stream.listen((bytesArrivati) {

      // Aggiunge i nuovi byte in coda al buffer
      buffer.addAll(bytesArrivati);

      // Aspetta di avere almeno 8192 byte (circa 0.09 secondi di audio)
      // prima di analizzare la frequenza. Con meno byte l'analisi è imprecisa.
      if (buffer.length >= 8192) {

        // Prende i primi 8192 byte dal buffer per l'analisi
        final campioni8192 = buffer.sublist(0, 8192);

        // Rimuove dal buffer i byte appena presi (li ha già processati)
        buffer = buffer.sublist(8192);

        // Converte i byte in numeri decimali tra -1.0 e 1.0
        final numeriDecimali = _convertiPCM16InDecimali(Uint8List.fromList(campioni8192));

        // Calcola la frequenza dominante in questi campioni
        final frequenzaTrovata = _calcolaFrequenza(numeriDecimali);

        // Invia la frequenza solo se è in un range ragionevole
        // (tra 40 Hz e 1500 Hz, che copre le note degli strumenti comuni)
        if (frequenzaTrovata > 40 && frequenzaTrovata < 1500) {
          _frequencyController.add(frequenzaTrovata);
        }
      }
    });

    // Avvia la registrazione vera e propria.
    // - toStream: manda i dati nel nostro "tubo" _audioController
    // - codec: formato audio "PCM16" = numeri interi grezzi, senza compressione
    // - numChannels: 1 = mono (un solo canale, non stereo)
    // - sampleRate: 44100 campioni al secondo (qualità CD)
    await _recorder.startRecorder(
      toStream:   _audioController!.sink,
      codec:      Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );

    // Aggiorna lo stato: microfono acceso
    _isListening = true;
  }


  // ── METODO PRIVATO: converti byte PCM16 in decimali ──────
  //
  // Il microfono produce "PCM16": ogni campione audio è un numero intero
  // rappresentato con 2 byte (16 bit), con valore da -32768 a +32767.
  //
  // Questo metodo li converte in numeri decimali tra -1.0 e 1.0,
  // che sono più facili da usare nei calcoli matematici successivi.
  //
  // Come funziona per ogni coppia di byte:
  //   byte[0] = parte bassa del numero (bit 0-7)
  //   byte[1] = parte alta del numero  (bit 8-15)
  //   Combinati con | (OR) e << (shift) formano il numero intero a 16 bit.
  //   Se il numero supera 32767, va sottratto 65536 per ottenere il valore negativo.
  //   Dividendo per 32768.0 si normalizza tra -1.0 e +1.0.

  List<double> _convertiPCM16InDecimali(Uint8List byte) {
    final risultato = <double>[];

    // Legge 2 byte alla volta (i += 2)
    for (int i = 0; i < byte.length - 1; i += 2) {

      // Combina i due byte in un intero a 16 bit
      int campione = byte[i] | (byte[i + 1] << 8);

      // Se il valore è oltre 32767, è un numero negativo in PCM16
      if (campione > 32767) {
        campione -= 65536;
      }

      // Normalizza tra -1.0 e +1.0
      risultato.add(campione / 32768.0);
    }

    return risultato;
  }


  // ── METODO PRIVATO: calcola la frequenza con autocorrelazione ──
  //
  // L'AUTOCORRELAZIONE è un metodo matematico per trovare quanto
  // spesso un segnale si ripete (cioè il suo periodo).
  //
  // Idea semplice: se sposto il segnale di X campioni e lo confronto
  // con sé stesso, quando la somiglianza (correlazione) è massima,
  // X è proprio il periodo della nota suonata.
  //
  // Da X campioni → frequenza = 44100 / X
  //
  // Parametri di ricerca:
  //   minLag = campioni minimi per una nota a 1500 Hz (acuto)
  //   maxLag = campioni massimi per una nota a 40 Hz (grave)

  double _calcolaFrequenza(List<double> campioni) {
    const int   frequenzaCampionamento = 44100; // Hz
    const int   freqMinima = 40;    // Hz (note più gravi degli strumenti)
    const int   freqMassima = 1500; // Hz (note più acute degli strumenti)

    // Quanti campioni corrispondono a una nota molto acuta (1500 Hz)?
    final int lagMinimo = (frequenzaCampionamento / freqMassima).round();

    // Quanti campioni corrispondono a una nota molto grave (40 Hz)?
    final int lagMassimo = (frequenzaCampionamento / freqMinima).round();

    double migliorCorrelazione = -1;
    int    migliorLag           = lagMinimo;

    // Prova ogni possibile "ritardo" (lag) e calcola la correlazione
    for (int lag = lagMinimo; lag <= lagMassimo && lag < campioni.length; lag++) {

      double correlazione = 0;

      // Moltiplica ogni campione per quello spostato di "lag" posizioni
      // e somma tutto: se il segnale si ripete ogni "lag" campioni,
      // la somma sarà molto alta
      for (int i = 0; i < campioni.length - lag; i++) {
        correlazione += campioni[i] * campioni[i + lag];
      }

      // Salva il lag che ha dato la correlazione più alta
      if (correlazione > migliorCorrelazione) {
        migliorCorrelazione = correlazione;
        migliorLag           = lag;
      }
    }

    // Calcola la frequenza dal lag migliore trovato
    return frequenzaCampionamento / migliorLag;
  }


  // ── METODO: spegni il microfono ───────────────────────────
  Future<void> stopListening() async {

    // Se il microfono è già spento, non fare nulla
    if (!_isListening) return;

    _isListening = false;

    // Ferma la registrazione e chiude il registratore
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();

    // Chiude il "tubo" dei byte audio
    await _audioController?.close();
    _audioController = null;
  }


  // ── METODO STATICO: calcola i "cents" di scostamento ─────
  //
  // I CENTS sono l'unità di misura per lo scostamento tra note.
  // Un semitono = 100 cents. Mezzo semitono = 50 cents.
  //
  // Formula: 1200 × log₂(frequenzaRilevata / frequenzaTarget)
  //
  // Esempi:
  //   risultato = 0     → nota perfettamente accordata
  //   risultato = -10   → nota troppo bassa (flat) di 10 cents
  //   risultato = +25   → nota troppo alta  (sharp) di 25 cents
  //
  // "static" significa che puoi chiamarlo senza creare un oggetto AudioService:
  //   AudioService.calculateCents(220.0, 216.0)

  static double calculateCents(double frequenzaRilevata, double frequenzaTarget) {

    // Se uno dei due valori è zero o negativo, il calcolo non ha senso
    if (frequenzaRilevata <= 0 || frequenzaTarget <= 0) return 0;

    // log(x) / log(2) equivale a log₂(x)
    return 1200 * (log(frequenzaRilevata / frequenzaTarget) / log(2));
  }


  // ── METODO: libera le risorse quando non serve più ────────
  // Va chiamato quando la schermata dell'accordatore viene chiusa
  void dispose() {
    stopListening();             // spegne il microfono
    _frequencyController.close(); // chiude il "tubo" delle frequenze
  }
}

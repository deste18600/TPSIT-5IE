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

//1. Come nascono i "Sample" Decimali (Il Microfono)Quando pizzichi una corda, questa oscilla su e giù. Il microfono non fa altro che registrare la posizione della corda migliaia di volte al 
//secondo.Questa operazione si chiama "Campionamento" (Sampling). Di solito un microfono scatta 44.100 "fotografie" al secondo (il famoso Sample Rate di 44.1 kHz).Ogni fotografia (Sample) è
// un numero decimale compreso tra -1.0 e +1.0:0.0: La corda è ferma al centro.+1.0: La corda ha raggiunto il punto più alto in assoluto verso l'alto.-1.0: La corda ha raggiunto il punto più 
//basso verso il basso.Se prendiamo i famosi "800 e passa sample" (che in gergo si chiama un Buffer di dati), non stiamo facendo altro che guardare una lista di 800 numeri che descrivono
// un'onda che va su e giù.Esempio di una lista di Sample (l'onda che sale e scende):0.00 (parte dal centro)0.50 (sale)1.00 (picco massimo in alto)0.50 (scende)0.00 (torna al centro)-0.50 
//(scende sotto il centro)-1.00 (picco massimo in basso)-0.50 (risale)0.00 (torna al centro, l'onda è finita e sta per ricominciare!)2. A cosa serve il "Lag"? (La ricerca del Periodo)Il
// computer ha in mano questa lista di 800 decimali, ma è "stupido": non sa che nota sia. Per scoprirlo, deve capire ogni quanti sample l'onda si ripete identica a se stessa.Per farlo, usa un 
//trucco chiamato "Autocorrelazione". Prende la lista di 800 numeri, ne fa una copia mentale, e la fa scivolare in avanti (Lag) di un passo alla volta, confrontandola con l'originale.Il "Lag"
// (dall'inglese, ritardo o scostamento) è semplicemente il numero di posizioni di cui spostiamo la copia.Facciamo scivolare i dati:Immaginiamo di voler confrontare l'onda dell'esempio sopra.
//TENTATIVO 1: Lag = 2 (Spostiamo tutto a destra di 2 posizioni)Originale: 0.0, 0.5, 1.0, 0.5, 0.0...Spostata di 2: ---, ---, 0.0, 0.5, 1.0...Confronto: Al terzo posto l'originale è al picco 
//assimo (1.0), ma la copia è a zero (0.0). I numeri sono lontanissimi. Il computer dice: "No, a Lag 2 l'onda non si ripete".TENTATIVO 2: Lag = 4 (Spostiamo di 4 posizioni)Originale: 0.0, 0.5,
// 1.0, 0.5, 0.0...Spostata di 4: ---, ---, ---, ---, 0.0...Confronto: Qui i numeri iniziano ad assomigliarsi un po' di più, ma l'onda originale sta scendendo verso i numeri negativi, mentre 
//la copia sta per salire verso il +0.5. Ancora non ci siamo.TENTATIVO 3: Lag = 8 (Spostiamo di 8 posizioni)Originale: 0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0...Spostata di 8
//: ---, ---, ---, ---, ---, ---, ---, ---, 0.0, 0.5, 1.0...Confronto: BINGO! I numeri della copia coincidono perfettamente con i numeri originali da quel punto in poi. La differenza tra le d
//ue liste è praticamente zero.Il computer ha trovato il Lag Vincente: Lag = 8.Significa che l'onda ha un "periodo" di 8 sample. Ogni 8 "fotografie", il movimento della corda ricomincia da ca
//po.3. La formula finale: Dal Lag agli HertzOra che il computer sa che il Lag vincente è 8 (cioè ci vogliono 8 fotogrammi per completare un'oscillazione), la conversione in frequenza (Hertz)
// è un semplice calcolo matematico.La formula universale è:$$Frequenza = \frac{Sample Rate}{Lag}$$Riprendiamo i nostri dati:Sample Rate: Il microfono scatta 44.100 foto al secondo.Lag Vincen
//te: Ci vogliono 8 foto per un giro completo.$$Frequenza = \frac{44100}{8} = 5512.5 \text{ Hz}$$Questo è un tono altissimo (l'esempio con 8 sample era per rendere i numeri facili da leggere)
//.Un esempio reale con una Chitarra:Se suoni il La2 (la quinta corda della chitarra, che dovrebbe suonare a 110 Hz), l'onda è molto più lunga. Il computer prenderà i suoi 800 (o più) sample 
//e troverà il punto di incastro perfetto a un Lag di 401.$$Frequenza = \frac{44100}{401} = 109.97 \text{ Hz}$$L'accordatore leggerà 109.97 Hz. Sapendo che il tuo obiettivo è 110 Hz esatti, 
//il programma capirà che ti manca un minuscolo 0.03 e disegnerà l'ago dello schermo quasi perfettamente al centro,
// magari leggermente spostato verso sinistra (dicendoti "Tira appena appena la corda!").

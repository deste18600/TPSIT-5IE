# PitchMaster

**Studente:** Simone D'Este  
**Classe:** 5IE  

---

## Descrizione del progetto

**PitchMaster** è un'applicazione mobile sviluppata in **Flutter** che combina due funzionalità principali destinate ai musicisti: un **accordatore cromatico** e un **archivio spartiti**.

L'accordatore ascolta in tempo reale il suono prodotto dallo strumento tramite il microfono del dispositivo, ne rileva la frequenza e mostra lo scostamento rispetto alla nota target tramite un indicatore.

L'archivio spartiti permette di salvare, visualizzare ed eliminare file PDF o immagini associati ai propri brani, con supporto **offline** garantito da un database SQLite locale che funge da cache.

I dati vengono sincronizzati con un server **REST** basato su `json-server`.

---

## Analisi dei file principali

---

## instrument.dart

Contiene la definizione del modello `Instrument` e i dati degli strumenti predefiniti.

### Instrument

Rappresenta uno strumento musicale con le sue corde.

Contiene:

- `id` – identificatore opzionale
- `name` – nome dello strumento
- `strings` – lista delle note delle corde in ordine dalla più grave alla più acuta
- `isCustom` – indica se lo strumento è stato aggiunto dall'utente

```dart
class Instrument {
  final int? id;
  final String name;
  final List<String> strings;
  final bool isCustom;

  const Instrument({
    this.id,
    required this.name,
    required this.strings,
    this.isCustom = false,
  });
}
```

### defaultInstruments

Lista degli strumenti predefiniti inclusi nell'app.

```dart
const List<Instrument> defaultInstruments = [
  Instrument(name: 'Chitarra', strings: ['Mi2', 'La2', 'Re3', 'Sol3', 'Si3', 'Mi4']),
  Instrument(name: 'Basso',    strings: ['Mi1', 'La1', 'Re2', 'Sol2']),
  Instrument(name: 'Ukulele',  strings: ['Sol4', 'Do4', 'Mi4', 'La4']),
];
```

### noteFrequencies

Mappa che associa ogni nome di nota alla sua frequenza in Hz, usata dall'accordatore per calcolare lo scostamento.

```dart
const Map<String, double> noteFrequencies = {
  'Mi2': 82.41,
  'La2': 110.00,
  // ...
  'La4': 440.00,
};
```

---

## audio_service.dart

Gestisce la cattura audio dal microfono e il rilevamento della frequenza.

Utilizza il package **flutter_sound** per la registrazione in streaming e **permission_handler** per richiedere il permesso al microfono.

### Avvio dell'ascolto

Quando l'utente preme il pulsante microfono viene chiamato `startListening()`, che prima richiede il permesso e poi avvia la registrazione in formato PCM16 grezzo.

```dart
await _recorder.startRecorder(
  toStream: _audioController!.sink,
  codec: Codec.pcm16,
  numChannels: 1,
  sampleRate: 44100,
);
```

I dati audio arrivano in chunks e vengono accumulati in un buffer. Ogni volta che il buffer raggiunge 8192 campioni viene eseguita la rilevazione della frequenza.

### Conversione PCM16

I byte grezzi vengono convertiti in valori `double` normalizzati tra -1.0 e 1.0.

```dart
List<double> _pcm16ToDoubles(Uint8List bytes) {
  for (int i = 0; i < bytes.length - 1; i += 2) {
    int sample = bytes[i] | (bytes[i + 1] << 8);
    if (sample > 32767) sample -= 65536;
    result.add(sample / 32768.0);
  }
}
```

### Rilevamento frequenza – Autocorrelazione

La frequenza dominante viene calcolata tramite **autocorrelazione**: l'algoritmo trova il ritardo (lag) che massimizza la correlazione del segnale con se stesso, che corrisponde al periodo fondamentale.

```dart
for (int lag = minLag; lag <= maxLag; lag++) {
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
```

### Calcolo in cents

Lo scostamento tra la frequenza rilevata e quella target viene espresso in **cents** (centesimi di semitono).

```dart
static double calculateCents(double detected, double target) {
  return 1200 * (log(detected / target) / log(2));
}
```

Un risultato negativo indica che la nota è troppo bassa (flat), positivo che è troppo alta (sharp). La soglia di ±5 cents viene considerata "accordato".

---

## database_helper.dart

Gestisce il database SQLite locale che funge da cache offline per gli spartiti.

Utilizza il package **sqflite**.

### Schema della tabella

```sql
CREATE TABLE spartiti (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  remote_id     TEXT UNIQUE,
  nome_file     TEXT NOT NULL,
  percorso_file TEXT NOT NULL DEFAULT '',
  note          TEXT,
  synced        INTEGER NOT NULL DEFAULT 0,
  sync_pending  INTEGER NOT NULL DEFAULT 0
)
```

Le colonne `synced` e `sync_pending` gestiscono la sincronizzazione con il server:

- `synced = 0` — il record esiste solo in locale, non ancora inviato al server
- `sync_pending = 1` — la richiesta al server è partita ma non ha ancora ricevuto risposta
- `synced = 1` — il record è stato confermato dal server e ha un `remote_id`

### Merge con i dati del server

Il metodo `mergeSpartiti()` sincronizza la cache locale con la lista ricevuta dal server, aggiornando i record esistenti e inserendo i nuovi, senza toccare quelli non ancora sincronizzati.

```dart
static Future<void> mergeSpartiti(List<Map<String, dynamic>> remoteList) async {
  // Raccoglie i nome_file locali non sincronizzati per evitare duplicati
  final unsyncedNames = unsyncedRows
      .map((r) => r['nome_file']?.toString().toLowerCase() ?? '')
      .toSet();

  for (final s in remoteList) {
    // Aggiorna se esiste, inserisce solo se non è già in attesa di sync
  }
}
```

### Gestione duplicati

Il flag `sync_pending` previene la duplicazione dei dati in caso di chiusura imprevista dell'app: prima di ogni chiamata HTTP il record viene marcato come "invio in corso", e rimesso in coda solo se il server non risponde.

```dart
static Future<void> markSyncPending(int localId) async {
  await db.update('spartiti', {'sync_pending': 1},
      where: 'id = ?', whereArgs: [localId]);
}

static Future<void> markSynced(int localId, String remoteId) async {
  await db.update('spartiti',
      {'synced': 1, 'sync_pending': 0, 'remote_id': remoteId},
      where: 'id = ?', whereArgs: [localId]);
}
```

---

## api_service.dart

Gestisce tutte le chiamate HTTP verso il server REST.

Attualmente punta a `json-server` sulla porta 3000. Modificando `baseUrl` si passa al backend PHP senza cambiare nessun altro file.

```dart
static const String baseUrl = 'http://192.168.1.132:3000';
```

### createSpartito

A differenza di un semplice `bool`, restituisce il record completo creato dal server, incluso l'`id` assegnato. Questo permette di salvare il `remote_id` in SQLite e collegare il record locale a quello remoto.

```dart
static Future<Map<String, dynamic>?> createSpartito(
    Map<String, dynamic> spartito) async {
  final response = await http.post(
    Uri.parse('$baseUrl/spartiti'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(spartito),
  );
  if (response.statusCode == 201) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  return null;
}
```

Tutti i metodi hanno un timeout di 5 secondi e restituiscono `null` in caso di errore, permettendo all'app di passare automaticamente alla modalità offline.

---

## spartiti_screen.dart

Gestisce la schermata dell'archivio spartiti con logica **offline-first**.

### Caricamento

Al primo avvio mostra immediatamente i dati dalla cache SQLite, poi contatta il server in background per aggiornare i dati.

```dart
Future<void> _loadSpartiti() async {
  // 1. Mostra subito il locale
  final local = await DatabaseHelper.getAllSpartiti();
  setState(() { _spartiti = local; });

  // 2. Contatta il server
  final remote = await ApiService.getAllSpartiti();
  if (remote == null) return; // offline: la cache è già mostrata

  // 3. Merge e sync dei record in attesa
  await DatabaseHelper.mergeSpartiti(remoteList);
  await _syncUnsynced();
}
```

### Aggiunta di uno spartito

Il salvataggio è immediato: il file viene copiato nella cartella interna dell'app e il record inserito in SQLite con `synced = 0`. Il dialog si chiude subito, senza aspettare il server.

```dart
final localId = await DatabaseHelper.insertSpartito({
  'nome_file':     nome,
  'percorso_file': localPath,
  'note':          note,
  'synced':        0,
});
Navigator.pop(context); // chiude subito

// Invia al server in background
_pushToServer(localId: localId, ...);
```

### File non disponibile

Se un file non è più presente sul dispositivo, invece di mostrare un errore generico viene mostrato un dialog informativo che spiega la situazione e permette di ricaricare il file tramite il pulsante di modifica.

---

## tuner_screen.dart

Gestisce l'interfaccia dell'accordatore.

### Selezione strumento e corda

Lo strumento viene selezionato tramite un `BottomSheet`. Cambiando strumento o corda viene aggiornata la frequenza target nell'`AudioService`.

```dart
void _onInstrumentChanged(Instrument instrument) {
  setState(() {
    _selectedInstrument = instrument;
    _selectedStringIndex = 0;
  });
  _audioService.setTargetFrequency(_getTargetFrequency());
}
```

### Stato dell'accordatura

Lo stato viene determinato in base allo scostamento in cents:

```dart
String _getTuningStatus() {
  if (_detectedFrequency == 0) return 'Inizia a suonare';
  if (_centsOffset.abs() <= 5)  return 'Accordato! ✓';
  if (_centsOffset < 0)         return 'Accordare più in alto';
  return 'Accordare più in basso';
}
```

---

## frequency_gauge.dart

Rappresenta graficamente lo scostamento in cents tramite un gauge semicircolare disegnato con `CustomPainter`.

Il colore dell'ago cambia dinamicamente in base alla precisione:

- **Verde smeraldo** — scostamento ≤ 5 cents (accordato)
- **Oro brillante** — scostamento ≤ 20 cents (vicino)
- **Oro metallico** — scostamento > 20 cents (lontano)

```dart
Color _getColor() {
  if (centsOffset.abs() <= 5)  return const Color(0xFF2ECC71);
  if (centsOffset.abs() <= 20) return const Color(0xFFF1C40F);
  return const Color(0xFFD4AF37);
}
```

---

## string_selector.dart

Mostra i pulsanti delle corde disposti simmetricamente ai lati di una rappresentazione grafica della tastiera.

I pulsanti a indice pari vengono posizionati a sinistra, quelli a indice dispari a destra, adattandosi automaticamente al numero di corde di qualsiasi strumento.

```dart
for (int i = 0; i < strings.length; i++) {
  if (i % 2 == 0) leftStrings.add(i);
  else            rightStrings.add(i);
}
```

---

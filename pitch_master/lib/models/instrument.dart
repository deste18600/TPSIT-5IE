// ============================================================
// instrument.dart
// Questo file descrive cos'è uno "strumento musicale" per l'app.
// Contiene anche la lista degli strumenti già pronti da usare
// e una tabella che dice: "questa nota suona a X Hz".
// ============================================================


// ── CLASSE INSTRUMENT ────────────────────────────────────────
// Una "classe" è come uno stampo: serve a creare oggetti.
// Qui lo stampo si chiama Instrument (strumento musicale).
// Ogni strumento ha queste informazioni:
//   - id:       un numero identificativo (può anche non esserci)
//   - name:     il nome dello strumento, es. "Chitarra"
//   - strings:  la lista delle note delle corde, dalla più grave alla più acuta
//   - isCustom: true se lo strumento è stato aggiunto dall'utente, false se è predefinito

class Instrument {
  final int?    id;       // Può essere null (il punto interrogativo significa "opzionale")
  final String  name;
  final List<String> strings;
  final bool    isCustom;

  // Questo è il "costruttore": viene chiamato quando crei un nuovo Instrument.
  // Le parentesi graffe { } rendono i parametri facoltativi (tranne quelli con "required").
  const Instrument({
    this.id,                  // facoltativo: se non lo passi vale null
    required this.name,       // obbligatorio
    required this.strings,    // obbligatorio
    this.isCustom = false,    // facoltativo: se non lo passi vale false
  });
}


// ── STRUMENTI PREDEFINITI ─────────────────────────────────────
// Questa è una lista costante (non cambia mai) degli strumenti
// già inclusi nell'app. Ogni elemento è un oggetto Instrument
// creato con lo stampo qui sopra.

const List<Instrument> defaultInstruments = [

  // Chitarra standard: 6 corde, dalla più grave (Mi2) alla più acuta (Mi4)
  Instrument(
    name: 'Chitarra',
    strings: ['Mi2', 'La2', 'Re3', 'Sol3', 'Si3', 'Mi4'],
  ),

  // Basso: 4 corde, tutte più gravi della chitarra
  Instrument(
    name: 'Basso',
    strings: ['Mi1', 'La1', 'Re2', 'Sol2'],
  ),

  // Ukulele: 4 corde con accordatura particolare (Sol4 è più acuta di Do4)
  Instrument(
    name: 'Ukulele',
    strings: ['Sol4', 'Do4', 'Mi4', 'La4'],
  ),

];


// ── TABELLA FREQUENZE ─────────────────────────────────────────
// Ogni nota musicale corrisponde a una frequenza specifica in Hz (Hertz).
// Questa mappa (= dizionario) associa il nome della nota alla sua frequenza.
// Esempio: 'La4' -> 440.00 Hz è il "La" di riferimento universale.
//
// L'accordatore la usa così:
//   1. L'utente seleziona la corda "La2"
//   2. L'app legge da qui che La2 = 110.00 Hz
//   3. Il microfono ascolta la nota suonata e ne misura la frequenza
//   4. L'app confronta le due frequenze e dice se è accordato

const Map<String, double> noteFrequencies = {
  // ── NOTE DEL BASSO ───
  'Mi1':  41.20,   // corda più grave del basso
  'La1':  55.00,
  'Re2':  73.42,
  'Sol2': 98.00,

  // ── NOTE DELLA CHITARRA ───
  'Mi2':  82.40,   // corda più grave della chitarra (6a corda)
  'La2':  110.00,  // 5a corda
  'Re3':  146.83,  // 4a corda
  'Sol3': 196.00,  // 3a corda
  'Si3':  246.94,  // 2a corda
  'Mi4':  329.63,  // 1a corda (la più acuta)

  // ── NOTE DELL'UKULELE ───
  'Sol4': 392.00,
  'Do4':  261.63,
  'La4':  440.00,  // il "La" di riferimento (concerto)
};

# PitchMaster

**Studente:** Simone D'Este  
**Classe:** 5IE

---

## Descrizione del progetto

PitchMaster è un'applicazione mobile sviluppata in Flutter dedicata ai musicisti. L'architettura dell'app si divide in due funzionalità principali, accessibili tramite una barra di navigazione inferiore (Navbar):

- **Pagina Accordatore:** Un accordatore cromatico in tempo reale che ascolta il suono prodotto dallo strumento tramite il microfono e mostra visivamente lo scostamento dalla nota target.
- **Pagina Spartiti:** Un archivio offline-first per salvare, visualizzare e gestire i propri file PDF o immagini musicali, con sincronizzazione in background verso un server.

---

## Navigazione Principale (Bottom Navbar)

La navigazione tra le due sezioni dell'app avviene tramite una barra inferiore. Questa gestisce lo stato principale dell'interfaccia:

- **Tasto Accordatore (Sinistra):** Mostra la schermata `TunerScreen` e inizializza i servizi audio.
- **Tasto Spartiti (Destra):** Mostra la schermata `SpartitiScreen`, attivando la lettura dal database locale e la verifica della connessione col server.

---

## 1. Pagina Accordatore (`tuner_screen.dart`)

Questa schermata è il cuore interattivo dell'app. L'interfaccia è costruita per essere reattiva e chiara durante l'uso pratico dello strumento.

### Il pulsante del microfono

L'attivazione del microfono è gestita da un `GestureDetector` che avvolge un `AnimatedContainer`.

- Quando l'ascolto è **spento**, il pulsante appare con i colori standard (oro e grigio scuro) e l'icona del microfono.
- Quando l'ascolto è **attivo**, il contenitore si anima in rosso (`#E74C3C`) con l'icona di stop, fornendo un feedback visivo immediato.

La pressione invoca i metodi di avvio/stop presenti nell'`AudioService`.

### Selettore delle Corde (`string_selector.dart`)

Questo widget permette di selezionare quale corda accordare.

- **Struttura:** Non avendo uno stato interno (`StatelessWidget`), riceve semplicemente l'indice della corda attiva e la lista delle note.
- **Layout:** Utilizza una `Row` centrale che contiene due `Column` affiancate. La logica divide dinamicamente l'array delle corde: gli indici pari finiscono nella colonna di sinistra, quelli dispari nella colonna di destra, creando una disposizione ergonomica.
- I pulsanti cambiano ombreggiatura (`BoxShadow`) e colore del bordo quando selezionati.

### Il Quadrante dell'Accordatore (`frequency_gauge.dart`)

La lancetta e il semicerchio graduato sono disegnati da zero utilizzando il sistema `CustomPainter` di Flutter, che permette prestazioni elevatissime agendo direttamente sul `Canvas`.

- **Funzionamento:** Riceve il valore di `centsOffset` (lo scostamento in centesimi di semitono).
- **Calcolo della Lancetta:** Mappa il valore `[-100, +100]` in angoli radianti `[π, 2π]`. Usa funzioni trigonometriche (`cos` e `sin`) per calcolare la punta dell'ago e la sua ombra sfocata per un effetto 3D.
- **Colori dinamici:** Il colore dell'ago e del perno centrale cambia in tempo reale:
  - 🟢 **Verde (`#2ECC71`):** Perfettamente accordato (entro ±5 cents).
  - 🟡 **Giallo (`#F1C40F`):** Vicino (entro ±20 cents).
  - 🟠 **Oro (`#D4AF37`):** Troppo distante.

### I due Stream e il Calcolo della Frequenza (`audio_service.dart`)

La logica audio è divisa in due flussi (Stream) per non bloccare l'interfaccia grafica:

1. **Il primo Stream (Grezzo):** Usa la libreria `flutter_sound` per catturare i byte PCM16 dal microfono e li accumula in un buffer privato (`_audioController`).
2. **Il calcolo (Autocorrelazione):** Raggiunti gli 8192 campioni, i byte vengono convertiti in decimali. L'algoritmo di autocorrelazione cerca pattern ripetitivi nell'onda sonora, confrontando il segnale con se stesso spostato nel tempo (lag) per trovare il periodo e, di conseguenza, la frequenza espressa in Hertz.
3. **Il secondo Stream (Raffinato):** Una volta calcolata la frequenza in Hz, il numero pulito viene inserito nel `_frequencyController`, a cui l'interfaccia grafica si "abbona" per muovere la lancetta, mantenendo la UI fluida a 60 fps. Il calcolo in "cents" definisce infine di quanto la nota è calante (flat) o crescente (sharp).

---

## 2. Pagina Spartiti (`spartiti_screen.dart`)

L'archivio è costruito seguendo un'architettura **offline-first**: l'utente non deve mai aspettare i tempi di rete per visualizzare i propri file.

### Widget utilizzati

La struttura principale è gestita da uno `Scaffold`.

- La lista degli spartiti utilizza un `ListView.builder` avvolto in un `RefreshIndicator` per permettere l'aggiornamento manuale tirando verso il basso.
- Ogni spartito è disegnato usando una `Card` contenente un `ListTile` con iconografia condizionale (es. nuvola con spunta verde se sincronizzato, icona smartphone se solo locale).
- L'aggiunta e la modifica avvengono tramite modali (`AlertDialog` con `StatefulBuilder`) richiamati da un `FloatingActionButton`. I form usano widget nativi come `TextField` e `OutlinedButton.icon` per agganciare il file system (`file_picker`).

### Database SQLite Locale (`database_helper.dart`)

Il pacchetto `sqflite` gestisce i dati sul telefono attraverso due tabelle:

- **`strumenti`:** Salva il nome e le corde di ogni strumento (es. `"Mi2,La2,Re3..."`). La colonna `attivo` indica quale strumento è in uso, permettendo di cambiarlo con una singola istruzione `UPDATE`.
- **`spartiti`:** Salva il riferimento al file e i metadati. Include flag vitali per la sincronizzazione:
  - `synced = 0`: Elemento creato offline, da inviare.
  - `sync_pending = 1`: Evita che lo stesso file venga caricato due volte in caso di connessione instabile.
  - `remote_id`: L'ID univoco assegnato dal server una volta salvato con successo.

### Sincronizzazione API (`api_service.dart`)

Il ponte tra l'app e il server remoto (basato su `json-server`).

- Usa il pacchetto `http` per inviare richieste REST (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`).
- Tutte le chiamate traducono i dati Dart in JSON (`jsonEncode`) e viceversa (`jsonDecode`).
- Implementa un **timeout di 5 secondi**: se il server non risponde in tempo, l'`ApiService` restituisce `null`. La logica dell'app "cattura" questo risultato, mantiene `_eOnline = false`, e continua a operare perfettamente leggendo i file PDF copiati nella cartella locale dei documenti, ritentando la sincronizzazione silente in background in un secondo momento.

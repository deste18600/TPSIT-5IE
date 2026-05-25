# PitchMaster

**Studente:** Simone D'Este  
**Classe:** 5IE

---

## Descrizione del progetto

PitchMaster è un'app mobile fatta in Flutter pensata per i musicisti. L'idea di base è semplice: avere in un'unica app sia un accordatore che funziona col microfono, sia un posto dove tenere tutti i propri spartiti. Si passa da una sezione all'altra con una barra di navigazione in basso.

---

## Navigazione principale (Bottom Navbar)

La barra in basso è il punto di accesso alle due schermate:

- **Tasto Accordatore (sinistra):** apre la `TunerScreen` e avvia i servizi audio.
- **Tasto Spartiti (destra):** apre la `SpartitiScreen`, che legge dal database locale e controlla se il server è raggiungibile.

---

## 1. Pagina Accordatore (`tuner_screen.dart`)

### Il pulsante del microfono

È un `AnimatedContainer` dentro un `GestureDetector`. Quando il microfono è spento è grigio scuro con l'icona del microfono, quando è attivo diventa rosso (`#E74C3C`) con l'icona di stop — così non ci si dimentica che sta ascoltando.

### Selettore delle corde (`string_selector.dart`)

Permette di scegliere quale corda si vuole accordare. È uno `StatelessWidget` perché non gestisce stato suo, riceve solo l'indice della corda attiva. Le corde vengono divise in due colonne affiancate (pari a sinistra, dispari a destra) per stare comode sullo schermo. Il pulsante selezionato cambia colore del bordo e ombra.

### Il quadrante (`frequency_gauge.dart`)

Questa è la parte che mi ha dato più soddisfazione. La lancetta e il semicerchio sono disegnati da zero con `CustomPainter`, quindi tutto gira direttamente sul `Canvas` di Flutter senza widget intermedi. Riceve il valore di `centsOffset` (quanto sei distante dalla nota), lo mappa tra `[-100, +100]` e lo converte in angoli con `cos` e `sin`. Il colore cambia in tempo reale:

-  **Verde:** accordato (entro ±5 cents)
-  **Giallo:** quasi (entro ±20 cents)
-  **Oro:** troppo distante

### Come funziona il calcolo audio (`audio_service.dart`)

La logica è divisa in due Stream per non bloccare l'interfaccia:

1. **Stream grezzo:** `flutter_sound` cattura i byte PCM16 dal microfono e li accumula in un buffer interno.
2. **Calcolo:** Quando si raggiungono 8192 campioni scatta l'autocorrelazione — in pratica si confronta il segnale audio con una copia di sé stesso spostata nel tempo, così si trova il periodo dell'onda e quindi la frequenza in Hz.
3. **Stream pulito:** La frequenza calcolata va nel `_frequencyController`, a cui la UI si abbona per muovere la lancetta. Così l'interfaccia rimane fluida a 60fps anche mentre il calcolo sta girando. Alla fine si converte tutto in cents per sapere se la nota è calante o crescente.

---

## 2. Pagina Spartiti (`spartiti_screen.dart`)

L'idea era che l'app funzionasse anche senza connessione, quindi ho costruito tutto con una logica **offline-first**: si legge sempre prima dal database locale, e il server è un extra.

### Struttura dell'interfaccia

- La lista usa un `ListView.builder` dentro un `RefreshIndicator` (il gesto "tira giù per aggiornare").
- Ogni spartito è una `Card` con un `ListTile`. L'icona cambia a seconda dello stato di sincronizzazione: nuvola verde se è già sul server, icona smartphone se è solo in locale.
- Per aggiungere o modificare uno spartito si apre un `AlertDialog` con `StatefulBuilder`. I form usano `TextField` e `OutlinedButton.icon`, e per scegliere il file si usa `file_picker`.

### Database locale (`database_helper.dart`)

Uso `sqflite` con due tabelle:

- **`strumenti`:** Nome e corde dello strumento (es. `"Mi2,La2,Re3..."`). La colonna `attivo` tiene traccia di quale strumento è selezionato, e per cambiarlo basta una `UPDATE`.
- **`spartiti`:** Percorso del file e metadati. I flag più importanti sono:
  - `synced = 0` → creato offline, ancora da mandare al server
  - `sync_pending = 1` → evita di caricarlo due volte se la connessione cade a metà
  - `remote_id` → l'ID che assegna il server una volta salvato con successo

### Sincronizzazione con il server (`api_service.dart`)

Il backend gira su `json-server`. L'`ApiService` fa chiamate REST (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`) con il pacchetto `http`, convertendo tutto da e verso JSON.

Ho messo un **timeout di 5 secondi**: se il server non risponde, il servizio restituisce `null`, l'app imposta `_eOnline = false` e continua a lavorare normalmente coi file locali. La sincronizzazione viene ritentata in background quando torna la connessione.
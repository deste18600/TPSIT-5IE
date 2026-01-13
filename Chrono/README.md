# Progetto Cronometro Flutter

## Descrizione

Questo progetto è un **cronometro** sviluppato in Flutter che permette di misurare il tempo in minuti e secondi.  
Include funzionalità di **start**, **stop/reset** e **pausa**, con aggiornamento in tempo reale della UI tramite `StreamBuilder`.

---

## Struttura del progetto

- **MyApp (StatelessWidget)**  
  - Punto di ingresso dell'app Flutter.  
  - Avvia la schermata principale `Chrono`.  

- **Chrono (StatefulWidget)**  
  - Gestisce lo stato del cronometro e l'interazione dell'utente.  
  - Contiene timer, stato corrente del cronometro e gestione della pausa.  

- **StreamController<int>**  
  - Controlla lo stream dei secondi trascorsi.  
  - Permette aggiornamenti in tempo reale della UI tramite `StreamBuilder`.

- **Timer.periodic**  
  - Aggiorna i secondi interni ogni secondo quando il cronometro è in stato `START`.  

---

## Funzionamento

1. **Avvio dell'app**: viene visualizzato il cronometro a 00:00.  
2. **Start / Stop / Reset**:  
   - Premendo il bottone principale, il cronometro passa tra stati `START`, `STOP` e `RESET`.  
   - `START` avvia il timer.  
   - `STOP` ferma il timer senza resettare i secondi.  
   - `RESET` azzera il tempo visualizzato.  

3. **Pausa / Resume**:  
   - Premendo il bottone di pausa, il timer si interrompe senza cambiare lo stato principale.  
   - Premendo nuovamente riprende il conteggio.  

4. **Visualizzazione tempo**:  
   - I secondi interni vengono convertiti in minuti e secondi tramite `_formatTime()`.  
   - La UI si aggiorna in tempo reale grazie a `StreamBuilder<int>`.

---

## Metodi e funzionalità principali

### Cronometro

- **_startTicker()**: avvia il `Timer.periodic` che incrementa `_secondiInterni` ogni secondo se `_cronoState == START` e `_isPaused == false`.  
- **_stopTicker()**: cancella il timer.  
- **_resetTicker()**: azzera i secondi e aggiorna lo stream a 0.  
- **_toggleCronoState()**: cambia lo stato del cronometro tra `START`, `STOP` e `RESET` e richiama il metodo corrispondente.  
- **_togglePauseState()**: alterna lo stato di pausa `_isPaused`.  
- **_formatTime(int totalSeconds)**: converte il tempo in minuti e secondi formattati `MM:SS`.  

### Stream e UI

- **StreamController<int> _secondiController**: gestisce lo stream dei secondi interni.  
- **Stream<int> _secondiStream**: stream broadcast per aggiornare la UI in tempo reale.  
- **StreamBuilder<int>**: widget che ascolta `_secondiStream` e aggiorna il `Text` con il tempo formattato.  
- **FloatingActionButton**: permette di interagire con i comandi Start/Stop/Reset e Pausa/Resume.  

### Stato del cronometro

```dart
enum CronoState { START, STOP, RESET }

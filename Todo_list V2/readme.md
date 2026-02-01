# Progetto zKeep

**Studente:** Simone D'Este  
**Classe:** 5IE  

## Descrizione del progetto
zKeep è un'applicazione sviluppata in **Flutter**, ispirata a Google Keep.  
L'app consente di gestire una bacheca di note dinamiche, dove ogni nota è rappresentata da una **Card** contenente una lista di attività (**Todo**).

---

## Funzionalità principali
- Creazione di nuove note (Card)
- Gestione dei Todo (aggiunta, modifica, completamento, eliminazione)
- Modifica del testo direttamente dalla schermata principale (*inline editing*)
- Aggiornamento automatico dell'interfaccia
- gestire una lista di Todo per ogni Card

---

## Modello Dati (Model)
Il modello dati è definito nel file `lib/model.dart`.

gli elementi principali sono:
- **TodoLine**: rappresenta una singola attività, composta da testo e stato di completamento
- **TodoCard**: rappresenta una nota, contenente una lista di TodoLine

---

## Logica di Stato (ViewModel)
La gestione dello stato è affidata alla classe `TodoBoardNotifier`, definita nel file `lib/todo_board_notifier.dart`.

Il notifier si occupa di:
- creare nuove Card
- modificare e aggiornare i Todo
- notificare automaticamente la UI tramite `notifyListeners()`

Sono implementate le principali operazioni (Create, Read, Update, Delete).

---

## Interfaccia Utente (View)
L'interfaccia grafica è sviluppata nel file `main.dart`.

Caratteristiche principali:
- utilizzo di **Card** per rappresentare le note
- presenza di un **FloatingActionButton** per aggiungere nuove Card
- utilizzo di campi di testo modificabili direttamente (*inline editing*)
- interazione semplice e immediata per l'utente

---

## Gestione dello stato nella UI
Per ottimizzare le prestazioni:
- `context.watch` viene utilizzato per i widget che devono aggiornarsi al variare dei dati
- `context.read` viene utilizzato per richiamare metodi senza ricostruire inutilmente l'interfaccia

Questa scelta migliora l'efficienza generale dell'applicazione.

---

## Valutazione finale

### Pulizia del codice
Il progetto è organizzato in file separati, ognuno con una responsabilità ben definita.

### Usabilità
L'interfaccia è intuitiva e permette una gestione completa delle note senza cambiare schermata.

### Efficienza
La gestione reattiva dello stato consente un aggiornamento fluido e immediato dell'interfaccia.

---

## Conclusione
Il progetto zKeep dimostra l'utilizzo corretto di Flutter e del pattern MVVM per la realizzazione di un'applicazione funzionale, ordinata e facilmente estendibile.


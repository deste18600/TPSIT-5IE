# Progetto zKeep – Database Version

**Studente:** Simone D’Este  
**Classe:** 5IE  

---

# Descrizione del progetto

**zKeep** è un’applicazione sviluppata in **Flutter**, ispirata a Google Keep.

Permette di gestire una bacheca di **note organizzate in Card**, dove ogni card può contenere:

- un **titolo**
- una lista di **righe Todo**
- checkbox per segnare le attività completate

I dati vengono salvati tramite **SQLite**, in modo che le note rimangano anche dopo la chiusura dell'app.

L’interfaccia utilizza una griglia simile a quella di Google Keep grazie al pacchetto **flutter_staggered_grid_view** che contiene il widget MasonryGridVIew.

---

# Analisi dei file principali

---

# model.dart: 

Sono presenti due classi principali:

- `TodoLine`
- `TodoCard`

### TodoLine

Rappresenta una singola riga della lista.

Contiene:

- `id` - identificatore della riga nel database  
- `cardId` - riferimento alla card a cui appartiene  
- `text` - testo della riga  
- `checked` - indica se la riga è completata  

Il metodo `toMap()` converte l’oggetto Dart in una mappa compatibile con SQLite

```dart
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'card_id': cardId,
    'text': text,
    'checked': checked ? 1 : 0,
  };
}
```

### TodoCard

Rappresenta una nota completa.

Ogni card contiene:

- `id`
- `title`
- una lista di `TodoLine`

```dart
class TodoCard {
  int? id;
  String title;
  List<TodoLine> lines;

  TodoCard({this.id, this.title = "", required this.lines});
}
```

---

# helper.dart – Gestione database

Questo file gestisce  la comunicazione con SQLite.

Utilizza il package **sqflite** per creare e gestire il database locale.

Il database viene salvato nel percorso fornito tramite:

```dart
String path = join(await getDatabasesPath(), 'zkeep.db');
```

---

## Creazione delle tabelle

Alla prima apertura dell'app viene usato `onCreate`, che crea le due tabelle principali.

### Tabella cards

Contiene le informazioni principali delle note.

```sql
CREATE TABLE cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT
)
```

### Tabella lines

Contiene le righe associate alle card.

```sql
CREATE TABLE lines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  card_id INTEGER,
  text TEXT,
  checked INTEGER,
  FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
)
```

La **Foreign Key con `ON DELETE CASCADE`** permette di eliminare automaticamente tutte le righe quando una card viene cancellata.

---

## Recupero delle card dal database

Il metodo `getCards()` legge tutte le card dal database e ricostruisce gli oggetti Dart.

Prima recupera le card:

```dart
final List<Map<String, Object?>> cardMaps =
    await db.query('cards', orderBy: 'id DESC');
```

Poi per ogni card recupera le righe associate.

```dart
final lineMaps = await db.query(
  'lines',
  where: 'card_id = ?',
  whereArgs: [cardId],
);
```

Infine i dati SQL vengono trasformati in **oggetti Dart**.

---

## Metodi di interazione con il database

### insertCard

Crea una nuova card.

```dart
static Future<int> insertCard() async {
  final db = await getDatabase();
  return await db.insert('cards', {'title': ''});
}
```

### deleteCard

Elimina una card.

```dart
static Future<void> deleteCard(int id) async {
  final db = await getDatabase();
  await db.delete('cards', where: 'id = ?', whereArgs: [id]);
}
```

### insertLine

Inserisce una nuova riga nella lista.

```dart
static Future<int> insertLine(TodoLine line) async {
  final db = await getDatabase();
  return await db.insert('lines', line.toMap());
}
```

### updateLine

Aggiorna una riga esistente.

```dart
static Future<void> updateLine(TodoLine line) async {
  final db = await getDatabase();
  await db.update(
    'lines',
    line.toMap(),
    where: 'id = ?',
    whereArgs: [line.id],
  );
}
```

### deleteLine

Elimina una riga specifica.

```dart
static Future<void> deleteLine(int id) async {
  final db = await getDatabase();
  await db.delete('lines', where: 'id = ?', whereArgs: [id]);
}
```

---

# notifier.dart – Logica di stato

Questo file gestisce **lo stato dell'applicazione**.

Utilizza la classe `ChangeNotifier`, che permette di notificare l’interfaccia grafica quando i dati cambiano.

```dart
class TodoBoardNotifier with ChangeNotifier {
```

La lista delle card viene salvata in:

```dart
List<TodoCard> _cards = [];
```

Per evitare modifiche dirette dall’esterno viene utilizzato un **getter pubblico**.

```dart
List<TodoCard> get cards => _cards;
```

---

## Caricamento dei dati

All’avvio dell’app le card vengono recuperate dal database.

```dart
Future<void> loadData() async {
  _cards = await DatabaseHelper.getCards();
  notifyListeners();
}
```

---

## Creazione di una nuova card

Quando l’utente preme il pulsante **Nuova**, viene creata una nuova card.

```dart
Future<void> addCard() async {
  int id = await DatabaseHelper.insertCard();
  _cards.insert(0, TodoCard(id: id, lines: []));
  notifyListeners();
}
```

---

## Aggiornamento del titolo

Permette di modificare il titolo della nota.

```dart
Future<void> updateTitle(TodoCard card, String title) async {
  card.title = title;
  await DatabaseHelper.updateCardTitle(card.id!, title);
  notifyListeners();
}
```

---

## Aggiungere una riga

```dart
Future<void> addLine(TodoCard card) async {
  TodoLine line = TodoLine(cardId: card.id, text: "");
  line.id = await DatabaseHelper.insertLine(line);
  card.lines.add(line);
  notifyListeners();
}
```

---

## Cambiare lo stato della checkbox

```dart
Future<void> toggleLine(TodoLine line) async {
  line.checked = !line.checked;
  await DatabaseHelper.updateLine(line);
  notifyListeners();
}
```

---

## Eliminare una riga

```dart
Future<void> deleteLine(TodoCard card, TodoLine line) async {
  card.lines.remove(line);
  if (line.id != null) await DatabaseHelper.deleteLine(line.id!);
  notifyListeners();
}
```

---

## Eliminare una card

```dart
Future<void> deleteCard(TodoCard card) async {
  if (card.id != null) {
    await DatabaseHelper.deleteCard(card.id!);
    _cards.remove(card);
    notifyListeners();
  }
}
```

---

# widgets.dart – Componenti grafici

Questo file definisce **l'interfaccia grafica delle note**.

## TodoCardWidget

Rappresenta una card nella schermata principale.

Mostra il titolo e un’anteprima delle righe della nota.

Quando l’utente tocca la card viene aperta la schermata di modifica tramite il widget Navigator.

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return EditNoteScreen(card: card);
    },
  ),
);
```

---

## EditNoteScreen

Questa schermata permette di **modificare completamente la nota**.

L’utente può:

- modificare il titolo
- aggiungere nuove righe
- spuntare le checkbox
- eliminare righe
- cancellare la card

Le righe vengono generate tramite l’operatore **spread (`...`)**.

```dart

...card.lines.map((line)) {

```

I campi di testo usano `TextFormField` con `initialValue` per evitare che il cursore salti durante la scrittura:

```dart
TextFormField(
  initialValue: line.text,
  decoration: const InputDecoration(border: InputBorder.none),
  onChanged: (nuovoTesto) {
    notifier.updateLine(line, nuovoTesto);
  },
)

---
# main.dart – Punto d’ingresso e TodoBoardPage

Contiene il **punto d’accesso principale** dell’app (`main()`) e definisce la struttura generale dell’interfaccia con **MaterialApp** e **TodoBoardPage**.  

Questa pagina mostra tutte le card dell’utente in una **MasonryGridView**.  
Se non ci sono card, mostra un messaggio di invito a crearne una.  

Il **FloatingActionButton** è stato aggiornato in modo semplice:

- Premendo “Nuova”, si crea subito una nuova card  
- La card appena creata viene selezionata come **prima della lista**  
- Si apre subito **EditNoteScreen** per modificarla

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final notifier = TodoBoardNotifier();
        notifier.loadData(); // carica le card dal database all'avvio
        return notifier;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.black,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const TodoBoardPage(),
      ),
    );
  }
}

class TodoBoardPage extends StatelessWidget {
  const TodoBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<TodoBoardNotifier>().cards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("zKeep"),
        centerTitle: true,
      ),

      body: cards.isEmpty
          ? const Center(
              child: Text("Crea la tua prima nota!"),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return TodoCardWidget(card: cards[index]);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final notifier = context.read<TodoBoardNotifier>();

          // crea la nuova card
          notifier.addCard();

          // prendi subito la prima card (la più recente)
          final newCard = notifier.cards.first;

          // apri la schermata di modifica
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditNoteScreen(card: newCard),
            ),
          );
        },
        label: const Text("Nuova"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
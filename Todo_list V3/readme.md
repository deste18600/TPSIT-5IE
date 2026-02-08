# Progetto zKeep – Database Version

**Studente:** Simone D’Este  
**Classe:** 5IE  

## Descrizione del progetto

**zKeep** è un’applicazione sviluppata in **Flutter**, ispirata a Google Keep.  
Consente di gestire una bacheca di note dinamiche organizzate in **Card** con persistenza dei dati tramite **SQLite**.

---

## Analisi dei file principali

### model.dart – Modello dati

Definisce la struttura delle righe Todo.  
Il metodo `toMap()` converte l’oggetto Dart in una mappa compatibile con SQLite, trasformando i booleani in interi.
successivamente la classe todoCard definisce un id univoco e la lista contenente gli oggetti associati

```dart
Map<String, dynamic> toMap() => {
  'id': id,
  'card_id': cardId,
  'text': text,
  'checked': checked ? 1 : 0,
};

class TodoCard {
  int? id;               
  List<TodoLine> lines;  

  TodoCard({this.id, required this.lines});
}
```
---

### helper.dart – Gestione database
Gestisce l’inizializzazione del database e la creazione delle tabelle.  
È presente una **Foreign Key** con `ON DELETE CASCADE` per mantenere l’integrità dei dati.

la classe databaseHelper accede al database grazie a questo metodo:

```dart
  static Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }
```

successivamente chiede al sistema operativo il percorso dove salvare i propri dati e file
inoltre se è la prima volta che apro il file usa il metodo oncreate per creare le tabelle
```dart
 static Future<Database> _init() async {
 String path = join(await getDatabasesPath(), 'zkeep.db');
return await openDatabase(path, version: 1, onCreate: (db, version) async {
  await db.execute('CREATE TABLE cards (id INTEGER PRIMARY KEY AUTOINCREMENT)');

```

```dart
await db.execute('''
  CREATE TABLE lines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    card_id INTEGER,
    text TEXT,
    checked INTEGER,
    FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
  )
''');
```

helper contiene anche i metodo getCards che aggiorna chiede tutte le card del database e tramite una mappa trasforma i dati sql in oggetti dart

```dart
  static Future<List<TodoCard>> getCards() async {
    final db = await _database;
    final List<Map<String, dynamic>> cardMaps = await db.query('cards');
    
    List<TodoCard> results = [];

    for (var cardMap in cardMaps) {
      int cardId = cardMap['id'];
      final List<Map<String, dynamic>> lineMaps = await db.query(
        'lines', 
        where: 'card_id = ?', 
        whereArgs: [cardId]
      );
      
      List<TodoLine> lines = lineMaps.map((l) => TodoLine(
        id: l['id'],
        cardId: l['card_id'],
        text: l['text'] ?? "",
        checked: l['checked'] == 1,
      )).toList();

      results.add(TodoCard(id: cardId, lines: lines));
    }
    return results;
  }
```

tutti i metodi per interagire con l'applicazione sono anchessi contenuti su helper: 

instertcard
```dart
static Future<int> insertCard() async {
  final db = await _database;
    return await db.insert('cards', {'id': null}); 
}
```
deletecard
```dart
 static Future<void> deleteCard(int id) async {
    final db = await _database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

```

insertline
```dart
 static Future<int> insertLine(TodoLine line) async {
    final db = await _database;
    return await db.insert('lines', line.toMap());
  }
```

updateline
```dart
  static Future<void> updateLine(TodoLine line) async {
    final db = await _database;
    await db.update('lines', line.toMap(), where: 'id = ?', whereArgs: [line.id]);
  }
```

deleteline
```dart
  static Future<void> deleteLine(int id) async {
    final db = await _database;
    await db.delete('lines', where: 'id = ?', whereArgs: [id]);
  }
```
---

### notifier.dart – Logica di stato

Gestisce lo **stato dell’app** e collega il database con l’interfaccia grafica tramite **ChangeNotifier**.  
Tutte le modifiche ai dati passano dal **Notifier**, che aggiorna la UI tramite `notifyListeners()`.

```dart
import 'package:flutter/widgets.dart';
import 'model.dart';
import 'helper.dart';

class TodoBoardNotifier with ChangeNotifier {


  List<TodoCard> _cards = [];

  // Getter per leggere la lista senza modificarla direttamente
  List<TodoCard> get cards {
    return _cards;
  }
```
Recupera le card dal database all'avvio dell'app

```dart
  // Recupera le card dal database all'avvio dell'app
  Future<void> loadData() async {
    _cards = await DatabaseHelper.getCards();
    notifyListeners();
  }
```
Aggiunge una nuova Card con una riga iniziale

```dart
  void addCard() async {
    int cardId = await DatabaseHelper.insertCard();
    
    TodoLine newLine = TodoLine(cardId: cardId, text: "Nuova riga");
    int lineId = await DatabaseHelper.insertLine(newLine);
    newLine.id = lineId;

    _cards.add(TodoCard(id: cardId, lines: [newLine]));
    notifyListeners();
  }
  ```
  Aggiunge una nuova riga a una Card esistente

```dart
  void addLine(TodoCard card) async {
    TodoLine newLine = TodoLine(cardId: card.id, text: "Nuova riga");
    int lineId = await DatabaseHelper.insertLine(newLine);
    newLine.id = lineId;

    card.lines.add(newLine);
    notifyListeners();
  }
  ```
  Aggiorna il testo di una riga

  ```dart
  void updateLine(TodoLine line, String newText) {
    line.text = newText;
    DatabaseHelper.updateLine(line);
    notifyListeners();
  }
```
Cambia lo stato di una riga (fatto/non fatto)

```dart
  void toggleLine(TodoLine line) {
    line.checked = !line.checked;
    DatabaseHelper.updateLine(line);
    notifyListeners();
  }
 ```
Elimina una riga specifica

 ```dart
 
  void deleteLine(TodoCard card, TodoLine line) async {
    card.lines.remove(line);
    if (line.id != null) {
      await DatabaseHelper.deleteLine(line.id!);
    }
    notifyListeners();
  }
 ```
Elimina un'intera Card con tutte le sue righe

 ```dart
  void deleteCard(TodoCard card) async {
    if (card.id != null) {
      await DatabaseHelper.deleteCard(card.id!);
      _cards.remove(card);
      notifyListeners();
    }
  }
}


###  widgets.dart – Componenti grafici

Definisce la struttura delle Card e delle Todo.  
Le righe vengono generate dinamicamente tramite l’operatore spread (`...`).
la classe è stateless perché non aggiorna lei stessa lo stato della pagina ma attende che sia il notifier a farlo

```dart
class TodoCardWidget extends StatelessWidget {
  final TodoCard card;

  const TodoCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TodoBoardNotifier>();

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ...card.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: line.checked,
                      onChanged: (_) => notifier.toggleLine(line),
                    ),
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(text: line.text),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Scrivi qualcosa...",
                        ),
                        onSubmitted: (value) =>
                            notifier.updateLine(line, value),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          notifier.deleteLine(card, line),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => notifier.deleteCard(card),
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => notifier.addLine(card),
                  icon: const Icon(Icons.add),
                  label: const Text("Aggiungi riga"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
```

---

### main.dart 

Contiene il **punto d’accesso principale** dell’app (`main()`) e definisce la struttura generale dell’interfaccia con **MaterialApp** e **TodoBoardPage**.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notifier.dart';
import 'widgets.dart';

void main() {
  runApp(const MyApp());
}
```
App principale che inizializza il ChangeNotifierProvider e carica subito i dati dal database

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TodoBoardNotifier>(
      create: (_) => TodoBoardNotifier()..loadData(),
      child: MaterialApp(
        title: 'zKeep',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: const TodoBoardPage(),
      ),
    );
  }
}
```
Pagina principale che osserva il Notifier e aggiorna automaticamente la UI

```dart
class TodoBoardPage extends StatelessWidget {
  const TodoBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<TodoBoardNotifier>().cards;

    return Scaffold(
      appBar: AppBar(
        title: const Text("zKeep"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 4,
      ),
      body: cards.isEmpty
          ? const Center(child: Text("Premi + per aggiungere una card"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return TodoCardWidget(card: cards[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<TodoBoardNotifier>().addCard(),
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```
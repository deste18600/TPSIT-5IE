# Todo List App

## Descrizione del progetto
Questa applicazione è una semplice Todo List sviluppata in Flutter.
qui segue la descrizione delle aggiunte richieste dalla consegna:

---

## Aggiunta di un Todo tramite FloatingActionButton

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    context.read<TodoListNotifier>().addTodo("Nuovo todo");
  },
  child: const Icon(Icons.add),
),
```

Il FloatingActionButton permette di aggiungere un nuovo Todo alla lista.
Alla pressione del pulsante viene chiamato il metodo `addTodo`, che aggiorna
lo stato dell’applicazione e l’interfaccia grafica.

---

## Visualizzazione dei Todo tramite Card

```dart
return Card(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: ...
  ),
);
```

Ogni Todo viene visualizzato all’interno di una Card.

## Gestione del completamento dei Todo con Checkbox

```dart
Checkbox(
  value: todo.checked,
  onChanged: (_) {
    context.read<TodoListNotifier>().changeTodo(todo);
  },
),
```

La Checkbox indica se un Todo è stato completato o meno.
Il cambio di stato viene gestito dal `TodoListNotifier`, che notifica
automaticamente l’interfaccia grafica.

---

## Modifica del testo di un Todo tramite tap

```dart
GestureDetector(
  onTap: () {
    setState(() => isEditing = true);
  },
  child: Text(widget.todo.name),
),
```

```dart
TextField(
  controller: _controller,
  autofocus: true,
  onSubmitted: (value) {
    context
        .read<TodoListNotifier>()
        .updateTodo(widget.todo, value);
    setState(() => isEditing = false);
  },
),
```

Toccando il testo di un Todo, questo diventa modificabile.
Il nuovo testo viene salvato alla conferma dell’input e aggiornato tramite
Provider.

---

## Gestione dello stato con Provider e ChangeNotifier

```dart
class TodoListNotifier with ChangeNotifier {
  final List<Todo> _todos = [];

  void addTodo(String name) {
    _todos.add(Todo(name: name, checked: false));
    notifyListeners();
  }

  void updateTodo(Todo todo, String newName) {
    todo.name = newName;
    notifyListeners();
  }
}
```

Lo stato globale dell’applicazione è gestito tramite `ChangeNotifier`
e il package Provider.
Ogni modifica alla lista dei Todo aggiorna automaticamente l’interfaccia.

---

## Separazione dello stato globale e locale

```dart
class TodoItem extends StatefulWidget {
  final Todo todo;
  const TodoItem({super.key, required this.todo});
}
```

Lo stato globale dell’applicazione è gestito dal `TodoListNotifier`,
mentre lo stato locale di modifica di un singolo Todo è gestito dal
widget `TodoItem`.

---


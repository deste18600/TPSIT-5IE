class Todo {
  int? id;
  String name;
  bool checked;

  Todo({this.id, required this.name, this.checked = false});

  // Converte un oggetto Todo in una Map per il database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'checked': checked ? 1 : 0, // SQLite non ha il tipo bool, usiamo 0 e 1
    };
  }

  // Crea un oggetto Todo da una Map letta dal database
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      name: map['name'] as String,
      checked: map['checked'] == 1,
    );
  }
}
class Todo {
  Todo({required this.name, required this.checked});
  
  String name;   // NON più final, così possiamo modificare il testo
  bool checked;
}

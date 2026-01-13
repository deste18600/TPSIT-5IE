import 'package:flutter/material.dart';
import 'package:todo_list/widgets/task_card.dart';
import 'package:uuid/uuid.dart';

class MainPage extends StatefulWidget {
  MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final textController = TextEditingController();
  List notes = []; // storing temporary notes here
  final uuid = Uuid();

//Function adds new to-do item
  void addTodo(String newNote) {
    setState(() {
      notes.add([
        uuid.v4(),
        newNote,
        false
      ]); //[to-do item identifier,content, checked status]
    });
  }

  // Function to remove a to-do item by index
  void removeTodoAt(int index) {
    setState(() {
      notes.removeAt(index);
    });
  }

// Function toggles the checkbox for each to-do item
  void changeSelection(bool? value, int index) {
    setState(() {
      notes[index][2] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Todo King"),
        backgroundColor: Theme.of(context).primaryColor, //use primary color from the colours scheme provided in the MaterialApp widget
      ),
      body: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 10).copyWith(bottom: 80, top: 20), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TaskCard(
                      key: ValueKey(notes[index][0]), //important without it code will not work correctly
                      noteContent: notes[index][1],
                      isChecked: notes[index][2],
                      deleteTodo: () {
                        removeTodoAt(index);
                      },
                      onChanged: (value) => changeSelection(value, index),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 20, //just adds some space between text field and your to-do tasks
            ),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: "Add New Item",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.all(10.0),
        child: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              addTodo(textController.text);
              textController.clear();
            }),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
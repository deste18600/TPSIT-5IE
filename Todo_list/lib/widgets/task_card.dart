import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String noteContent; // Note content
  final bool isChecked; // Note status
  final VoidCallback deleteTodo; //function to delete to-do item
  final ValueChanged<bool?> onChanged; // function to change checkbox

  TaskCard({
    required this.noteContent,
    required this.isChecked,
    required this.deleteTodo,
    required this.onChanged, // all these attributes must be provided in order for the component to work
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // retrieve current screen width

    return Container(
      width: 0.8 * screenWidth, // set width to 80% 0f screen
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor, //use primary color from the colours scheme provided in the MaterialApp widget
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row( 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Checkbox(
              value: isChecked,
              activeColor: Colors.black26, // you can still add your own colors, background colour of checkbox when chosen
              checkColor: Colors.lightBlue, // Check mark colour
              onChanged: onChanged, // method activated when checked 
            ),
            Expanded(
              child: Text(
                noteContent,
                style: TextStyle(
                  decoration: isChecked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none, // add line through when item is checked
                ),
              ),
            ),
            IconButton(onPressed: deleteTodo, icon: Icon(Icons.delete))
          ],
        ),
      ),
    );
  }
}
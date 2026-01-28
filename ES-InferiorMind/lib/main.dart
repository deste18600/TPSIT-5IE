import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

// App principale
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inferior Mind',
      theme: ThemeData.dark().copyWith(),
      home: const MyHomePage(title: 'Inferior Mind'),//guarda cosè
      debugShowCheckedModeBanner: false,
    );
  }
}

// Enum per i colori
enum ColorOption { gray, green, red, purple }

// Mappa enum -> colore Flutter
const Map<ColorOption, Color> colorMap = {
  ColorOption.gray: Colors.grey,
  ColorOption.green: Colors.green,
  ColorOption.red: Colors.red,
  ColorOption.purple: Colors.purple,
};

// Pagina principale con stato
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Stato dei 4 bottoni
  List<ColorOption> buttonColors = [
    ColorOption.gray,
    ColorOption.gray,
    ColorOption.gray,
    ColorOption.gray
  ];

  // Combinazione segreta
  List<ColorOption> target = [];

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _generateTarget();
  }

  // Genera combinazione casuale
  void _generateTarget() {
    List<ColorOption> choices = [ColorOption.green, ColorOption.red, ColorOption.purple];
    target = List.generate(4, (_) => choices[random.nextInt(choices.length)]);
    buttonColors = [ColorOption.gray, ColorOption.gray, ColorOption.gray, ColorOption.gray];
    setState(() {});
  }

  // Cambia colore bottone premuto
  void _changeColor(int index) {
    ColorOption current = buttonColors[index];
    ColorOption next;
    switch (current) {
      case ColorOption.gray:
        next = ColorOption.green;
        break;
      case ColorOption.green:
        next = ColorOption.red;
        break;
      case ColorOption.red:
        next = ColorOption.purple;
        break;
      case ColorOption.purple:
        next = ColorOption.gray;
        break;
    }
    setState(() {
      buttonColors[index] = next;
    });
  }

  // Mostra combinazione vincente e controlla se si è vinto o perso
  void _showWinningCondition() {
    // Controlla vittoria
    bool won = true;
    for (int i = 0; i < 4; i++) {
      if (buttonColors[i] != target[i]) won = false;
    }

    // Mostra messaggio vittoria o sconfitta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(won ? 'Hai vinto!' : 'Non hai indovinato'),
      ),
    );

    // Reset bottoni a grigio
    setState(() {
      buttonColors = [ColorOption.gray, ColorOption.gray, ColorOption.gray, ColorOption.gray];
    });

    // Mostra la combinazione vincente
    String colors = '';
    for (int i = 0; i < target.length; i++) {
      switch (target[i]) {
        case ColorOption.green:
          colors += 'VERDE';
          break;
        case ColorOption.red:
          colors += 'ROSSO';
          break;
        case ColorOption.purple:
          colors += 'VIOLA';
          break;
        case ColorOption.gray:
          colors += 'GRIGIO';
          break;
      }
      if (i < target.length - 1) colors += ', ';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('La combinazione vincente era: $colors')),
    );

    // Genera nuova combinazione casuale
    _generateTarget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 4 bottoni colorati
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < 4; i++)
                  FloatingActionButton(
                    backgroundColor: colorMap[buttonColors[i]],
                    onPressed: () => _changeColor(i),
                    child: const Icon(Icons.circle),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Bottone per verificare vittoria e mostrare combinazione vincente
            ElevatedButton(
              onPressed: _showWinningCondition,
              child: const Text('Verifica scelta'),
            ),
          ],
        ),
      ),
    );
  }
}


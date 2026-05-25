// ============================================================
// main.dart
// Questo è il FILE DI PARTENZA dell'app. Flutter lo esegue per primo.
//
// Contiene:
//   1. main()       → il punto di ingresso, come il "main" in C/Java
//   2. MyApp        → il widget radice che configura il tema
//   3. HomeScreen   → la schermata principale con la barra di navigazione
// ============================================================

import 'package:flutter/material.dart';
import 'screens/tuner_screen.dart';    // schermata dell'accordatore
import 'screens/spartiti_screen.dart'; // schermata degli spartiti


// ── PUNTO DI INGRESSO ────────────────────────────────────────
// main() è la prima funzione chiamata da Flutter quando l'app si avvia.
// runApp() prende il widget radice e lo monta sull'intero schermo.
void main() {
  runApp(const MyApp());
}


// ── WIDGET RADICE: MyApp ─────────────────────────────────────
// Questo widget non mostra nulla direttamente, ma configura:
//   - Il titolo dell'app (visibile nel gestore app del telefono)
//   - Il tema grafico globale (colori, font, stile dei widget)
//
// È un StatelessWidget perché non cambia mai dopo la creazione.

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                   'PitchMaster',
      debugShowCheckedModeBanner: false, // nasconde il banner rosso "DEBUG"

      // ── TEMA GLOBALE ───────────────────────────────────────
      // Tutto il tema è buio (dark) con accenti dorati.
      // I colori definiti qui vengono usati automaticamente
      // da tutti i widget dell'app (AppBar, pulsanti, ecc.)
      theme: ThemeData(
        brightness:              Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // sfondo quasi nero

        // ColorScheme: la palette di colori principale dell'app
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFFD4AF37), // oro principale (pulsanti, accenti)
          secondary: Color(0xFFC5A880), // oro morbido (testi secondari)
          surface:   Color(0xFF161616), // superfici card/dialog
          onSurface: Colors.white,      // testo su superfici
        ),

        // Stile della barra in cima (AppBar)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation:       0, // senza ombra sotto la barra
          iconTheme:       IconThemeData(color: Color(0xFFD4AF37)),
          titleTextStyle:  TextStyle(
            color:      Color(0xFFD4AF37),
            fontSize:   20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Stile della barra di navigazione in fondo
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor:    Color(0xFF0A0A0A),
          selectedItemColor:  Color(0xFFD4AF37), // voce selezionata: oro
          unselectedItemColor: Colors.white30,  // voci non selezionate: grigio chiaro
        ),
      ),

      // La schermata iniziale dell'app
      home: const HomeScreen(),
    );
  }
}


// ── SCHERMATA PRINCIPALE: HomeScreen ─────────────────────────
// Gestisce la navigazione tra le due schermate principali
// tramite una barra di navigazione in fondo (BottomNavigationBar).
//
// È un StatefulWidget perché deve ricordare quale tab è attivo.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  // Indice della schermata attualmente visibile:
  //   0 = Accordatore (TunerScreen)
  //   1 = Spartiti (SpartitiScreen)
  int _indiceAttivo = 0;

  // La lista delle schermate.
  // Sono "const" perché non cambiano: vengono create una sola volta.
  final List<Widget> _schermate = const [
    TunerScreen(),
    SpartitiScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // Mostra la schermata corrispondente all'indice attivo
      body: _schermate[_indiceAttivo],

      // ── Barra di navigazione in fondo ─────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAttivo,

        // Quando l'utente tocca una voce, aggiorna l'indice
        // setState() fa ridisegnare il widget con il nuovo indice
        onTap: (nuovoIndice) => setState(() => _indiceAttivo = nuovoIndice),

        items: const [
          // Prima voce: Accordatore
          BottomNavigationBarItem(
            icon:  Icon(Icons.graphic_eq),
            label: 'Accordatore',
          ),
          // Seconda voce: Spartiti
          BottomNavigationBarItem(
            icon:  Icon(Icons.library_music),
            label: 'Spartiti',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/tuner_screen.dart';    
import 'screens/spartiti_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                   'PitchMaster',
      debugShowCheckedModeBanner: false, 

      theme: ThemeData(
        brightness:  Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), 


        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFFD4AF37), 
          secondary: Color(0xFFC5A880), 
          surface:   Color(0xFF161616), 
          onSurface: Colors.white,      
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation:       0,
          iconTheme:       IconThemeData(color: Color(0xFFD4AF37)),
          titleTextStyle:  TextStyle(
            color:      Color(0xFFD4AF37),
            fontSize:   20,
            fontWeight: FontWeight.bold,
          ),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor:    Color(0xFF0A0A0A),
          selectedItemColor:  Color(0xFFD4AF37), 
          unselectedItemColor: Colors.white30,  
        ),
      ),


      home: const HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  int _indiceAttivo = 0;

  final List<Widget> _schermate = const [
    TunerScreen(),
    SpartitiScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _schermate[_indiceAttivo],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAttivo,

        onTap: (nuovoIndice) => setState(() => _indiceAttivo = nuovoIndice),

        items: const [
          BottomNavigationBarItem(
            icon:  Icon(Icons.graphic_eq),
            label: 'Accordatore',
          ),

          BottomNavigationBarItem(
            icon:  Icon(Icons.library_music),
            label: 'Spartiti',
          ),
        ],
      ),
    );
  }
}

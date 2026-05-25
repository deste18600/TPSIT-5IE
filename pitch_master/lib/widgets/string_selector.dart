// ============================================================
// string_selector.dart
// Pulsanti circolari per scegliere la corda da accordare.
// Disposizione: due colonne affiancate, indici pari a sinistra
// e indici dispari a destra.
// ============================================================

import 'package:flutter/material.dart';


class StringSelector extends StatelessWidget {

  final List<String>  strings;       // es. ['Mi2', 'La2', 'Re3', ...]
  final int           selectedIndex;
  final Function(int) onSelected;

  const StringSelector({
    super.key,
    required this.strings,
    required this.selectedIndex,
    required this.onSelected,
  });


  @override
  Widget build(BuildContext context) {

    // Indici pari → colonna sinistra, dispari → colonna destra
    final sinistra = <int>[];
    final destra   = <int>[];

    for (int i = 0; i < strings.length; i++) {
      if (i % 2 == 0) sinistra.add(i);
      else             destra.add(i);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // Colonna sinistra
        Column(
          children: sinistra.map((i) => _pulsante(i)).toList(),
        ),

        const SizedBox(width: 20), // spazio tra le due colonne

        // Colonna destra
        Column(
          children: destra.map((i) => _pulsante(i)).toList(),
        ),
      ],
    );
  }


  Widget _pulsante(int index) {
    final bool sel = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sel ? const Color(0xFFD4AF37) : const Color(0xFF161616),
            border: Border.all(
              color: sel
                  ? const Color(0xFFD4AF37)
                  : const Color(0xFFD4AF37).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: sel
                ? [BoxShadow(
                    color:        const Color(0xFFD4AF37).withOpacity(0.4),
                    blurRadius:   8,
                    spreadRadius: 1,
                  )]
                : null,
          ),
          child: Center(
            child: Text(
              strings[index],
              style: TextStyle(
                color:      sel ? const Color(0xFF0A0A0A) : const Color(0xFFC5A880),
                fontWeight: FontWeight.bold,
                fontSize:   13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

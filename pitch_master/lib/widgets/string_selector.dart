import 'package:flutter/material.dart';

class StringSelector extends StatelessWidget {
  final List<String> strings;
  final int selectedIndex;
  final Function(int) onSelected;

  const StringSelector({
    super.key,
    required this.strings,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sinistra = <int>[];
    final destra = <int>[];

    for (int i = 0; i < strings.length; i++) {
      if (i % 2 == 0) {
        sinistra.add(i);
      } else {
        destra.add(i);
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: sinistra.map((i) {
            return _pulsante(i);
          }).toList(),
        ),
        const SizedBox(width: 20),
        Column(
          children: destra.map((i) {
            return _pulsante(i);
          }).toList(),
        ),
      ],
    );
  }

  Widget _pulsante(int index) {
    final bool sel = index == selectedIndex;

    Color coloreSfondo = const Color(0xFF161616);
    Color coloreBordo = const Color(0xFFD4AF37).withOpacity(0.3);
    List<BoxShadow>? ombre = null;
    Color coloreTesto = const Color(0xFFC5A880);

    if (sel) {
      coloreSfondo = const Color(0xFFD4AF37);
      coloreBordo = const Color(0xFFD4AF37);
      ombre = [
        BoxShadow(
          color: const Color(0xFFD4AF37).withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 1,
        )
      ];
      coloreTesto = const Color(0xFF0A0A0A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          onSelected(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58, 
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: coloreSfondo,
            border: Border.all(
              color: coloreBordo,
              width: 1.5,
            ),
            boxShadow: ombre,
          ),
          child: Center(
            child: Text(
              strings[index],
              style: TextStyle(
                color: coloreTesto,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
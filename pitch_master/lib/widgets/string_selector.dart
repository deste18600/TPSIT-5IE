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
    // Divide le corde in sinistra e destra come GuitarTuna
    final leftStrings = <int>[];
    final rightStrings = <int>[];

    for (int i = 0; i < strings.length; i++) {
      if (i % 2 == 0) {
        leftStrings.add(i);
      } else {
        rightStrings.add(i);
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Colonna sinistra
        Column(
          children: leftStrings.map((i) => _buildButton(i)).toList(),
        ),

        // Immagine testiera (placeholder)
        Container(
          width: 120,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A574),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('🎸', style: TextStyle(fontSize: 60)),
          ),
        ),

        // Colonna destra
        Column(
          children: rightStrings.map((i) => _buildButton(i)).toList(),
        ),
      ],
    );
  }

  Widget _buildButton(int index) {
    final isSelected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.blueAccent : const Color(0xFF2A2A3E),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.white24,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              strings[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
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

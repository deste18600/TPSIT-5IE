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
        Column(
          children: leftStrings.map((i) => _buildButton(i)).toList(),
        ),
        // Tastiera chitarra mockup nera ed oro
        Container(
          width: 96,
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF222222), Color(0xFF111111)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              // Frets (tasti chitarra)
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    5,
                    (index) => Container(
                      height: 1,
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              // Strings (corde dorate)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 1.2,
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              // Cerchio centrale con emoji chitarra
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Text(
                    '🎸',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: rightStrings.map((i) => _buildButton(i)).toList(),
        ),
      ],
    );
  }

  Widget _buildButton(int index) {
    final isSelected = index == selectedIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF161616),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              strings[index],
              style: TextStyle(
                color: isSelected ? const Color(0xFF0A0A0A) : const Color(0xFFC5A880),
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
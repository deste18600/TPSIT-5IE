import 'package:flutter/material.dart';
import 'dart:math';

class FrequencyGauge extends StatelessWidget {
  final double centsOffset; // valore tra -100 e +100

  const FrequencyGauge({super.key, required this.centsOffset});

  Color _getColor() {
    if (centsOffset.abs() <= 5) return Colors.green;
    if (centsOffset.abs() <= 20) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 160,
      child: CustomPaint(
        painter: _GaugePainter(centsOffset: centsOffset, color: _getColor()),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double centsOffset;
  final Color color;

  _GaugePainter({required this.centsOffset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Sfondo arco
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Zona verde centrale
    final greenPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi + (pi * 0.45),
      pi * 0.1,
      false,
      greenPaint,
    );

    // Ago
    final angle = pi + (pi * (centsOffset + 100) / 200);
    final needleEnd = Offset(
      center.dx + (radius - 20) * cos(angle),
      center.dy + (radius - 20) * sin(angle),
    );

    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Pallino centrale
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);

    // Tacche e numeri
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var label in [-100, -60, -40, -20, 0, 20, 40, 60, 100]) {
      final labelAngle = pi + (pi * (label + 100) / 200);
      final tickStart = Offset(
        center.dx + (radius - 18) * cos(labelAngle),
        center.dy + (radius - 18) * sin(labelAngle),
      );
      final tickEnd = Offset(
        center.dx + (radius - 30) * cos(labelAngle),
        center.dy + (radius - 30) * sin(labelAngle),
      );

      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = Colors.white38
          ..strokeWidth = 1.5,
      );

      textPainter.text = TextSpan(
        text: label == 0 ? '0' : (label > 0 ? '+$label' : '$label'),
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      );
      textPainter.layout();
      final textPos = Offset(
        center.dx + (radius - 44) * cos(labelAngle) - textPainter.width / 2,
        center.dy + (radius - 44) * sin(labelAngle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.centsOffset != centsOffset;
}

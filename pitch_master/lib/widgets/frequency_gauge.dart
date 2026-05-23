import 'package:flutter/material.dart';
import 'dart:math';

class FrequencyGauge extends StatelessWidget {
  final double centsOffset;

  const FrequencyGauge({super.key, required this.centsOffset});

  Color _getColor() {
    if (centsOffset.abs() <= 5) return const Color(0xFF2ECC71); // Smeraldo per accordato
    if (centsOffset.abs() <= 20) return const Color(0xFFF1C40F); // Oro brillante
    return const Color(0xFFD4AF37); // Oro metallico standard
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

    // Sfondo dell'arco (nero antracite profondo)
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi, pi, false, bgPaint,
    );

    // Bordo dorato esterno molto sottile ed elegante
    final goldBorderPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      pi, pi, false, goldBorderPaint,
    );

    // Zona centrale di tolleranza (verde smeraldo morbido)
    final greenZonePaint = Paint()
      ..color = const Color(0xFF2ECC71).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi + (pi * 0.475), pi * 0.05, false, greenZonePaint,
    );

    // Calcolo angolo dell'ago
    final angle = pi + (pi * (centsOffset + 100) / 200);
    final needleEnd = Offset(
      center.dx + (radius - 20) * cos(angle),
      center.dy + (radius - 20) * sin(angle),
    );

    // Disegno ombra dell'ago per effetto 3D
    final shadowEnd = Offset(
      center.dx + (radius - 20) * cos(angle + 0.02) + 2,
      center.dy + (radius - 20) * sin(angle + 0.02) + 2,
    );
    canvas.drawLine(
      center,
      shadowEnd,
      Paint()
        ..color = Colors.black45
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Disegno ago (colorazione dinamica dorato/smeraldo)
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Pallino centrale - Anello metallico dorato con perla nera interna
    final goldRingPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    final innerDarkPaint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 10, goldRingPaint);
    canvas.drawCircle(center, 6, innerDarkPaint);
    canvas.drawCircle(center, 3, Paint()..color = color); // Nucleo luminoso

    // Tacche e numeri (dorati)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var label in [-100, -60, -40, -20, 0, 20, 40, 60, 100]) {
      final labelAngle = pi + (pi * (label + 100) / 200);
      
      // Colore della tacca (dorata o smeraldo per la tacca 0)
      final tickColor = label == 0
          ? const Color(0xFF2ECC71).withOpacity(0.8)
          : const Color(0xFFD4AF37).withOpacity(0.5);

      canvas.drawLine(
        Offset(center.dx + (radius - 18) * cos(labelAngle),
            center.dy + (radius - 18) * sin(labelAngle)),
        Offset(center.dx + (radius - 28) * cos(labelAngle),
            center.dy + (radius - 28) * sin(labelAngle)),
        Paint()..color = tickColor..strokeWidth = 1.5,
      );

      textPainter.text = TextSpan(
        text: label == 0 ? '0' : (label > 0 ? '+$label' : '$label'),
        style: TextStyle(
          color: label == 0 
              ? const Color(0xFF2ECC71) 
              : const Color(0xFFC5A880), // Oro tenue per le etichette
          fontSize: 9,
          fontWeight: label == 0 ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(
        center.dx + (radius - 42) * cos(labelAngle) - textPainter.width / 2,
        center.dy + (radius - 42) * sin(labelAngle) - textPainter.height / 2,
      ));
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.centsOffset != centsOffset || old.color != color;
}
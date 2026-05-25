import 'package:flutter/material.dart';
import 'dart:math';

class FrequencyGauge extends StatelessWidget {
  final double centsOffset;

  const FrequencyGauge({super.key, required this.centsOffset});

  Color _scegliColore() {
    if (centsOffset.abs() <= 5) {
      return const Color(0xFF2ECC71);
    }
    if (centsOffset.abs() <= 20) {
      return const Color(0xFFF1C40F);
    }
    return const Color(0xFFD4AF37);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 160,
      child: CustomPaint(
        painter: _GaugePainter(
          centsOffset: centsOffset,
          colore: _scegliColore(),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double centsOffset;
  final Color colore;

  _GaugePainter({required this.centsOffset, required this.colore});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height);
    final raggio = size.width / 2;

    final pennelloSfondo = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio - 10),
      pi,
      pi,
      false,
      pennelloSfondo,
    );

    final pennelloBordoOro = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio - 5),
      pi,
      pi,
      false,
      pennelloBordoOro,
    );

    final pennelloZonaVerde = Paint()
      ..color = const Color(0xFF2ECC71).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio - 10),
      pi + (pi * 0.475),
      pi * 0.05,
      false,
      pennelloZonaVerde,
    );

    final angolo = pi + (pi * (centsOffset + 100) / 200);

    final puntaAgo = Offset(
      centro.dx + (raggio - 20) * cos(angolo),
      centro.dy + (raggio - 20) * sin(angolo),
    );

    final puntaOmbra = Offset(
      centro.dx + (raggio - 20) * cos(angolo + 0.02) + 2,
      centro.dy + (raggio - 20) * sin(angolo + 0.02) + 2,
    );

    canvas.drawLine(
      centro,
      puntaOmbra,
      Paint()
        ..color = Colors.black45
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawLine(
      centro,
      puntaAgo,
      Paint()
        ..color = colore
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(centro, 10, Paint()..color = const Color(0xFFD4AF37));
    canvas.drawCircle(centro, 6, Paint()..color = const Color(0xFF0A0A0A));
    canvas.drawCircle(centro, 3, Paint()..color = colore);

    final pittoreTesto = TextPainter(textDirection: TextDirection.ltr);
    final etichette = [-100, -60, -40, -20, 0, 20, 40, 60, 100];

    for (final valore in etichette) {
      final angoloTacca = pi + (pi * (valore + 100) / 200);

      Color coloreTacca = const Color(0xFFD4AF37).withOpacity(0.5);
      if (valore == 0) {
        coloreTacca = const Color(0xFF2ECC71).withOpacity(0.8);
      }

      final inizio = Offset(
        centro.dx + (raggio - 18) * cos(angoloTacca),
        centro.dy + (raggio - 18) * sin(angoloTacca),
      );
      final fine = Offset(
        centro.dx + (raggio - 28) * cos(angoloTacca),
        centro.dy + (raggio - 28) * sin(angoloTacca),
      );

      canvas.drawLine(inizio, fine, Paint()..color = coloreTacca..strokeWidth = 1.5);

      String testoEtichetta;
      if (valore == 0) {
        testoEtichetta = '0';
      } else if (valore > 0) {
        testoEtichetta = '+$valore';
      } else {
        testoEtichetta = '$valore';
      }

      Color coloreTesto = const Color(0xFFC5A880);
      FontWeight pesoTesto = FontWeight.normal;
      
      if (valore == 0) {
        coloreTesto = const Color(0xFF2ECC71);
        pesoTesto = FontWeight.bold;
      }

      pittoreTesto.text = TextSpan(
        text: testoEtichetta,
        style: TextStyle(
          color: coloreTesto,
          fontSize: 9,
          fontWeight: pesoTesto,
        ),
      );

      pittoreTesto.layout();

      pittoreTesto.paint(
        canvas,
        Offset(
          centro.dx + (raggio - 42) * cos(angoloTacca) - pittoreTesto.width / 2,
          centro.dy + (raggio - 42) * sin(angoloTacca) - pittoreTesto.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter vecchio) {
    if (vecchio.centsOffset != centsOffset) {
      return true;
    }
    if (vecchio.colore != colore) {
      return true;
    }
    return false;
  }
}
// ============================================================
// frequency_gauge.dart
// Questo file disegna il "quadrante" semicircolare dell'accordatore:
// l'ago che si sposta a sinistra/destra per mostrare quanto
// la nota è fuori tono.
//
// Usa "CustomPainter": un sistema di Flutter che ti permette
// di disegnare forme geometriche personalizzate su una "tela" (canvas).
// È come disegnare con una matita: prima scegli il colore, poi disegni.
//
// L'ago si trova al centro (0 cents) quando la nota è perfetta.
// Va a sinistra se la nota è troppo bassa (flat, negativo).
// Va a destra se la nota è troppo alta (sharp, positivo).
// ============================================================

import 'package:flutter/material.dart';
import 'dart:math'; // per pi (π) e cos(), sin() usati per calcolare le coordinate dell'ago


// ── WIDGET PRINCIPALE: FrequencyGauge ────────────────────────
// Un "StatelessWidget" è un widget che non cambia stato da solo:
// riceve i dati dall'esterno (centsOffset) e li visualizza.
// Quando centsOffset cambia, Flutter ridisegna tutto da capo.

class FrequencyGauge extends StatelessWidget {

  // Lo scostamento in cents che arriva dall'accordatore
  // Valore tra -100 e +100
  final double centsOffset;

  const FrequencyGauge({super.key, required this.centsOffset});


  // ── Scegli il colore dell'ago in base alla precisione ─────
  Color _scegliColore() {
    if (centsOffset.abs() <= 5) {
      return const Color(0xFF2ECC71); // verde smeraldo = accordato!
    }
    if (centsOffset.abs() <= 20) {
      return const Color(0xFFF1C40F); // giallo oro = vicino ma non perfetto
    }
    return const Color(0xFFD4AF37);   // oro metallico = troppo lontano
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  280,
      height: 160,
      // CustomPaint usa il nostro "pittore" (_GaugePainter) per disegnare
      child: CustomPaint(
        painter: _GaugePainter(
          centsOffset: centsOffset,
          colore:      _scegliColore(),
        ),
      ),
    );
  }
}


// ── PITTORE: _GaugePainter ────────────────────────────────────
// Questa classe fa il lavoro vero: disegna tutto sull'area assegnata.
// "canvas" è la "tela" su cui disegniamo.
// "size" dice quanto è grande la tela (width × height).
//
// Coordinate: (0, 0) è l'angolo in alto a sinistra.
// x cresce verso destra, y cresce verso il basso.
//
// Per il semicerchio usiamo le coordinate polari convertite in cartesiane:
//   x = centro.x + raggio × cos(angolo)
//   y = centro.y + raggio × sin(angolo)

class _GaugePainter extends CustomPainter {

  final double centsOffset;
  final Color  colore;

  _GaugePainter({required this.centsOffset, required this.colore});


  @override
  void paint(Canvas canvas, Size size) {

    // Il centro del semicerchio è in basso al centro della tela
    final centro = Offset(size.width / 2, size.height);
    final raggio  = size.width / 2;


    // ── 1. Disegna il semicerchio di sfondo (arco grigio scuro) ──
    // Paint = "pennello" con le impostazioni di disegno
    final pennelloSfondo = Paint()
      ..color       = const Color(0xFF1E1E1E)  // grigio antracite
      ..style       = PaintingStyle.stroke     // solo il bordo, non riempito
      ..strokeWidth = 10;                      // spessore linea

    // drawArc(rettangolo, angoloInizio, ampiezza, chiusura?, pennello)
    // pi = 180°, quindi da pi a 2*pi = semicerchio inferiore
    // ma con centro in basso, da pi a pi significa il semicerchio superiore
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio - 10),
      pi,   // angolo di inizio: 180° (sinistra)
      pi,   // ampiezza: altri 180° (per completare il semicerchio)
      false, // false = non chiudere l'arco con linee rette
      pennelloSfondo,
    );


    // ── 2. Disegna il bordo dorato esterno (decorativo) ──────
    final pennelloBordoOro = Paint()
      ..color       = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio - 5),
      pi, pi, false,
      pennelloBordoOro,
    );


    // ── 3. Disegna la zona verde centrale (±5 cents) ─────────
    // È una piccola fetta al centro del semicerchio che indica
    // la zona "accordato"
    final pennelloZonaVerde = Paint()
      ..color       = const Color(0xFF2ECC71).withOpacity(0.15)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 10;

    // 0.475 * pi = parte del semicerchio per arrivare al centro
    // 0.05  * pi = piccola fetta verde (5% del semicerchio)
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raggio - 10),
      pi + (pi * 0.475), // angolo di inizio della zona verde
      pi * 0.05,         // ampiezza della zona verde
      false,
      pennelloZonaVerde,
    );


    // ── 4. Calcola l'angolo dell'ago ─────────────────────────
    // Mappiamo centsOffset da [-100, +100] all'angolo dell'ago:
    //   centsOffset = -100 → angolo = pi (tutto a sinistra, 180°)
    //   centsOffset =    0 → angolo = pi + pi/2 = 3*pi/2 (centro, 270°)
    //   centsOffset = +100 → angolo = 2*pi (tutto a destra, 360°)
    //
    // Formula: pi + pi × (centsOffset + 100) / 200
    //   (centsOffset + 100) sposta il range da [-100,+100] a [0,200]
    //   diviso 200 normalizza tra [0,1]
    //   moltiplicato pi dà l'angolo in radianti tra [0, pi]
    //   sommato pi sposta l'inizio al lato sinistro del semicerchio
    final angolo = pi + (pi * (centsOffset + 100) / 200);

    // Calcola la punta dell'ago usando trigonometria
    final puntaAgo = Offset(
      centro.dx + (raggio - 20) * cos(angolo), // coordinata X
      centro.dy + (raggio - 20) * sin(angolo), // coordinata Y
    );


    // ── 5. Disegna l'ombra dell'ago (effetto 3D) ─────────────
    // L'ombra è un ago leggermente spostato e sfocato
    final puntaOmbra = Offset(
      centro.dx + (raggio - 20) * cos(angolo + 0.02) + 2, // leggermente spostato
      centro.dy + (raggio - 20) * sin(angolo + 0.02) + 2,
    );

    canvas.drawLine(
      centro,
      puntaOmbra,
      Paint()
        ..color       = Colors.black45  // nero semitrasparente
        ..strokeWidth = 4
        ..strokeCap   = StrokeCap.round // punta arrotondata
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 2), // sfocatura
    );


    // ── 6. Disegna l'ago principale ──────────────────────────
    canvas.drawLine(
      centro,    // dalla base (centro del semicerchio)
      puntaAgo,  // fino alla punta
      Paint()
        ..color       = colore // il colore scelto prima (verde/giallo/oro)
        ..strokeWidth = 3
        ..strokeCap   = StrokeCap.round,
    );


    // ── 7. Disegna il cerchio centrale (perno dell'ago) ──────
    // Tre cerchi concentrici per un effetto metallico:
    //   esterno: oro
    //   medio:   nero (lo sfondo)
    //   interno: il colore dinamico (verde/giallo/oro)

    // Anello dorato esterno
    canvas.drawCircle(centro, 10, Paint()..color = const Color(0xFFD4AF37));

    // Cerchio nero interno
    canvas.drawCircle(centro,  6, Paint()..color = const Color(0xFF0A0A0A));

    // Nucleo colorato (tiny, solo 3px di raggio)
    canvas.drawCircle(centro,  3, Paint()..color = colore);


    // ── 8. Disegna le tacche e i numeri della scala ───────────
    // Usiamo un TextPainter per disegnare testo sul canvas.
    // Flutter non ha un metodo diretto "drawText", si usa TextPainter.
    final pittoreTesto = TextPainter(textDirection: TextDirection.ltr);

    // Lista dei valori da mostrare sulla scala
    final etichette = [-100, -60, -40, -20, 0, 20, 40, 60, 100];

    for (final valore in etichette) {

      // Calcola l'angolo di questa tacca (stessa formula dell'ago)
      final angoloTacca = pi + (pi * (valore + 100) / 200);

      // Il colore della tacca: verde per lo zero, oro tenue per gli altri
      final coloreTacca = valore == 0
          ? const Color(0xFF2ECC71).withOpacity(0.8)
          : const Color(0xFFD4AF37).withOpacity(0.5);

      // Calcola le coordinate iniziali e finali della tacca
      // La tacca è una piccola linea radiale sul bordo del semicerchio
      final inizio = Offset(
        centro.dx + (raggio - 18) * cos(angoloTacca),
        centro.dy + (raggio - 18) * sin(angoloTacca),
      );
      final fine = Offset(
        centro.dx + (raggio - 28) * cos(angoloTacca),
        centro.dy + (raggio - 28) * sin(angoloTacca),
      );

      canvas.drawLine(inizio, fine, Paint()..color = coloreTacca..strokeWidth = 1.5);


      // Prepara il testo dell'etichetta
      // Per lo zero mostra "0", per i positivi "+20", per i negativi "-20"
      String testoEtichetta;
      if (valore == 0) {
        testoEtichetta = '0';
      } else if (valore > 0) {
        testoEtichetta = '+$valore';
      } else {
        testoEtichetta = '$valore';
      }

      pittoreTesto.text = TextSpan(
        text: testoEtichetta,
        style: TextStyle(
          color:      valore == 0 ? const Color(0xFF2ECC71) : const Color(0xFFC5A880),
          fontSize:   9,
          fontWeight: valore == 0 ? FontWeight.bold : FontWeight.normal,
        ),
      );

      // layout() calcola le dimensioni del testo prima di disegnarlo
      pittoreTesto.layout();

      // Posiziona il testo più all'interno rispetto alla tacca
      // Sottraiamo metà larghezza/altezza per centrarlo sul punto
      pittoreTesto.paint(canvas, Offset(
        centro.dx + (raggio - 42) * cos(angoloTacca) - pittoreTesto.width  / 2,
        centro.dy + (raggio - 42) * sin(angoloTacca) - pittoreTesto.height / 2,
      ));
    }
  }


  // ── Quando ridisegnare? ───────────────────────────────────
  // Flutter chiama questo metodo per decidere se ridisegnare il widget.
  // Ridisegniamo solo se i valori sono cambiati (efficienza).
  @override
  bool shouldRepaint(covariant _GaugePainter vecchio) {
    return vecchio.centsOffset != centsOffset || vecchio.colore != colore;
  }
}

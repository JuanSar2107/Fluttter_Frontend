import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fondo de plano tecnico (blueprint): cuadricula, avion en vista superior y
/// de perfil con cotas. Es puramente decorativo y no recibe toques.
class BlueprintBackground extends StatelessWidget {
  const BlueprintBackground({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _BlueprintPainter(), size: Size.infinite),
    ),
  );
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  static const Color _ink = Color(0xFF6E9EEB);

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(canvas, size);
    _paintGrid(canvas, size);

    // Vista superior: grande, a la derecha.
    // El avion es casi cuadrado (envergadura ~ longitud): se ajusta a la
    // altura para que las alas no se salgan de la pantalla.
    final topWidth = math.min(size.height * 0.72, size.width * 0.62);
    final topRect = Rect.fromCenter(
      center: Offset(size.width * 0.62, size.height * 0.52),
      width: topWidth,
      height: topWidth,
    );
    _paintTopView(canvas, topRect);

    // Vista lateral: pequena, abajo a la izquierda.
    final sideWidth = (size.width * 0.3).clamp(220.0, 520.0);
    final sideRect = Rect.fromLTWH(
      size.width * 0.04,
      size.height * 0.80 - sideWidth * 0.14,
      sideWidth,
      sideWidth * 0.28,
    );
    _paintSideView(canvas, sideRect);
  }

  // --------------------------------------------------------------------------

  void _paintGlow(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.25, 0.1),
          radius: 1.1,
          colors: [
            const Color(0xFF16305A).withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = _ink.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = _ink.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    const step = 24.0;
    var i = 0;
    for (var x = 0.0; x <= size.width; x += step, i++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 5 == 0 ? major : minor,
      );
    }
    i = 0;
    for (var y = 0.0; y <= size.height; y += step, i++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 5 == 0 ? major : minor,
      );
    }
  }

  Paint _stroke(double alpha, [double width = 1.2]) => Paint()
    ..color = _ink.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round;

  /// Avion de pasillo unico, morro a la derecha. Coordenadas normalizadas
  /// (0..1) dentro de [r]; la mitad inferior es el espejo de la superior.
  void _paintTopView(Canvas canvas, Rect r) {
    Offset p(double x, double y) =>
        Offset(r.left + x * r.width, r.top + y * r.height);
    Offset m(double x, double y) => p(x, 1 - y);

    final outline = _stroke(0.55, 1.5);
    final detail = _stroke(0.32);
    final fill = Paint()..color = _ink.withValues(alpha: 0.07);

    // Fuselaje.
    final fuselage = Path()
      ..moveTo(p(0.03, 0.488).dx, p(0.03, 0.488).dy)
      ..lineTo(p(0.16, 0.466).dx, p(0.16, 0.466).dy)
      ..lineTo(p(0.86, 0.466).dx, p(0.86, 0.466).dy)
      ..quadraticBezierTo(
        p(0.985, 0.47).dx,
        p(0.985, 0.47).dy,
        p(1.0, 0.5).dx,
        p(1.0, 0.5).dy,
      )
      ..quadraticBezierTo(
        p(0.985, 0.53).dx,
        p(0.985, 0.53).dy,
        p(0.86, 0.534).dx,
        p(0.86, 0.534).dy,
      )
      ..lineTo(p(0.16, 0.534).dx, p(0.16, 0.534).dy)
      ..lineTo(p(0.03, 0.512).dx, p(0.03, 0.512).dy)
      ..close();

    // Alas y estabilizadores (superior y su espejo).
    Path wing(Offset Function(double, double) f) => Path()
      ..moveTo(f(0.58, 0.466).dx, f(0.58, 0.466).dy)
      ..lineTo(f(0.37, 0.04).dx, f(0.37, 0.04).dy)
      ..lineTo(f(0.32, 0.04).dx, f(0.32, 0.04).dy)
      ..lineTo(f(0.42, 0.466).dx, f(0.42, 0.466).dy);
    Path stabilizer(Offset Function(double, double) f) => Path()
      ..moveTo(f(0.15, 0.468).dx, f(0.15, 0.468).dy)
      ..lineTo(f(0.055, 0.31).dx, f(0.055, 0.31).dy)
      ..lineTo(f(0.02, 0.31).dx, f(0.02, 0.31).dy)
      ..lineTo(f(0.07, 0.475).dx, f(0.07, 0.475).dy);
    Path flaps(Offset Function(double, double) f) => Path()
      ..moveTo(f(0.435, 0.40).dx, f(0.435, 0.40).dy)
      ..lineTo(f(0.36, 0.12).dx, f(0.36, 0.12).dy);
    Rect engine(Offset Function(double, double) f) =>
        Rect.fromPoints(f(0.47, 0.30), f(0.57, 0.345));

    for (final f in [p, m]) {
      final w = wing(f);
      canvas.drawPath(w, fill);
      canvas.drawPath(w, outline);
      canvas.drawPath(flaps(f), detail);
      final s = stabilizer(f);
      canvas.drawPath(s, fill);
      canvas.drawPath(s, outline);
      final e = RRect.fromRectAndRadius(engine(f), const Radius.circular(4));
      canvas.drawRRect(e, fill);
      canvas.drawRRect(e, outline);
      // Pilon del motor.
      final eRect = engine(f);
      canvas.drawLine(
        Offset(eRect.center.dx, eRect.center.dy),
        Offset(eRect.center.dx - 4, eRect.center.dy),
        detail,
      );
    }
    canvas.drawPath(fuselage, fill);
    canvas.drawPath(fuselage, outline);

    // Cabina y ventanillas.
    canvas.drawArc(
      Rect.fromCenter(center: p(0.955, 0.5), width: 22, height: 26),
      -1.2,
      2.4,
      false,
      detail,
    );
    for (var x = 0.2; x < 0.88; x += 0.025) {
      canvas.drawCircle(p(x, 0.474), 1.1, detail);
      canvas.drawCircle(p(x, 0.526), 1.1, detail);
    }

    // Eje longitudinal discontinuo.
    _dashedLine(canvas, p(-0.03, 0.5), p(1.04, 0.5), _stroke(0.28));

    // Cotas: longitud (abajo) y envergadura (izquierda).
    final dim = _stroke(0.4);
    _dimension(canvas, p(0.03, 1.02), p(1.0, 1.02), '37.57 m', dim);
    _dimension(canvas, p(0.24, 0.04), p(0.24, 0.96), '35.80 m', dim);

    _label(canvas, p(0.0, -0.04), 'VISTA SUPERIOR · ESC 1:200');
    _label(canvas, p(0.70, 0.08), 'A320-200  /  AERO-PARTS', size: 13);
    _label(canvas, p(0.70, 0.12), 'PLANO N.º AP-0420  ·  REV. C', size: 10);
  }

  /// Perfil lateral sencillo, morro a la derecha.
  void _paintSideView(Canvas canvas, Rect r) {
    Offset p(double x, double y) =>
        Offset(r.left + x * r.width, r.top + y * r.height);
    final outline = _stroke(0.45, 1.3);
    final detail = _stroke(0.28);

    final body = Path()
      ..moveTo(p(0.0, 0.42).dx, p(0.0, 0.42).dy)
      ..lineTo(p(0.12, 0.40).dx, p(0.12, 0.40).dy)
      ..lineTo(p(0.88, 0.40).dx, p(0.88, 0.40).dy)
      ..quadraticBezierTo(
        p(1.0, 0.45).dx,
        p(1.0, 0.45).dy,
        p(0.99, 0.62).dx,
        p(0.99, 0.62).dy,
      )
      ..quadraticBezierTo(
        p(0.96, 0.72).dx,
        p(0.96, 0.72).dy,
        p(0.85, 0.72).dx,
        p(0.85, 0.72).dy,
      )
      ..lineTo(p(0.2, 0.72).dx, p(0.2, 0.72).dy)
      ..lineTo(p(0.0, 0.52).dx, p(0.0, 0.52).dy)
      ..close();
    canvas.drawPath(body, outline);

    // Deriva vertical.
    final fin = Path()
      ..moveTo(p(0.03, 0.42).dx, p(0.03, 0.42).dy)
      ..lineTo(p(-0.02, 0.0).dx, p(-0.02, 0.0).dy)
      ..lineTo(p(0.05, 0.0).dx, p(0.05, 0.0).dy)
      ..lineTo(p(0.16, 0.40).dx, p(0.16, 0.40).dy);
    canvas.drawPath(fin, outline);

    // Motor y tren.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(p(0.44, 0.74), p(0.56, 0.88)),
        const Radius.circular(3),
      ),
      outline,
    );
    for (final x in [0.42, 0.86]) {
      canvas.drawLine(p(x, 0.72), p(x, 0.92), detail);
      canvas.drawCircle(p(x, 0.96), 3, detail);
    }
    for (var x = 0.2; x < 0.86; x += 0.03) {
      canvas.drawCircle(p(x, 0.50), 1, detail);
    }
    _dashedLine(canvas, p(-0.04, 1.0), p(1.04, 1.0), _stroke(0.14));
    _label(canvas, p(0.0, 1.08), 'VISTA LATERAL');
  }

  // --------------------------------------------------------------------------

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 10.0;
    const gap = 6.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += dash + gap) {
      final end = (d + dash).clamp(0.0, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
    }
  }

  void _dimension(Canvas canvas, Offset a, Offset b, String text, Paint paint) {
    canvas.drawLine(a, b, paint);
    final dir = (b - a) / (b - a).distance;
    final normal = Offset(-dir.dy, dir.dx);
    for (final end in [a, b]) {
      canvas.drawLine(end - normal * 6, end + normal * 6, paint);
    }
    // Flechas.
    void arrow(Offset tip, Offset towards) {
      canvas.drawLine(tip, tip + towards * 9 + normal * 3.5, paint);
      canvas.drawLine(tip, tip + towards * 9 - normal * 3.5, paint);
    }

    arrow(a, dir);
    arrow(b, -dir);

    final mid = Offset.lerp(a, b, 0.5)!;
    final vertical = dir.dx.abs() < 0.5;
    canvas.save();
    canvas.translate(mid.dx, mid.dy);
    if (vertical) canvas.rotate(-1.5708);
    _label(canvas, const Offset(0, -16), text, centered: true);
    canvas.restore();
  }

  void _label(
    Canvas canvas,
    Offset at,
    String text, {
    double size = 10.5,
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
          color: _ink.withValues(alpha: 0.6),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, centered ? at - Offset(painter.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(_BlueprintPainter oldDelegate) => false;
}

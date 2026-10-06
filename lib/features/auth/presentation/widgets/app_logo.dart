import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Marca de la aplicacion: un rotor de helicoptero estilizado.
///
/// Dibujado con `CustomPainter` en vez de un PNG para que sea nitido en
/// cualquier densidad de pantalla y herede los colores del tema.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final emblem = _RotorEmblem(
      size: size,
      blade: Theme.of(context).colorScheme.secondary,
      hub: Colors.white,
    );

    if (!showWordmark) {
      return emblem;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AeroParts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            Text(
              'Control de repuestos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _RotorEmblem extends StatelessWidget {
  const _RotorEmblem({
    required this.size,
    required this.blade,
    required this.hub,
  });

  final double size;
  final Color blade;
  final Color hub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: CustomPaint(
        painter: _RotorPainter(blade: blade, hub: hub),
      ),
    );
  }
}

class _RotorPainter extends CustomPainter {
  const _RotorPainter({required this.blade, required this.hub});

  final Color blade;
  final Color hub;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final bladePaint = Paint()..color = blade;

    // Cuatro palas: helicoptera conventional (no coaxia).
    const bladeCount = 4;
    for (var i = 0; i < bladeCount; i++) {
      final angle = (i * 2 * 3.14159265 / bladeCount) + 0.4;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final path = Path()
        ..moveTo(0, -radius * 0.14)
        ..quadraticBezierTo(
          radius * 0.62,
          -radius * 0.34,
          radius * 0.84,
          -radius * 0.10,
        )
        ..quadraticBezierTo(
          radius * 0.60,
          radius * 0.06,
          0,
          radius * 0.14,
        )
        ..close();
      canvas.drawPath(path, bladePaint);

      canvas.restore();
    }

    // Cono del rotor.
    final hubPaint = Paint()..color = hub;
    canvas.drawCircle(center, radius * 0.20, hubPaint);
    canvas.drawCircle(
      center,
      radius * 0.09,
      Paint()..color = blade.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_RotorPainter oldDelegate) =>
      oldDelegate.blade != blade || oldDelegate.hub != hub;
}

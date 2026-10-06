import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/login_form.dart';

/// Pantalla de acceso.
///
/// ## Diseno responsivo
///
/// Por debajo de 900 px se muestra solo el formulario (movil/tablet vertical).
/// A partir de ahi aparece un panel de marca a la izquierda. El breakpoint
/// esta en el `LayoutBuilder`, no en `MediaQuery`, para que el panel dependa
/// del ancho **disponible** y no del de la ventana: asi funciona igual dentro
/// de una pestana dividida o de un escritorio con una ventana dividida.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const double _breakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showBrandPanel = constraints.maxWidth >= _breakpoint;

            return Row(
              children: [
                if (showBrandPanel)
                  Expanded(flex: 5, child: const _BrandPanel())
                else
                  const SizedBox.shrink(),
                Expanded(flex: 6, child: const _FormPanel()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          // Textura de cuadricula, evocando cartas tecnicas.
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // SingleChildScrollView ocupa todo el alto disponible (gracias al
          // Expanded padre) y permite desplazar si el contenido es mas alto.
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              // Fuerza altura minima igual al viewport para que el contenido
              // quede centrado verticalmente cuando cabe, y haga scroll si no.
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 60),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Inventario de\nrepuestos aeronáuticos',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Control de stock, trazabilidad de componentes y '
                      'certificados para flotas aeronáuticas.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _FeatureList(theme: theme),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Entorno de demostración',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    // Espacio extra al final para que no se pegue al borde al
                    // hacer scroll hasta abajo.
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.theme});

  final ThemeData theme;

  static const _features = <({IconData icon, String label})>[
    (icon: Icons.inventory_2_outlined, label: 'Existencias por pieza'),
    (icon: Icons.qr_code_2_outlined, label: 'Trazabilidad por lote'),
    (icon: Icons.verified_outlined, label: 'Certificados de conformidad'),
    (icon: Icons.timeline_outlined, label: 'Historial de movimientos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in _features)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  feature.icon,
                  size: 20,
                  color: AppColors.amber,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  feature.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const step = 48.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _FormPanel extends StatelessWidget {
  const _FormPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          // Limita el ancho para que el formulario no se estire en monitores
          // grandes, donde una linea de texto de 800 px es incomoda de leer.
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Solo en movil, donde no hay panel de marca.
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  if (!isNarrow) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const AppLogo(size: 52, showWordmark: true),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  );
                },
              ),
              Text('Iniciar sesion', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ingresa tus credenciales para acceder al almacen.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
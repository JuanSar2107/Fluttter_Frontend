import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Pantalla de carga mientras se restaura la sesion guardada.
///
/// Solo aparece si el almacenamiento seguro responde lento. Si falla la
/// lectura, `AppRouter` decide entre reintentar o mostrar el login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 64),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Restaurando sesion...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

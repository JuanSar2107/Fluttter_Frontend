import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import '../widgets/app_logo.dart';

/// Error al leer la sesion guardada.
///
/// Se muestra cuando el almacenamiento seguro falla de forma inesperada, algo
/// distinto de "no hay sesion". Ofrece reintentar y, en ultimo caso, entrar
/// desde cero.
class SessionErrorScreen extends ConsumerWidget {
  const SessionErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final message = describeAuthError(error);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 56),
                const SizedBox(height: AppSpacing.xl),
                Icon(
                  Icons.cloud_off_outlined,
                  size: 44,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No pudimos recuperar tu sesion',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).retry(),
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Entrar de todos modos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

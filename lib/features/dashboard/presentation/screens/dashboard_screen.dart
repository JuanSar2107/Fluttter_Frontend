import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/app_logo.dart';
import '../../../../routing/app_router.dart';

/// Pantalla principal (Dashboard) con la misma estructura visual que el panel
/// derecho del login: centrado, ancho máximo 420px, con header de marca en móvil.
///
/// Evita el layout partido (brand panel + content) para evitar problemas de
/// overflow en tests. Cuando se necesite el panel lateral, se puede añadir
/// copiando el patrón del LoginScreen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 28, showWordmark: false),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.inventory),
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Inventario',
          ),
          const SizedBox(width: AppSpacing.xs),
          if (user != null)
            IconButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: SafeArea(
        child: _ContentPanel(user: user),
      ),
    );
  }
}

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({required this.user});

  final AppUser? user;

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
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con logo + badge de usuario (estilo login móvil)
              _MobileHeader(user: user),
              const SizedBox(height: AppSpacing.xl),

              // Título de la página
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Bienvenido de vuelta, ${user?.displayName ?? 'Operador'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Placeholder de contenido
              _EmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogo(size: 52, showWordmark: true),
        const SizedBox(height: AppSpacing.lg),
        if (user != null) _MobileUserBadge(user: user!),
      ],
    );
  }
}

class _MobileUserBadge extends StatelessWidget {
  const _MobileUserBadge({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.secondary,
            child: Text(
              user.initials,
              style: TextStyle(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user.role.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Dashboard en construcción',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Aquí se mostrarán KPIs, gráficas de stock, alertas y accesos '
            'rápidos a los módulos principales.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_chart_outlined, size: 18),
                  label: const Text('Añadir widget'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Configurar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
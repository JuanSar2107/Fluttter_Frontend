import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Pantalla principal, placeholder.
///
/// Solo confirma que la sesion funciona. Los modulos de inventario se anaden
/// aqui.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(currentSessionProvider);
    final user = session?.user;
    final dayFormat = DateFormat("EEEE d 'de' MMMM 'de' y", 'es');

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showWordmark = constraints.maxWidth > 400;
            return AppLogo(showWordmark: showWordmark, size: 32);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeCard(
                      displayName: user?.displayName ?? 'Operador',
                      roleLabel: user?.role.label ?? '',
                      date: dayFormat.format(DateTime.now()),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SessionPanel(session: session),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Modulos pendientes', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _PlaceholderGrid(isWide: isWide),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.displayName,
    required this.roleLabel,
    required this.date,
  });

  final String displayName;
  final String roleLabel;
  final String date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido, $displayName',
            style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$roleLabel · $date',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPanel extends ConsumerWidget {
  const _SessionPanel({required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Copia a local: Dart no promociona campos opcionales, y usar `session`
    // directamente haria que el compilador lo tratara como nullable siempre.
    final active = session;
    final remaining = active?.remaining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Sesion activa', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: 'Usuario', value: active?.user.username ?? '-'),
            _InfoRow(label: 'Rol', value: active?.user.role.label ?? '-'),
            _InfoRow(
              label: 'Emite',
              value: active == null
                  ? '-'
                  : DateFormat('HH:mm:ss').format(active.issuedAt),
            ),
            _InfoRow(
              label: 'Expira en',
              value: remaining == null ? '-' : _formatDuration(remaining),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesion'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'expirada';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderGrid extends StatelessWidget {
  const _PlaceholderGrid({required this.isWide});

  final bool isWide;

  static const _modules = <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.inventory_2_outlined,
      title: 'Existencias',
      subtitle: 'Stock por numero de parte',
    ),
    (
      icon: Icons.add_shopping_cart_outlined,
      title: 'Movimientos',
      subtitle: 'Entradas, salidas y ajustes',
    ),
    (
      icon: Icons.qr_code_2_outlined,
      title: 'Trazabilidad',
      subtitle: 'Lotes y serializers',
    ),
    (
      icon: Icons.assignment_outlined,
      title: 'Ordenes de trabajo',
      subtitle: 'Instalacion y remoción',
    ),
    (
      icon: Icons.description_outlined,
      title: 'Documentacion',
      subtitle: 'Fichas tecnicas y certificados',
    ),
    (
      icon: Icons.people_outline,
      title: 'Usuarios',
      subtitle: 'Roles y permisos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = isWide ? 3 : 1;

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: isWide ? 1.5 : 3.2,
      children: [
        for (final module in _modules)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(module.icon, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          module.subtitle,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

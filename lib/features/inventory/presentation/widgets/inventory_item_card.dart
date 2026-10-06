import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/inventory_item.dart';

/// Tarjeta de item de inventario con expandible "Ver más".
class InventoryItemCard extends StatefulWidget {
  const InventoryItemCard({super.key, required this.item});

  final InventoryItem item;

  @override
  State<InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends State<InventoryItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen del item
          AspectRatio(
            aspectRatio: 16 / 10,
            child: _ItemImage(imageUrl: item.imageUrl),
          ),

          // Contenido principal (siempre visible)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con PN y badge de condición
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.partNumber,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _ConditionBadge(condition: item.condition),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Descripción
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Stock y ubicación
                Row(
                  children: [
                    _StockIndicator(item: item),
                    const SizedBox(width: AppSpacing.md),
                    _LocationTag(location: item.location),
                  ],
                ),
              ],
            ),
          ),

          // Sección expandible
          SizeTransition(
            sizeFactor: _heightAnimation,
            alignment: Alignment.topCenter,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _ExpandedDetails(item: item),
            ),
          ),

          // Botón "Ver más" / "Ver menos"
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: OutlinedButton.icon(
              onPressed: _toggleExpand,
              icon: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more, size: 18),
              ),
              label: Text(_isExpanded ? 'Ver menos' : 'Ver más'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl == null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.inventory_2_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.condition});

  final PartCondition condition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (condition) {
      case PartCondition.nuevo:
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        icon = Icons.star_outline;
      case PartCondition.reparado:
        bgColor = AppColors.info.withValues(alpha: 0.15);
        textColor = AppColors.info;
        icon = Icons.build_outlined;
      case PartCondition.revisado:
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
        icon = Icons.verified_outlined;
      case PartCondition.usado:
        bgColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.history_outlined;
      case PartCondition.scrap:
        bgColor = AppColors.danger.withValues(alpha: 0.15);
        textColor = AppColors.danger;
        icon = Icons.delete_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            condition.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockIndicator extends StatelessWidget {
  const _StockIndicator({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    if (item.isOutOfStock) {
      color = AppColors.danger;
      icon = Icons.inventory_2_outlined;
      label = 'Agotado';
    } else if (item.isLowStock) {
      color = AppColors.warning;
      icon = Icons.warning_amber_outlined;
      label = 'Bajo (${item.stock})';
    } else {
      color = AppColors.success;
      icon = Icons.check_circle_outline;
      label = '${item.stock} disp.';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            location,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Características principales
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Categoría',
            value: item.category.label,
          ),
          _DetailRow(
            icon: Icons.engineering_outlined,
            label: 'Fabricante',
            value: item.manufacturer.isNotEmpty ? item.manufacturer : '—',
          ),
          _DetailRow(
            icon: Icons.settings_outlined,
            label: 'Condición',
            value: item.condition.label,
          ),
          if (item.serialNumbers.isNotEmpty)
            _DetailRow(
              icon: Icons.numbers_outlined,
              label: 'Nº Serie',
              value: item.serialNumbers.join(', '),
            ),
          if (item.certificates.isNotEmpty)
            _DetailRow(
              icon: Icons.verified_outlined,
              label: 'Certificados',
              value: item.certificates.join(', '),
            ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Notas', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              item.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
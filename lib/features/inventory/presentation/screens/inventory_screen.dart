import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/app_logo.dart';
import '../../../../routing/app_router.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_providers.dart';
import '../widgets/inventory_item_card.dart';

/// Pantalla de inventario con tarjetas de items.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(inventoryRepositoryProvider).getAll();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.dashboard),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver al dashboard',
        ),
        title: Row(
          children: [
            const AppLogo(size: 28, showWordmark: false),
            const SizedBox(width: AppSpacing.sm),
            Text('Inventario', style: theme.textTheme.titleLarge),
          ],
        ),
        actions: [
          // Botón "Agregar objeto nuevo"
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo objeto'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? _EmptyState()
            : _InventoryGrid(items: items),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(),
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  const _InventoryGrid({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula columnas basado en ancho disponible
        int crossAxisCount;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.78, // Ajustado para tarjetas con imagen + info
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return InventoryItemCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Inventario vacío',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Agrega tu primer repuesto usando el botón "Nuevo objeto"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar objeto'),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para agregar nuevo item (placeholder por ahora).
class _AddItemDialog extends StatefulWidget {
  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _partNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _locationController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _minStockController = TextEditingController(text: '1');

  PartCategory _selectedCategory = PartCategory.estructura;
  PartCondition _selectedCondition = PartCondition.nuevo;

  @override
  void dispose() {
    _partNumberController.dispose();
    _descriptionController.dispose();
    _manufacturerController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar nuevo objeto'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _partNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de parte (PN)*',
                    hintText: 'Ej: 161-500-001-001',
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción*',
                    hintText: 'Ej: Panel de control principal',
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<PartCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría*'),
                  items: PartCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<PartCondition>(
                  value: _selectedCondition,
                  decoration: const InputDecoration(labelText: 'Condición*'),
                  items: PartCondition.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCondition = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Fabricante',
                    hintText: 'Ej: Honeywell',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    hintText: 'Ej: A-01-01',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock inicial',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (int.tryParse(v) == null) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock mínimo',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (int.tryParse(v) == null) return 'Inválido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implementar creación real en repositorio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Objeto "${_partNumberController.text}" creado (demo)'),
      ),
    );
    Navigator.of(context).pop();
  }
}
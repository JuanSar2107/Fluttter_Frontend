import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/app_logo.dart';
import '../../../inventory/domain/entities/heavy_part.dart';
import '../../../inventory/presentation/providers/heavy_inventory_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final inventory = ref.watch(heavyInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 28, showWordmark: false),
        actions: [
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MobileHeader(user: user),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventario de repuestos pesados',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Controla existencias y ubicaciones de componentes aeronáuticos.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => const _AddHeavyPartDialog(),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir repuesto'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  inventory.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _InventoryLoadError(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(heavyInventoryProvider),
                    ),
                    data: (parts) => _InventoryContent(parts: parts),
                  ),
                ],
              ),
            ),
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
  Widget build(BuildContext context) => Column(
    children: [
      const AppLogo(size: 52, showWordmark: true),
      const SizedBox(height: AppSpacing.lg),
      if (user != null) _MobileUserBadge(user: user!),
    ],
  );
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
                Text(user.role.label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryContent extends ConsumerWidget {
  const _InventoryContent({required this.parts});

  final List<HeavyPart> parts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = parts.fold<int>(0, (total, part) => total + part.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Referencias',
                value: '${parts.length}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SummaryCard(
                label: 'Unidades en stock',
                value: '$units',
                icon: Icons.widgets_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Repuestos registrados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        if (parts.isEmpty)
          const _EmptyInventory()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 850
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: parts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 360,
                ),
                itemBuilder: (context, index) {
                  final part = parts[index];
                  return _HeavyPartCard(
                    part: part,
                    onEdit: () => showDialog<void>(
                      context: context,
                      builder: (_) => _AddHeavyPartDialog(part: part),
                    ),
                    onDelete: () => _confirmDelete(context, ref, part),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HeavyPart part,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar repuesto'),
        content: Text('¿Eliminar ${part.partNumber} del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(heavyInventoryProvider.notifier).removePart(part.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el repuesto: $error')),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(value, style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aún no hay repuestos registrados',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Añade el primer componente pesado para comenzar a controlar el stock.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _HeavyPartCard extends StatelessWidget {
  const _HeavyPartCard({
    required this.part,
    required this.onEdit,
    required this.onDelete,
  });

  final HeavyPart part;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: part.imagesBase64.isEmpty
                ? ColoredBox(
                    color: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.precision_manufacturing_outlined,
                      size: 48,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  )
                : Row(
                    children: part.imagesBase64
                        .map(
                          (image) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Image.memory(
                                base64Decode(image),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                  color: theme.colorScheme.secondaryContainer,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          part.partNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        tooltip: 'Editar ${part.partNumber}',
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        tooltip: 'Eliminar ${part.partNumber}',
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  Text(
                    part.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    'Ubicación: ${part.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (part.serialNumber.isNotEmpty)
                    Text(
                      'Serie: ${part.serialNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cant. ${part.quantity}',
                        style: theme.textTheme.titleSmall,
                      ),
                      Flexible(
                        child: Text(
                          part.condition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryLoadError extends StatelessWidget {
  const _InventoryLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text('No se pudo cargar el inventario: $message'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _AddHeavyPartDialog extends ConsumerStatefulWidget {
  const _AddHeavyPartDialog({this.part});

  final HeavyPart? part;

  @override
  ConsumerState<_AddHeavyPartDialog> createState() =>
      _AddHeavyPartDialogState();
}

class _AddHeavyPartDialogState extends ConsumerState<_AddHeavyPartDialog> {
  final _formKey = GlobalKey<FormState>();
  final _partNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<String> _imagesBase64 = [];
  String _condition = 'Disponible';
  String? _saveError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final part = widget.part;
    if (part == null) return;

    _partNumberController.text = part.partNumber;
    _descriptionController.text = part.description;
    _quantityController.text = '${part.quantity}';
    _locationController.text = part.location;
    _serialNumberController.text = part.serialNumber;
    _imagesBase64 = [...part.imagesBase64];
    _condition = part.condition;
  }

  @override
  void dispose() {
    _partNumberController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _serialNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.part == null ? 'Añadir repuesto pesado' : 'Editar repuesto',
    ),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(
                controller: _partNumberController,
                label: 'Número de parte',
                icon: Icons.tag,
              ),
              _textField(
                controller: _descriptionController,
                label: 'Descripción',
                icon: Icons.description_outlined,
              ),
              _textField(
                controller: _quantityController,
                label: 'Cantidad',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  if (quantity == null || quantity < 1) {
                    return 'Ingresa una cantidad mayor que cero';
                  }
                  return null;
                },
              ),
              _textField(
                controller: _locationController,
                label: 'Ubicación',
                icon: Icons.location_on_outlined,
              ),
              _textField(
                controller: _serialNumberController,
                label: 'Número de serie (opcional)',
                icon: Icons.qr_code_2_outlined,
                required: false,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Imágenes del catálogo (máximo 3)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ..._imagesBase64.asMap().entries.map(
                    (entry) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.memory(
                            base64Decode(entry.value),
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton.filledTonal(
                            visualDensity: VisualDensity.compact,
                            onPressed: _saving
                                ? null
                                : () => setState(
                                    () => _imagesBase64.removeAt(entry.key),
                                  ),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_imagesBase64.length < 3)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Agregar imágenes'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.fact_check_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Disponible',
                    child: Text('Disponible'),
                  ),
                  DropdownMenuItem(
                    value: 'En inspección',
                    child: Text('En inspección'),
                  ),
                  DropdownMenuItem(
                    value: 'No disponible',
                    child: Text('No disponible'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _condition = value);
                        }
                      },
              ),
              if (_saveError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _savePart,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(widget.part == null ? 'Guardar' : 'Guardar cambios'),
      ),
    ],
  );

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = true,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator:
          validator ??
          (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
    ),
  );

  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });
    final part = HeavyPart(
      id: widget.part?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      partNumber: _partNumberController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      location: _locationController.text.trim(),
      serialNumber: _serialNumberController.text.trim(),
      condition: _condition,
      imagesBase64: _imagesBase64,
    );

    try {
      if (widget.part == null) {
        await ref.read(heavyInventoryProvider.notifier).addPart(part);
      } else {
        await ref.read(heavyInventoryProvider.notifier).updatePart(part);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'No se pudo guardar el repuesto: $error';
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final selected = await _imagePicker.pickMultiImage(
        limit: 3 - _imagesBase64.length,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );
      if (selected.isEmpty || !mounted) return;

      final availableSlots = 3 - _imagesBase64.length;
      final encoded = await Future.wait(
        selected.take(availableSlots).map((file) async {
          return base64Encode(await file.readAsBytes());
        }),
      );
      if (!mounted) return;
      setState(() => _imagesBase64 = [..._imagesBase64, ...encoded]);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = 'No se pudieron cargar las imágenes: $error');
    }
  }
}

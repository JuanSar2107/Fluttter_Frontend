import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../inventory/domain/entities/heavy_part.dart';
import '../../../inventory/presentation/providers/category_provider.dart';
import '../../../inventory/presentation/providers/heavy_inventory_provider.dart';

const List<String> _kConditions = [
  'Disponible',
  'En inspección',
  'No disponible',
];

/// Dialogo de alta y edicion de repuestos.
///
/// Incluye un selector de categoria; los usuarios administradores tienen,
/// ademas, la opcion exclusiva de "Agregar nueva categoria" al final de la
/// lista.
class PartFormDialog extends ConsumerStatefulWidget {
  const PartFormDialog({super.key, this.part});

  final HeavyPart? part;

  @override
  ConsumerState<PartFormDialog> createState() => _PartFormDialogState();
}

class _PartFormDialogState extends ConsumerState<PartFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _partNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _minStockController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<String> _imagesBase64 = [];
  String _condition = 'Disponible';
  String _category = 'General';
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
    _minStockController.text = '${part.minStock}';
    _locationController.text = part.location;
    _serialNumberController.text = part.serialNumber;
    _imagesBase64 = [...part.imagesBase64];
    _condition = part.condition;
    _category = part.category;
  }

  @override
  void dispose() {
    _partNumberController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
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
                controller: _minStockController,
                label: 'Stock mínimo',
                icon: Icons.warning_amber_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final minStock = int.tryParse(value ?? '');
                  if (minStock == null || minStock < 0) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              _textField(
                controller: _locationController,
                label: 'Ubicación',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              _CategoryDropdown(
                initialValue: _category,
                onChanged: (value) => setState(() => _category = value),
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
                // Un estado desconocido (venido del backend) se conserva como
                // opcion: si no, el dropdown lanza una asercion al abrirse.
                items: [
                  for (final condition in {..._kConditions, _condition})
                    DropdownMenuItem(value: condition, child: Text(condition)),
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
      category: _category,
      imagesBase64: _imagesBase64,
      minStock: int.parse(_minStockController.text.trim()),
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

/// Selector de categoria del dialogo de repuestos.
///
/// Muestra las categorias existentes ordenadas alfabeticamente. Cuando el
/// usuario es administrador, agrega al final de la lista la opcion reservada
/// "Agregar nueva categoria...", que abre un dialogo para crearla; para el
/// resto de usuarios esa opcion no existe.
class _CategoryDropdown extends ConsumerStatefulWidget {
  const _CategoryDropdown({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<_CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends ConsumerState<_CategoryDropdown> {
  /// Valor reservado que representa la opcion "Agregar nueva categoria".
  static const String _addNewCategoryValue = '__add_new_category__';

  /// Accede al campo para restaurar o actualizar su valor visible despues de
  /// crear (o descartar) la creacion de una categoria.
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty || value == _addNewCategoryValue) {
      return 'Selecciona una categoría';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final sortedCategories = [...categories]
          ..sort((a, b) => a.compareTo(b));

        // La categoria actual siempre debe estar entre las opciones, aunque
        // haya sido eliminada de la lista mientras se editaba el repuesto.
        if (!sortedCategories.contains(widget.initialValue)) {
          sortedCategories.insert(0, widget.initialValue);
        }

        return _buildField(
          decoration: const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: [
            for (final category in sortedCategories)
              DropdownMenuItem<String>(value: category, child: Text(category)),
            if (isAdmin)
              const DropdownMenuItem<String>(
                value: _addNewCategoryValue,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Agregar nueva categoría...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value == _addNewCategoryValue) {
              _showAddCategoryDialog();
              return;
            }
            if (value != null) {
              widget.onChanged(value);
            }
          },
        );
      },
      loading: () => _buildField(
        decoration: const InputDecoration(
          labelText: 'Categoría',
          prefixIcon: Icon(Icons.category_outlined),
          hintText: 'Cargando categorías…',
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, _) => _buildField(
        decoration: InputDecoration(
          labelText: 'Categoría',
          prefixIcon: const Icon(Icons.category_outlined),
          errorText: 'No se pudieron cargar las categorías',
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }

  DropdownButtonFormField<String> _buildField({
    required InputDecoration decoration,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) => DropdownButtonFormField<String>(
    key: _fieldKey,
    initialValue: widget.initialValue,
    // Expande el contenido a todo el ancho disponible para que la opcion
    // "Agregar nueva categoria..." (icono + texto) no desborde el campo.
    isExpanded: true,
    decoration: decoration,
    items: items,
    onChanged: onChanged,
    validator: _validateCategory,
  );

  /// Abre el dialogo exclusivo del administrador para crear una categoria y
  /// actualiza el valor seleccionado del dropdown con el resultado.
  Future<void> _showAddCategoryDialog() async {
    final inputController = TextEditingController();
    String? createdCategory;
    var duplicated = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: inputController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            hintText: 'Ej: Neumáticos, Frenos, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = inputController.text.trim();
              if (name.isEmpty) return;

              final success = await ref
                  .read(categoryControllerProvider.notifier)
                  .addCategory(name);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);

              if (success) {
                createdCategory = name;
              } else {
                duplicated = true;
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (createdCategory != null) {
      final name = createdCategory!;
      widget.onChanged(name);
      _fieldKey.currentState?.didChange(name);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Categoría "$name" creada')));
      return;
    }

    // Cancelado o duplicado: restaura la categoria que estaba seleccionada.
    widget.onChanged(widget.initialValue);
    _fieldKey.currentState?.didChange(widget.initialValue);
    if (duplicated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('La categoría ya existe')));
    }
  }
}

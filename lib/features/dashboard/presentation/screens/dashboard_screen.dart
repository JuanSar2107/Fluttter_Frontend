import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/download/apk_download.dart';
import '../../../../core/utils/download/file_download.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../inventory/domain/entities/heavy_part.dart';
import '../../../inventory/domain/entities/stock_movement.dart';
import '../../../inventory/presentation/providers/heavy_inventory_provider.dart';
import '../widgets/blueprint_background.dart';
import '../widgets/part_form_dialog.dart';

/// Panel general de inventario tras iniciar sesion.
///
/// Escritorio: tabla filtrable de repuestos con panel lateral de detalle.
/// Movil/tablet vertical: lista de tarjetas y detalle en hoja inferior.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  /// Ancho del area principal a partir del cual se usa la tabla.
  static const double tableBreakpoint = 760;

  /// Altura minima del area principal para fijar cabecera y filtros y que la
  /// tabla ocupe el resto; por debajo se desplaza la pagina completa.
  static const double minTableViewportHeight = 640;

  /// Ancho de ventana a partir del cual el detalle va en panel lateral.
  static const double sidePanelBreakpoint = 1200;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

// ============================================================================
// PALETA (misma familia que el login)
// ============================================================================

const Color _kBg = Color(0xFF0E1522);
const Color _kPanel = Color(0xFF151E2D);

/// Panel semitransparente: deja ver el plano del avion del fondo.
const Color _kGlass = Color(0xB3131C2B);
const Color _kPanelAlt = Color(0xFF1A2536);
const Color _kBorder = Color(0xFF263244);
const Color _kRowSelected = Color(0xFF1E2B3E);
const Color _kText = Color(0xFFE8EEF5);
const Color _kMuted = Color(0xFF93A2B8);
const Color _kAmber = Color(0xFFED9D26);
const Color _kAmberSoft = Color(0xFFD9BC96);
const Color _kInputBg = Color(0xFF1F2E40);

const String _kAppVersion = 'v1.2';

// ============================================================================
// ESTADO DERIVADO DE CADA REPUESTO
// ============================================================================

enum PartStatus {
  available('Disponible', Color(0xFF1D6B3A), Color(0xFF9BE8B5)),
  inspection('Inspección', Color(0xFF1D4E7A), Color(0xFF9CCBFF)),
  low('Stock Bajo', Color(0xFF7A5414), Color(0xFFF6C66B)),
  critical('Crítico', Color(0xFF7A1F23), Color(0xFFFF9EA3));

  const PartStatus(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  /// Estado visible en el panel: combina la condicion registrada con la
  /// existencia frente al stock minimo.
  static PartStatus of(HeavyPart part) {
    if (part.condition == 'No disponible' ||
        part.quantity <= 0 ||
        part.quantity <= part.minStock) {
      return PartStatus.critical;
    }
    if (part.condition == 'En inspección') return PartStatus.inspection;
    if (part.quantity <= part.minStock * 2) return PartStatus.low;
    return PartStatus.available;
  }
}

// ============================================================================
// PANTALLA
// ============================================================================

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();

  String? _location;
  String? _category;
  PartStatus? _status;
  String _query = '';

  final Set<String> _selectedIds = {};
  String? _detailId;

  /// Si la ventana admite el panel lateral de detalle. Se toma del
  /// `LayoutBuilder` para que coincida siempre con el layout pintado.
  bool _sidePanelFits = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HeavyPart> _applyFilters(List<HeavyPart> parts) {
    final query = _query.trim().toLowerCase();
    return parts
        .where((part) {
          if (_location != null && part.location != _location) return false;
          if (_category != null && part.category != _category) return false;
          if (_status != null && PartStatus.of(part) != _status) return false;
          if (query.isEmpty) return true;
          return part.partNumber.toLowerCase().contains(query) ||
              part.description.toLowerCase().contains(query) ||
              part.serialNumber.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _clearFilters() => setState(() {
    _location = null;
    _category = null;
    _status = null;
    _query = '';
    _searchController.clear();
  });

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final inventory = ref.watch(heavyInventoryProvider);
    final parts = inventory.value ?? const <HeavyPart>[];
    final filtered = _applyFilters(parts);
    // Si el repuesto en detalle se elimino, el panel se cierra solo.
    final detailPart = parts.where((p) => p.id == _detailId).firstOrNull;
    // La seleccion solo cuenta repuestos que siguen existiendo.
    _selectedIds.removeWhere((id) => !parts.any((p) => p.id == id));

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _sidePanelFits =
                  constraints.maxWidth >= DashboardScreen.sidePanelBreakpoint;
              final showSidePanel = _sidePanelFits && detailPart != null;
              final horizontalPadding = constraints.maxWidth < 600
                  ? AppSpacing.md
                  : AppSpacing.lg;

              return Stack(
                children: [
                  const Positioned.fill(child: BlueprintBackground()),
                  Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, mainConstraints) {
                                  final useTable =
                                      mainConstraints.maxWidth >=
                                      DashboardScreen.tableBreakpoint;
                                  final header = _Header(
                                    user: user,
                                    parts: parts,
                                    onAdd: _openAddDialog,
                                    onSignOut: () => ref
                                        .read(authControllerProvider.notifier)
                                        .signOut(),
                                  );
                                  final filters = _FilterBar(
                                    parts: parts,
                                    location: _location,
                                    category: _category,
                                    status: _status,
                                    searchController: _searchController,
                                    selectedCount: _selectedIds.length,
                                    onLocationChanged: (v) =>
                                        setState(() => _location = v),
                                    onCategoryChanged: (v) =>
                                        setState(() => _category = v),
                                    onStatusChanged: (v) =>
                                        setState(() => _status = v),
                                    onQueryChanged: (v) =>
                                        setState(() => _query = v),
                                    onClearFilters: _clearFilters,
                                    onExport: (format) => _export(
                                      format,
                                      _exportTargets(parts, filtered),
                                    ),
                                    onDeleteSelected: () => _confirmDeleteMany(
                                      parts
                                          .where(
                                            (p) => _selectedIds.contains(p.id),
                                          )
                                          .toList(),
                                    ),
                                  );
                                  final Widget? body = inventory.when<Widget?>(
                                    skipLoadingOnRefresh: true,
                                    loading: () => const _CenteredMessage(
                                      child: CircularProgressIndicator(
                                        color: _kAmber,
                                      ),
                                    ),
                                    error: (error, _) => _InventoryLoadError(
                                      message: error.toString(),
                                      onRetry: () => ref.invalidate(
                                        heavyInventoryProvider,
                                      ),
                                    ),
                                    data: (_) => parts.isEmpty
                                        ? const _EmptyInventory(
                                            title: 'Aún no hay repuestos registrados',
                                            message: 'Añade el primer componente para comenzar a controlar el stock.',
                                          )
                                        : filtered.isEmpty
                                        ? _EmptyInventory(
                                            title: 'Sin resultados',
                                            message: 'Ningún repuesto coincide con los filtros.',
                                            action: TextButton(
                                              onPressed: _clearFilters,
                                              child: const Text(
                                                'Limpiar filtros',
                                              ),
                                            ),
                                          )
                                        : null,
                                  );

                                  if (useTable) {
                                    final table = _PartsTable(
                                      parts: filtered,
                                      placeholder: body,
                                      selectedIds: _selectedIds,
                                      detailId: _detailId,
                                      onToggleSelected: _toggleSelected,
                                      onToggleAll: (selectAll) => setState(() {
                                        final ids = filtered.map((p) => p.id);
                                        if (selectAll) {
                                          _selectedIds.addAll(ids);
                                        } else {
                                          _selectedIds.removeAll(ids);
                                        }
                                      }),
                                      onOpen: (part) =>
                                          _openDetail(context, part),
                                      onEdit: _openEditDialog,
                                      onDelete: _confirmDelete,
                                    );
                                    final padding = EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      AppSpacing.lg,
                                      horizontalPadding,
                                      AppSpacing.md,
                                    );

                                    // Con poca altura la cabecera y los filtros
                                    // dejarian la tabla sin espacio: se desplaza
                                    // la pagina y la tabla conserva su altura.
                                    if (mainConstraints.maxHeight <
                                        DashboardScreen
                                            .minTableViewportHeight) {
                                      return ListView(
                                        padding: padding,
                                        children: [
                                          header,
                                          const SizedBox(height: AppSpacing.md),
                                          filters,
                                          const SizedBox(height: AppSpacing.md),
                                          SizedBox(
                                            height:
                                                (mainConstraints.maxHeight - 32)
                                                    .clamp(
                                                      320,
                                                      double.infinity,
                                                    ),
                                            child: table,
                                          ),
                                        ],
                                      );
                                    }

                                    return Padding(
                                      padding: padding,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          header,
                                          const SizedBox(height: AppSpacing.md),
                                          filters,
                                          const SizedBox(height: AppSpacing.md),
                                          Expanded(child: table),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView(
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      AppSpacing.md,
                                      horizontalPadding,
                                      AppSpacing.lg,
                                    ),
                                    children: [
                                      header,
                                      const SizedBox(height: AppSpacing.md),
                                      filters,
                                      const SizedBox(height: AppSpacing.md),
                                      if (body != null)
                                        SizedBox(height: 320, child: body)
                                      else
                                        for (final part in filtered)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.sm,
                                            ),
                                            child: _PartCard(
                                              part: part,
                                              selected: _selectedIds.contains(
                                                part.id,
                                              ),
                                              onToggleSelected: () =>
                                                  _toggleSelected(part.id),
                                              onOpen: () =>
                                                  _openDetail(context, part),
                                              onEdit: () =>
                                                  _openEditDialog(part),
                                              onDelete: () =>
                                                  _confirmDelete(part),
                                            ),
                                          ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            if (showSidePanel)
                              Container(
                                width: 320,
                                decoration: const BoxDecoration(
                                  color: _kPanel,
                                  border: Border(
                                    left: BorderSide(color: _kBorder),
                                  ),
                                ),
                                child: _PartDetail(
                                  part: detailPart,
                                  onClose: () =>
                                      setState(() => _detailId = null),
                                  onEdit: () => _openEditDialog(detailPart),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _FooterBar(compact: constraints.maxWidth < 760),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Acciones
  // --------------------------------------------------------------------------

  void _toggleSelected(String id) => setState(() {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
  });

  /// Exporta la seleccion si la hay; si no, lo que muestran los filtros.
  List<HeavyPart> _exportTargets(
    List<HeavyPart> parts,
    List<HeavyPart> filtered,
  ) {
    if (_selectedIds.isEmpty) return filtered;
    return parts.where((p) => _selectedIds.contains(p.id)).toList();
  }

  void _openDetail(BuildContext context, HeavyPart part) {
    if (_sidePanelFits) {
      setState(() => _detailId = part.id);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kPanel,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _PartDetail(
          part: part,
          onClose: () => Navigator.pop(sheetContext),
          onEdit: () {
            Navigator.pop(sheetContext);
            _openEditDialog(part);
          },
        ),
      ),
    );
  }

  void _openAddDialog() => showDialog<void>(
    context: context,
    builder: (_) => const PartFormDialog(),
  );

  void _openEditDialog(HeavyPart part) => showDialog<void>(
    context: context,
    builder: (_) => PartFormDialog(part: part),
  );

  Future<void> _confirmDelete(HeavyPart part) async {
    final confirmed = await _askConfirmation(
      title: 'Eliminar repuesto',
      message: '¿Eliminar ${part.partNumber} del inventario?',
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(heavyInventoryProvider.notifier).removePart(part.id);
      if (_detailId == part.id) setState(() => _detailId = null);
    } catch (error) {
      _showMessage('No se pudo eliminar el repuesto: $error');
    }
  }

  Future<void> _confirmDeleteMany(List<HeavyPart> parts) async {
    if (parts.isEmpty) return;
    final confirmed = await _askConfirmation(
      title: 'Eliminar repuestos',
      message: '¿Eliminar ${parts.length} repuestos seleccionados?',
    );
    if (!confirmed || !mounted) return;

    final notifier = ref.read(heavyInventoryProvider.notifier);
    var failures = 0;
    for (final part in parts) {
      try {
        await notifier.removePart(part.id);
      } catch (_) {
        failures++;
      }
    }
    if (!mounted) return;
    setState(_selectedIds.clear);
    _showMessage(
      failures == 0
          ? 'Se eliminaron ${parts.length} repuestos'
          : 'No se pudieron eliminar $failures de ${parts.length} repuestos',
    );
  }

  Future<bool> _askConfirmation({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE03131),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _export(_ExportFormat format, List<HeavyPart> parts) async {
    if (parts.isEmpty) {
      _showMessage('No hay repuestos para exportar');
      return;
    }
    switch (format) {
      case _ExportFormat.csv:
        final csv = buildInventoryCsv(parts);
        final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
        final downloaded = downloadText(
          // BOM para que Excel respete los acentos.
          '﻿$csv',
          fileName: 'inventario_$stamp.csv',
          mimeType: 'text/csv',
        );
        if (downloaded) {
          _showMessage('CSV exportado (${parts.length} repuestos)');
        } else {
          await Clipboard.setData(ClipboardData(text: csv));
          _showMessage('CSV copiado al portapapeles');
        }
      case _ExportFormat.pdf:
        if (!printPage()) {
          _showMessage(
            'La exportación a PDF está disponible en la versión web',
          );
        }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// CSV del inventario (separado por comas, con comillas escapadas).
@visibleForTesting
String buildInventoryCsv(List<HeavyPart> parts) {
  String cell(Object value) => '"${value.toString().replaceAll('"', '""')}"';
  final rows = [
    [
      'Part #',
      'Nombre',
      'Categoría',
      'Ubicación',
      'Serial',
      'Stock',
      'Stock mínimo',
      'Condición',
      'Estatus',
    ],
    for (final part in parts)
      [
        part.partNumber,
        part.description,
        part.category,
        part.location,
        part.serialNumber,
        part.quantity,
        part.minStock,
        part.condition,
        PartStatus.of(part).label,
      ],
  ];
  return rows.map((row) => row.map(cell).join(',')).join('\r\n');
}

enum _ExportFormat { csv, pdf }

// ============================================================================
// CABECERA
// ============================================================================

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.parts,
    required this.onAdd,
    required this.onSignOut,
  });

  final AppUser? user;
  final List<HeavyPart> parts;
  final VoidCallback onAdd;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final units = parts.fold<int>(0, (total, part) => total + part.quantity);
    final critical = parts
        .where((p) => PartStatus.of(p) == PartStatus.critical)
        .length;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Panel General de Inventario'),
              TextSpan(
                text: '  $_kAppVersion',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _kMuted,
                ),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _kText,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${parts.length} referencias · $units unidades · '
          '$critical en estado crítico',
          style: const TextStyle(fontSize: 12.5, color: _kMuted),
        ),
      ],
    );

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (user != null) _UserChip(user: user!),
        IconButton(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout, color: _kMuted, size: 20),
          tooltip: 'Cerrar sesión',
        ),
        OutlinedButton.icon(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            backgroundColor: _kPanelAlt,
            foregroundColor: _kText,
            side: const BorderSide(color: _kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.add, size: 18, color: _kAmber),
          label: const Text('Añadir nuevo repuesto'),
        ),
      ],
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [title, actions],
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
    decoration: BoxDecoration(
      color: _kPanel,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _kBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: _kAmber,
          child: Text(
            user.initials,
            style: const TextStyle(
              color: Color(0xFF1F1408),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.displayName,
              style: const TextStyle(
                color: _kText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              user.role.label,
              style: const TextStyle(color: _kMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

// ============================================================================
// FILTROS
// ============================================================================

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.parts,
    required this.location,
    required this.category,
    required this.status,
    required this.searchController,
    required this.selectedCount,
    required this.onLocationChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onQueryChanged,
    required this.onClearFilters,
    required this.onExport,
    required this.onDeleteSelected,
  });

  final List<HeavyPart> parts;

  /// Ancho de cada filtro; en pantallas estrechas caben dos por fila.
  static double _fieldWidth(double available) =>
      available < 480 ? (available - AppSpacing.md) / 2 : 180;
  final String? location;
  final String? category;
  final PartStatus? status;
  final TextEditingController searchController;
  final int selectedCount;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<PartStatus?> onStatusChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<_ExportFormat> onExport;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final locations = {for (final p in parts) p.location}.toList()..sort();
    final categories = {for (final p in parts) p.category}.toList()..sort();
    final hasFilters =
        location != null ||
        category != null ||
        status != null ||
        searchController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = _fieldWidth(constraints.maxWidth);
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _FilterGroup(
                label: 'Ubicación',
                child: _FilterDropdown<String>(
                  width: fieldWidth,
                  value: location,
                  allLabel: 'Todas',
                  items: {for (final l in locations) l: l},
                  onChanged: onLocationChanged,
                ),
              ),
              _FilterGroup(
                label: 'Categoría',
                child: _FilterDropdown<String>(
                  width: fieldWidth,
                  value: category,
                  allLabel: 'Todas',
                  items: {for (final c in categories) c: c},
                  onChanged: onCategoryChanged,
                ),
              ),
              _FilterGroup(
                label: 'Estado',
                child: _FilterDropdown<PartStatus>(
                  width: fieldWidth,
                  value: status,
                  allLabel: 'Todos',
                  items: {for (final s in PartStatus.values) s: s.label},
                  onChanged: onStatusChanged,
                ),
              ),
              _FilterGroup(
                label: 'Buscar',
                child: SizedBox(
                  width: fieldWidth,
                  height: 36,
                  child: TextField(
                    controller: searchController,
                    onChanged: onQueryChanged,
                    style: const TextStyle(color: _kText, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Part #, nombre o serial',
                      hintStyle: const TextStyle(
                        color: _kMuted,
                        fontSize: 12.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 18,
                        color: _kMuted,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 34),
                      filled: true,
                      fillColor: _kInputBg,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(color: _kAmber),
                      ),
                    ),
                  ),
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Limpiar'),
                  style: TextButton.styleFrom(foregroundColor: _kAmberSoft),
                ),
              if (selectedCount > 0)
                TextButton.icon(
                  onPressed: onDeleteSelected,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Eliminar ($selectedCount)'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9EA3),
                  ),
                ),
              PopupMenuButton<_ExportFormat>(
                tooltip: selectedCount > 0
                    ? 'Exportar seleccionados'
                    : 'Exportar repuestos filtrados',
                onSelected: onExport,
                color: _kPanelAlt,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _ExportFormat.csv,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.table_view_outlined),
                      title: Text('Exportar CSV'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ExportFormat.pdf,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Imprimir / Guardar PDF'),
                    ),
                  ),
                ],
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E9EE),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.file_download_outlined,
                        size: 18,
                        color: Color(0xFF1A2231),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedCount > 0
                            ? 'Exportar ($selectedCount)'
                            : 'Exportar (PDF/CSV)',
                        style: const TextStyle(
                          color: Color(0xFF1A2231),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _kText,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.value,
    required this.allLabel,
    required this.items,
    required this.onChanged,
  });

  final double width;
  final T? value;
  final String allLabel;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: _kInputBg,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: value == null ? _kBorder : _kAmber),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T?>(
        value: items.containsKey(value) ? value : null,
        isExpanded: true,
        dropdownColor: _kPanelAlt,
        iconEnabledColor: _kMuted,
        style: const TextStyle(
          color: _kText,
          fontSize: 13,
          fontFamily: 'Roboto',
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
          for (final entry in items.entries)
            DropdownMenuItem<T?>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}

// ============================================================================
// TABLA (escritorio)
// ============================================================================

class _PartsTable extends StatelessWidget {
  const _PartsTable({
    required this.parts,
    required this.placeholder,
    required this.selectedIds,
    required this.detailId,
    required this.onToggleSelected,
    required this.onToggleAll,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<HeavyPart> parts;

  /// Estado de carga, error o vacio; si no es null sustituye a las filas.
  final Widget? placeholder;
  final Set<String> selectedIds;
  final String? detailId;
  final ValueChanged<String> onToggleSelected;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<HeavyPart> onOpen;
  final ValueChanged<HeavyPart> onEdit;
  final ValueChanged<HeavyPart> onDelete;

  @override
  Widget build(BuildContext context) {
    final selectedVisible = parts
        .where((p) => selectedIds.contains(p.id))
        .length;
    final bool? allState = selectedVisible == 0
        ? false
        : selectedVisible == parts.length
        ? true
        : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _kPanelAlt,
            height: 44,
            child: _TableRowLayout(
              checkbox: Checkbox(
                tristate: true,
                value: allState,
                onChanged: parts.isEmpty
                    ? null
                    : (_) => onToggleAll(allState != true),
              ),
              thumb: const _HeaderText('Thumb'),
              partNumber: const _HeaderText('Part #'),
              name: const _HeaderText('Nombre'),
              category: const _HeaderText('Cat'),
              location: const _HeaderText('Loc.'),
              serial: const _HeaderText('Serial'),
              stock: const _HeaderText('Stock'),
              status: const _HeaderText('Estatus'),
              actions: const SizedBox.shrink(),
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child:
                placeholder ??
                ListView.separated(
                  itemCount: parts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: _kBorder),
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    return _PartRow(
                      part: part,
                      selected: selectedIds.contains(part.id),
                      highlighted: part.id == detailId,
                      onToggleSelected: () => onToggleSelected(part.id),
                      onOpen: () => onOpen(part),
                      onEdit: () => onEdit(part),
                      onDelete: () => onDelete(part),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

/// Reparto de columnas comun a cabecera y filas.
class _TableRowLayout extends StatelessWidget {
  const _TableRowLayout({
    required this.checkbox,
    required this.thumb,
    required this.partNumber,
    required this.name,
    required this.category,
    required this.location,
    required this.serial,
    required this.stock,
    required this.status,
    required this.actions,
  });

  final Widget checkbox;
  final Widget thumb;
  final Widget partNumber;
  final Widget name;
  final Widget category;
  final Widget location;
  final Widget serial;
  final Widget stock;
  final Widget status;
  final Widget actions;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 44, child: Center(child: checkbox)),
      SizedBox(width: 56, child: thumb),
      Expanded(flex: 16, child: partNumber),
      Expanded(flex: 20, child: name),
      Expanded(flex: 12, child: category),
      Expanded(flex: 12, child: location),
      Expanded(flex: 12, child: serial),
      SizedBox(width: 72, child: stock),
      SizedBox(width: 112, child: status),
      SizedBox(width: 120, child: actions),
    ],
  );
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _kMuted,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _CellText extends StatelessWidget {
  const _CellText(this.text, {this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Text(
      text.isEmpty ? '—' : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: strong ? _kText : const Color(0xFFC9D3DF),
        fontSize: 13,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}

class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.part,
    required this.selected,
    required this.highlighted,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final HeavyPart part;
  final bool selected;
  final bool highlighted;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: highlighted || selected ? _kRowSelected : Colors.transparent,
    child: InkWell(
      onTap: onOpen,
      hoverColor: const Color(0xFF1B2638),
      child: SizedBox(
        height: 60,
        child: _TableRowLayout(
          checkbox: Checkbox(
            value: selected,
            onChanged: (_) => onToggleSelected(),
          ),
          thumb: Align(
            alignment: Alignment.centerLeft,
            child: _PartThumb(part: part, size: 42),
          ),
          partNumber: _CellText(part.partNumber, strong: true),
          name: _CellText(part.description),
          category: _CellText(part.category),
          location: _CellText(part.location),
          serial: _CellText(part.serialNumber),
          stock: Tooltip(
            message: 'Mínimo: ${part.minStock}',
            child: _CellText('${part.quantity}'),
          ),
          status: Align(
            alignment: Alignment.centerLeft,
            child: _StatusBadge(status: PartStatus.of(part)),
          ),
          actions: _RowActions(
            part: part,
            onOpen: onOpen,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      ),
    ),
  );
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.part,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final HeavyPart part;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onEdit,
        tooltip: 'Editar ${part.partNumber}',
        icon: const Icon(Icons.edit_outlined, size: 19, color: _kMuted),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onDelete,
        tooltip: 'Eliminar ${part.partNumber}',
        icon: const Icon(Icons.delete_outline, size: 19, color: _kMuted),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onOpen,
        tooltip: 'Ver ficha de ${part.partNumber}',
        icon: const Icon(Icons.description_outlined, size: 19, color: _kAmber),
      ),
    ],
  );
}

// ============================================================================
// TARJETA (movil)
// ============================================================================

class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.part,
    required this.selected,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final HeavyPart part;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _kRowSelected : _kGlass,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: selected ? _kAmber : _kBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      onLongPress: onToggleSelected,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PartThumb(part: part, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.partNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        part.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _kMuted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          part.category,
                          part.location,
                          if (part.serialNumber.isNotEmpty) part.serialNumber,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC9D3DF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(status: PartStatus.of(part)),
                      const SizedBox(height: 8),
                      Text(
                        'Stock ${part.quantity}',
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(value: selected, onChanged: (_) => onToggleSelected()),
                const Spacer(),
                _RowActions(
                  part: part,
                  onOpen: onOpen,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// PANEL DE DETALLE
// ============================================================================

class _PartDetail extends ConsumerWidget {
  const _PartDetail({
    required this.part,
    required this.onClose,
    required this.onEdit,
  });

  final HeavyPart part;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(partMovementsProvider(part.id));
    final status = PartStatus.of(part);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Detalle del Componente',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined, size: 19, color: _kMuted),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Cerrar detalle',
                icon: const Icon(Icons.close, size: 20, color: _kMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _DetailGallery(part: part),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      part.partNumber,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                part.description,
                style: const TextStyle(color: _kMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _DetailGrid(
                entries: {
                  'Categoría': part.category,
                  'Ubicación': part.location,
                  'Serial': part.serialNumber.isEmpty ? '—' : part.serialNumber,
                  'Condición': part.condition,
                  'Stock': '${part.quantity}',
                  'Stock mínimo': '${part.minStock}',
                },
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Historial de movimientos'),
              const SizedBox(height: 8),
              movements.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kAmber,
                      ),
                    ),
                  ),
                ),
                error: (_, _) => Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'No se pudo cargar el historial.',
                        style: TextStyle(color: _kMuted, fontSize: 12.5),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(partMovementsProvider(part.id)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                data: (items) => items.isEmpty
                    ? const Text(
                        'Sin movimientos registrados.',
                        style: TextStyle(color: _kMuted, fontSize: 12.5),
                      )
                    : Column(
                        children: [
                          for (final movement in items.take(8))
                            _MovementTile(movement: movement),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle('Certificado EASA Form 1'),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.verified_outlined, size: 18, color: _kMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sin certificado adjunto a este componente.',
                      style: TextStyle(color: _kMuted, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailGallery extends StatefulWidget {
  const _DetailGallery({required this.part});

  final HeavyPart part;

  @override
  State<_DetailGallery> createState() => _DetailGalleryState();
}

class _DetailGalleryState extends State<_DetailGallery> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _DetailGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.part.id != widget.part.id) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.part.imagesBase64;
    final index = _index.clamp(0, images.isEmpty ? 0 : images.length - 1);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: images.isEmpty
                ? const _ImagePlaceholder(iconSize: 56)
                : _Base64Image(images[index]),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 48,
                      height: 48,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: i == index ? _kAmber : _kBorder,
                          width: i == index ? 2 : 1,
                        ),
                      ),
                      child: _Base64Image(images[i]),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.entries});

  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) => Wrap(
    runSpacing: 10,
    children: [
      for (final entry in entries.entries)
        FractionallySizedBox(
          widthFactor: 0.5,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(color: _kMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _kText,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final date = movement.createdAt;
    final (IconData icon, Color color) = switch (movement.type) {
      'entry' => (Icons.south_west, const Color(0xFF9BE8B5)),
      'exit' => (Icons.north_east, const Color(0xFFFF9EA3)),
      _ => (Icons.tune, _kAmberSoft),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${movement.typeLabel}: ${movement.previousStock} → '
                  '${movement.newStock}',
                  style: const TextStyle(color: _kText, fontSize: 12.5),
                ),
                if (movement.reason != null && movement.reason!.isNotEmpty)
                  Text(
                    movement.reason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kMuted, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          if (date != null)
            Text(
              DateFormat('dd/MM/yy HH:mm').format(date.toLocal()),
              style: const TextStyle(color: _kMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// PIEZAS COMUNES
// ============================================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PartStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: status.background,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: status.foreground.withValues(alpha: 0.35)),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: status.foreground,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _PartThumb extends StatelessWidget {
  const _PartThumb({required this.part, required this.size});

  final HeavyPart part;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _kBorder),
    ),
    child: part.imagesBase64.isEmpty
        ? const _ImagePlaceholder(iconSize: 20)
        : _Base64Image(part.imagesBase64.first),
  );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _kPanelAlt,
    child: Center(
      child: Icon(
        Icons.precision_manufacturing_outlined,
        size: iconSize,
        color: _kMuted,
      ),
    ),
  );
}

/// Imagen en base64 con los bytes decodificados en cache, para no repetir la
/// decodificacion en cada reconstruccion de la tabla.
class _Base64Image extends StatelessWidget {
  const _Base64Image(this.data);

  final String data;

  static final Map<String, Uint8List> _cache = {};

  static Uint8List? _decode(String data) {
    final cached = _cache[data];
    if (cached != null) return cached;
    try {
      final bytes = base64Decode(data);
      if (_cache.length > 200) _cache.remove(_cache.keys.first);
      return _cache[data] = bytes;
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(data);
    if (bytes == null) return const _ImagePlaceholder(iconSize: 20);
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const _ImagePlaceholder(iconSize: 20),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: child),
  );
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _CenteredMessage(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 44, color: _kMuted),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kMuted, fontSize: 13),
        ),
        ?action,
      ],
    ),
  );
}

class _InventoryLoadError extends StatelessWidget {
  const _InventoryLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CenteredMessage(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 44, color: _kMuted),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No se pudo cargar el inventario: $message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kText, fontSize: 13.5),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

// ============================================================================
// BARRA INFERIOR
// ============================================================================

class _FooterBar extends StatelessWidget {
  const _FooterBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
    decoration: const BoxDecoration(
      color: _kPanel,
      border: Border(top: BorderSide(color: _kBorder)),
    ),
    child: Row(
      children: [
        // En pantallas estrechas el espacio es para los botones de descarga.
        if (!compact)
          const Expanded(
            child: Text(
              'Entorno de demostración $_kAppVersion',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _kMuted, fontSize: 11),
            ),
          ),
        Flexible(
          flex: 3,
          child: AppDownloadButtons(compact: compact, foreground: _kAmberSoft),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton(
          onPressed: () => _showSupport(context),
          style: TextButton.styleFrom(foregroundColor: _kText),
          child: const Text('Soporte'),
        ),
      ],
    ),
  );

  void _showSupport(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.support_agent_outlined),
      title: const Text('Soporte'),
      content: const Text(
        'Para asistencia técnica, altas de usuarios o problemas con el '
        'inventario, contacta al administrador del sistema.\n\n'
        'AeroParts $_kAppVersion',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

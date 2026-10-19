import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:aviation_inventory/core/network/api_client.dart';
import 'package:aviation_inventory/features/inventory/data/datasources/remote_category_data_source.dart';
import 'package:aviation_inventory/features/inventory/data/datasources/remote_heavy_part_data_source.dart';
import 'package:aviation_inventory/features/inventory/domain/entities/heavy_part.dart';
import 'package:aviation_inventory/features/inventory/domain/entities/stock_movement.dart';
import 'package:aviation_inventory/features/inventory/presentation/providers/category_provider.dart';
import 'package:aviation_inventory/features/inventory/presentation/providers/heavy_inventory_provider.dart';

/// Inventario en memoria: evita llamadas HTTP reales en los tests de widgets
/// (que ademas nunca completan dentro del reloj falso de `flutter_test`).
class FakeHeavyPartDataSource implements RemoteHeavyPartDataSource {
  FakeHeavyPartDataSource([List<HeavyPart> initialParts = const []])
    : parts = [...initialParts];

  final List<HeavyPart> parts;
  final List<StockMovement> movements = [];
  int _nextId = 1000;

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  RemoteCategoryDataSource get categoryDataSource =>
      throw UnimplementedError();

  @override
  Future<List<HeavyPart>> loadParts() async => [...parts];

  @override
  Future<HeavyPart> addPart(HeavyPart part) async {
    final created = part.copyWith(id: '${_nextId++}');
    parts.add(created);
    return created;
  }

  @override
  Future<void> updatePart(HeavyPart part, {int? previousQuantity}) async {
    final index = parts.indexWhere((p) => p.id == part.id);
    if (index >= 0) parts[index] = part;
  }

  @override
  Future<void> removePart(String id) async =>
      parts.removeWhere((p) => p.id == id);

  @override
  Future<List<StockMovement>> loadMovements(String id) async => movements;
}

class FakeCategoryDataSource implements RemoteCategoryDataSource {
  final List<String> categories = ['General', 'Motor', 'Aviónica'];

  @override
  Future<List<String>> getCategories() async => [...categories];

  @override
  Future<int?> getCategoryIdByName(String name) async =>
      categories.indexOf(name);

  @override
  Future<bool> addCategory(String category) async {
    if (categories.contains(category)) return false;
    categories.add(category);
    return true;
  }

  @override
  Future<bool> removeCategory(String category) async =>
      categories.remove(category);
}

/// Overrides de Riverpod para montar el dashboard sin backend.
List<Override> inventoryOverrides([FakeHeavyPartDataSource? parts]) => [
  heavyPartDataSourceProvider.overrideWithValue(
    parts ?? FakeHeavyPartDataSource(),
  ),
  categoryDataSourceProvider.overrideWithValue(FakeCategoryDataSource()),
];

HeavyPart samplePart({
  String id = '1',
  String partNumber = 'CYL-HEAD-A2',
  String description = 'Cabeza Cilindro',
  int quantity = 25,
  int minStock = 5,
  String location = 'Almacén A',
  String category = 'Motor',
  String condition = 'Disponible',
}) => HeavyPart(
  id: id,
  partNumber: partNumber,
  description: description,
  quantity: quantity,
  minStock: minStock,
  location: location,
  category: category,
  condition: condition,
  serialNumber: 'SN-$id',
);

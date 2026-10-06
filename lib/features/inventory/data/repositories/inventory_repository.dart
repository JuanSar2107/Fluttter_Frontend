import '../../domain/entities/inventory_item.dart';
import '../datasources/mock_inventory_data_source.dart';

/// Repositorio de inventario.
///
/// Abstracción para que la UI no dependa de la fuente de datos concreta.
class InventoryRepository {
  InventoryRepository({MockInventoryDataSource? dataSource})
      : _dataSource = dataSource ?? MockInventoryDataSource.instance;

  final MockInventoryDataSource _dataSource;

  List<InventoryItem> getAll() => _dataSource.getAll();

  InventoryItem? getById(String id) => _dataSource.getById(id);

  InventoryItem? getByPartNumber(String partNumber) =>
      _dataSource.getByPartNumber(partNumber);

  List<InventoryItem> getByCategory(PartCategory category) =>
      _dataSource.getByCategory(category);

  List<InventoryItem> getLowStock() => _dataSource.getLowStock();

  List<InventoryItem> getOutOfStock() => _dataSource.getOutOfStock();

  void addItem(InventoryItem item) => _dataSource.addItem(item);

  bool updateStock(String id, int newStock) => _dataSource.updateStock(id, newStock);
}
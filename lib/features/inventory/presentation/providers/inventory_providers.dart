import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/inventory_repository.dart';

/// Proveedor del repositorio de inventario.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});
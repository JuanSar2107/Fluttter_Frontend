import '../../domain/entities/inventory_item.dart';

/// Fuente de datos de inventario de mentira para desarrollo.
///
/// En producción esto vendría de un repositorio que hable con API/BD.
class MockInventoryDataSource {
  MockInventoryDataSource._();

  static final MockInventoryDataSource instance = MockInventoryDataSource._();

  /// Lista de items de ejemplo con imágenes placeholder.
  ///
  /// Las imágenes usan `via.placeholder.com` para tener visuales reales
  /// durante el desarrollo. En producción se usarían URLs de CDN/S3.
  final List<InventoryItem> items = [
    InventoryItem(
      id: 'inv-001',
      partNumber: '161-500-001-001',
      description: 'Panel de control principal - Boeing 737',
      category: PartCategory.avionica,
      condition: PartCondition.nuevo,
      stock: 3,
      minStock: 2,
      location: 'A-01-01',
      manufacturer: 'Honeywell',
      serialNumbers: ['SN-161500001001', 'SN-161500001002', 'SN-161500001003'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/FF9F1C?text=Panel+Control+737',
      certificates: ['EASA Form 1', '8130-3'],
      lastUpdated: DateTime(2026, 9, 15),
      notes: 'Compatible con 737NG y MAX. Requiere calibración post-instalación.',
    ),
    InventoryItem(
      id: 'inv-002',
      partNumber: '331-456-901-001',
      description: 'Unidad de potencia auxiliar (APU) GTCP131-9B',
      category: PartCategory.motor,
      condition: PartCondition.reparado,
      stock: 1,
      minStock: 1,
      location: 'B-05-12',
      manufacturer: 'Honeywell',
      serialNumbers: ['P-12345'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/12B886?text=APU+GTCP131-9B',
      certificates: ['EASA Form 1', '8130-3', 'Certificado de reparación'],
      lastUpdated: DateTime(2026, 8, 22),
      notes: 'Reparado por Honeywell MRO Madrid. Testado en banco certificado.',
    ),
    InventoryItem(
      id: 'inv-003',
      partNumber: '273-200-005-001',
      description: 'Actuador hidráulico de flap - Airbus A320',
      category: PartCategory.hidraulica,
      condition: PartCondition.revisado,
      stock: 5,
      minStock: 3,
      location: 'C-03-07',
      manufacturer: 'Parker Aerospace',
      serialNumbers: ['HYD-001', 'HYD-002', 'HYD-003', 'HYD-004', 'HYD-005'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/F59F00?text=Actuador+Flap+A320',
      certificates: ['EASA Form 1'],
      lastUpdated: DateTime(2026, 9, 10),
      notes: 'Revisado según CMM 27-30-05. Incluye kit de juntas.',
    ),
    InventoryItem(
      id: 'inv-004',
      partNumber: '162-110-300-001',
      description: 'Sensor de ángulo de ataque (AOA) - Boeing 787',
      category: PartCategory.instrumentacion,
      condition: PartCondition.nuevo,
      stock: 0,
      minStock: 2,
      location: 'A-02-15',
      manufacturer: 'Rosemount Aerospace',
      serialNumbers: [],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/E03131?text=Sensor+AOA+787',
      certificates: ['EASA Form 1', '8130-3'],
      lastUpdated: DateTime(2026, 7, 30),
      notes: 'PEDIDO PENDIENTE - ETA 2 semanas. Crítico para vuelo.',
    ),
    InventoryItem(
      id: 'inv-005',
      partNumber: '561-700-001-001',
      description: 'Ventana de cabina lado capitán - Airbus A350',
      category: PartCategory.estructura,
      condition: PartCondition.nuevo,
      stock: 2,
      minStock: 1,
      location: 'D-01-01 (Oversize)',
      manufacturer: 'GKN Aerospace',
      serialNumbers: ['WIN-A350-001', 'WIN-A350-002'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/FFFFFF?text=Ventana+Cabina+A350',
      certificates: ['EASA Form 1', 'Certificado de conformidad'],
      lastUpdated: DateTime(2026, 9, 1),
      notes: 'Calefactada, anti-hielo. Incluye marco y sellos.',
    ),
    InventoryItem(
      id: 'inv-006',
      partNumber: '321-400-001-001',
      description: 'Amortiguador principal tren aterrizaje - Boeing 777',
      category: PartCategory.trenAterrizaje,
      condition: PartCondition.reparado,
      stock: 4,
      minStock: 2,
      location: 'E-10-05',
      manufacturer: 'Goodrich / Safran',
      serialNumbers: ['LG-777-001', 'LG-777-002', 'LG-777-003', 'LG-777-004'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/FF9F1C?text=Amortiguador+777',
      certificates: ['EASA Form 1', '8130-3'],
      lastUpdated: DateTime(2026, 8, 15),
      notes: 'Reparado por Safran Landing Systems. Incluye nitrógeno cargado.',
    ),
    InventoryItem(
      id: 'inv-007',
      partNumber: '252-000-001-001',
      description: 'Extintor portátil cabina - Halon 1211',
      category: PartCategory.interior,
      condition: PartCondition.nuevo,
      stock: 12,
      minStock: 8,
      location: 'F-02-03',
      manufacturer: 'Kidde Aerospace',
      serialNumbers: [],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/12B886?text=Extintor+Halon',
      certificates: ['EASA Form 1'],
      lastUpdated: DateTime(2026, 9, 20),
      notes: 'Vida útil 10 años. Requiere recarga a los 5 años.',
    ),
    InventoryItem(
      id: 'inv-008',
      partNumber: '241-500-001-001',
      description: 'Generador eléctrico 90kVA - Airbus A330',
      category: PartCategory.electrico,
      condition: PartCondition.revisado,
      stock: 2,
      minStock: 1,
      location: 'B-03-08',
      manufacturer: 'Thales',
      serialNumbers: ['GEN-90-001', 'GEN-90-002'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/F59F00?text=Generador+90kVA',
      certificates: ['EASA Form 1'],
      lastUpdated: DateTime(2026, 8, 5),
      notes: 'Revisado según CMM 24-20-01. Brushless, refrigerado por aceite.',
    ),
    InventoryItem(
      id: 'inv-009',
      partNumber: '731-000-001-001',
      description: 'Unidad de gestión de combustible (FMU) - CFM56',
      category: PartCategory.motor,
      condition: PartCondition.reparado,
      stock: 1,
      minStock: 1,
      location: 'B-04-02',
      manufacturer: 'Woodward',
      serialNumbers: ['FMU-CFM-001'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/FFFFFF?text=FMU+CFM56',
      certificates: ['EASA Form 1', '8130-3'],
      lastUpdated: DateTime(2026, 6, 28),
      notes: 'Reparado por Woodward MRO. Calibrado en banco de prueba.',
    ),
    InventoryItem(
      id: 'inv-010',
      partNumber: '272-100-001-001',
      description: 'Válvula de prioridad hidráulica - Embraer E190',
      category: PartCategory.hidraulica,
      condition: PartCondition.usado,
      stock: 3,
      minStock: 2,
      location: 'C-01-11',
      manufacturer: 'Eaton Aerospace',
      serialNumbers: ['HV-E190-001', 'HV-E190-002', 'HV-E190-003'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/FF9F1C?text=Valvula+Prioridad+E190',
      certificates: ['EASA Form 1'],
      lastUpdated: DateTime(2026, 5, 12),
      notes: 'Condición usado - funcional. Requiere prueba de presión antes de instalar.',
    ),
    InventoryItem(
      id: 'inv-011',
      partNumber: '341-200-001-001',
      description: 'Indicador de actitud (ADI) - EFIS Boeing 747',
      category: PartCategory.instrumentacion,
      condition: PartCondition.revisado,
      stock: 2,
      minStock: 1,
      location: 'A-03-04',
      manufacturer: 'Rockwell Collins',
      serialNumbers: ['ADI-747-001', 'ADI-747-002'],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/12B886?text=ADI+EFIS+747',
      certificates: ['EASA Form 1'],
      lastUpdated: DateTime(2026, 9, 5),
      notes: 'Versión EFIS color. Compatible con 747-400/8.',
    ),
    InventoryItem(
      id: 'inv-012',
      partNumber: '381-000-001-001',
      description: 'Válvula de llenado agua potable - Airbus A321',
      category: PartCategory.interior,
      condition: PartCondition.nuevo,
      stock: 6,
      minStock: 3,
      location: 'F-01-05',
      manufacturer: 'Zodiac Aerospace',
      serialNumbers: [],
      imageUrl: 'https://via.placeholder.com/300x200/0B2239/F59F00?text=Valvula+Agua+A321',
      certificates: ['EASA Form 1'],
      lastUpdated: DateTime(2026, 9, 18),
      notes: 'Incluye filtro y regulador de presión.',
    ),
  ];

  /// Obtiene todos los items.
  List<InventoryItem> getAll() => List.unmodifiable(items);

  /// Busca por ID.
  InventoryItem? getById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Busca por número de parte.
  InventoryItem? getByPartNumber(String partNumber) {
    try {
      return items.firstWhere(
        (item) => item.partNumber == partNumber,
      );
    } catch (_) {
      return null;
    }
  }

  /// Filtra por categoría.
  List<InventoryItem> getByCategory(PartCategory category) =>
      items.where((item) => item.category == category).toList();

  /// Items con stock bajo.
  List<InventoryItem> getLowStock() =>
      items.where((item) => item.isLowStock).toList();

  /// Items sin stock.
  List<InventoryItem> getOutOfStock() =>
      items.where((item) => item.isOutOfStock).toList();

  /// Agrega un item (para el botón "Agregar objeto nuevo").
  void addItem(InventoryItem item) {
    items.add(item);
  }

  /// Actualiza stock de un item.
  bool updateStock(String id, int newStock) {
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) return false;
    items[index] = items[index].copyWith(stock: newStock, lastUpdated: DateTime.now());
    return true;
  }
}
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/heavy_part.dart';
import '../../domain/entities/stock_movement.dart';
import 'remote_category_data_source.dart';

class RemoteHeavyPartDataSource {
  RemoteHeavyPartDataSource({
    required this.apiClient,
    required this.categoryDataSource,
  });

  final ApiClient apiClient;
  final RemoteCategoryDataSource categoryDataSource;

  HeavyPart _fromBackendJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final partNumber = json['sku'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final quantity = (json['stock_quantity'] as num?)?.toInt() ?? 0;
    final minStock = (json['min_stock'] as num?)?.toInt() ?? 1;
    final categoryMap = json['category'] as Map<String, dynamic>?;
    final categoryName = categoryMap?['name'] as String? ?? 'General';

    String descriptionText = name;
    String location = 'Almacén Principal';
    String condition = 'Disponible';
    String serialNumber = '';
    List<String> images = const [];

    final rawDesc = json['description'] as String?;
    if (rawDesc != null && rawDesc.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDesc);
        if (decoded is Map<String, dynamic>) {
          descriptionText = decoded['desc'] as String? ?? name;
          location = decoded['location'] as String? ?? location;
          condition = decoded['condition'] as String? ?? condition;
          serialNumber = decoded['sn'] as String? ?? '';
          images =
              (decoded['imgs'] as List<dynamic>?)?.cast<String>() ?? const [];
        }
      } catch (_) {
        descriptionText = rawDesc;
      }
    }

    return HeavyPart(
      id: id,
      partNumber: partNumber,
      description: descriptionText,
      quantity: quantity,
      location: location,
      condition: condition,
      category: categoryName,
      serialNumber: serialNumber,
      imagesBase64: images,
      minStock: minStock,
    );
  }

  Future<List<HeavyPart>> loadParts() async {
    final data = await apiClient.get('/api/products');
    if (data is List) {
      return data
          .map((item) => _fromBackendJson(item as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const [];
  }

  Future<HeavyPart> addPart(HeavyPart part) async {
    final categoryId = await categoryDataSource.getCategoryIdByName(
      part.category,
    );

    final metaJson = jsonEncode({
      'desc': part.description,
      'location': part.location,
      'condition': part.condition,
      'sn': part.serialNumber,
      'imgs': part.imagesBase64,
    });

    final payload = <String, dynamic>{
      'name': part.description.isNotEmpty ? part.description : part.partNumber,
      'sku': part.partNumber,
      'description': metaJson,
      'category_id': ?categoryId,
      'stock_quantity': part.quantity,
      'min_stock': part.minStock,
      'price': 0.0,
      'cost': 0.0,
      'unit': 'unidad',
    };

    final created = await apiClient.post('/api/products', body: payload);
    return _fromBackendJson(created as Map<String, dynamic>);
  }

  /// Actualiza el repuesto. El ajuste de existencias solo se registra si la
  /// cantidad cambio respecto a [previousQuantity], para no llenar el
  /// historial de movimientos con ajustes vacios.
  Future<void> updatePart(HeavyPart part, {int? previousQuantity}) async {
    final productId = int.tryParse(part.id);
    if (productId == null) return;

    final categoryId = await categoryDataSource.getCategoryIdByName(
      part.category,
    );

    final metaJson = jsonEncode({
      'desc': part.description,
      'location': part.location,
      'condition': part.condition,
      'sn': part.serialNumber,
      'imgs': part.imagesBase64,
    });

    final payload = <String, dynamic>{
      'name': part.description.isNotEmpty ? part.description : part.partNumber,
      'sku': part.partNumber,
      'description': metaJson,
      'category_id': ?categoryId,
      'min_stock': part.minStock,
    };

    await apiClient.put('/api/products/$productId', body: payload);

    // Sincronizar existencia mediante movimiento de inventario si aplica
    if (previousQuantity == part.quantity) return;
    try {
      await apiClient.post(
        '/api/inventory/movements',
        body: {
          'product_id': productId,
          'movement_type': 'adjustment',
          'quantity': part.quantity,
          'reason': 'Ajuste desde frontend',
        },
      );
    } catch (_) {}
  }

  /// Historial de movimientos de un repuesto, del mas reciente al mas antiguo.
  Future<List<StockMovement>> loadMovements(String id) async {
    final productId = int.tryParse(id);
    if (productId == null) return const [];
    final data = await apiClient.get(
      '/api/inventory/movements',
      queryParameters: {'product_id': productId, 'limit': 20},
    );
    if (data is! List) return const [];
    final movements = data
        .whereType<Map<String, dynamic>>()
        .map(StockMovement.fromJson)
        .toList();
    movements.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(0);
      final bDate = b.createdAt ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return movements;
  }

  Future<void> removePart(String id) async {
    final productId = int.tryParse(id);
    if (productId == null) return;

    await apiClient.delete('/api/products/$productId');
  }
}

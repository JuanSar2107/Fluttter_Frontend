import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/heavy_part.dart';
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
          images = (decoded['imgs'] as List<dynamic>?)?.cast<String>() ?? const [];
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
    final categoryId = await categoryDataSource.getCategoryIdByName(part.category);

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
      'min_stock': 1,
      'price': 0.0,
      'cost': 0.0,
      'unit': 'unidad',
    };

    final created = await apiClient.post('/api/products', body: payload);
    return _fromBackendJson(created as Map<String, dynamic>);
  }

  Future<void> updatePart(HeavyPart part) async {
    final productId = int.tryParse(part.id);
    if (productId == null) return;

    final categoryId = await categoryDataSource.getCategoryIdByName(part.category);

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
    };

    await apiClient.put('/api/products/$productId', body: payload);

    // Sincronizar existencia mediante movimiento de inventario si aplica
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

  Future<void> removePart(String id) async {
    final productId = int.tryParse(id);
    if (productId == null) return;

    await apiClient.delete('/api/products/$productId');
  }
}

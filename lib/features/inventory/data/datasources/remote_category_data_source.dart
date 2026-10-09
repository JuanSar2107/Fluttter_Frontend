import '../../../../core/network/api_client.dart';

class RemoteCategoryDataSource {
  RemoteCategoryDataSource(this._apiClient);

  final ApiClient _apiClient;

  static const List<String> defaultCategories = [
    'Estructura',
    'Motor',
    'Aviónica',
    'Hidráulica',
    'Tren de aterrizaje',
    'Interior',
    'Eléctrico',
    'Instrumentación',
    'General',
  ];

  /// Cache en memoria de mapeo nombre -> id
  final Map<String, int> _categoryIds = {};

  Future<List<String>> getCategories() async {
    try {
      final data = await _apiClient.get('/api/categories');
      if (data is List) {
        final list = <String>[];
        for (final item in data) {
          if (item is Map) {
            final name = item['name'] as String? ?? '';
            final id = (item['id'] as num?)?.toInt();
            if (name.isNotEmpty) {
              list.add(name);
              if (id != null) {
                _categoryIds[name.toLowerCase()] = id;
              }
            }
          }
        }
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}
    return defaultCategories;
  }

  Future<int?> getCategoryIdByName(String name) async {
    final lower = name.toLowerCase().trim();
    if (_categoryIds.containsKey(lower)) {
      return _categoryIds[lower];
    }

    // Actualizar cache desde el backend
    await getCategories();
    if (_categoryIds.containsKey(lower)) {
      return _categoryIds[lower];
    }

    // Si no existe, crearla automáticamente en el backend
    try {
      final res = await _apiClient.post(
        '/api/categories',
        body: {'name': name, 'description': 'Categoría aeronáutica'},
      );
      if (res is Map && res['id'] != null) {
        final id = (res['id'] as num).toInt();
        _categoryIds[lower] = id;
        return id;
      }
    } catch (_) {}

    return null;
  }

  Future<bool> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return false;

    try {
      final res = await _apiClient.post(
        '/api/categories',
        body: {'name': trimmed, 'description': 'Categoría creada desde app'},
      );
      if (res is Map && res['id'] != null) {
        _categoryIds[trimmed.toLowerCase()] = (res['id'] as num).toInt();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeCategory(String category) async {
    try {
      final id = await getCategoryIdByName(category);
      if (id == null) return false;

      await _apiClient.delete('/api/categories/$id');
      _categoryIds.remove(category.toLowerCase().trim());
      return true;
    } catch (_) {
      return false;
    }
  }
}

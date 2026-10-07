import 'package:shared_preferences/shared_preferences.dart';

/// Almacena y gestiona las categorías de repuestos.
///
/// Las categorías se guardan en SharedPreferences como una lista de strings.
/// Incluye categorías por defecto y permite agregar nuevas (solo admin).
class CategoryDataSource {
  CategoryDataSource(this._preferences);

  final SharedPreferences _preferences;

  static const String _categoriesKey = 'heavy_inventory_categories';

  /// Categorías por defecto que siempre están disponibles.
  static const List<String> _defaultCategories = [
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

  /// Obtiene todas las categorías (por defecto + personalizadas).
  Future<List<String>> getCategories() async {
    final custom = _preferences.getStringList(_categoriesKey) ?? <String>[];
    final all = [..._defaultCategories, ...custom];
    return all;
  }

  /// Agrega una nueva categoría personalizada.
  ///
  /// Retorna `true` si se agregó, `false` si ya existía (case-insensitive).
  Future<bool> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return false;

    final current = await getCategories();
    if (current.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }

    final custom = _preferences.getStringList(_categoriesKey) ?? <String>[];
    custom.add(trimmed);
    await _preferences.setStringList(_categoriesKey, custom);
    return true;
  }

  /// Elimina una categoría personalizada.
  ///
  /// No permite eliminar las categorías por defecto.
  Future<bool> removeCategory(String category) async {
    if (_defaultCategories.contains(category)) return false;

    final custom = _preferences.getStringList(_categoriesKey) ?? <String>[];
    final removed = custom.remove(category);
    if (removed) {
      await _preferences.setStringList(_categoriesKey, custom);
    }
    return removed;
  }

  /// Verifica si una categoría es personalizada (no por defecto).
  bool isCustomCategory(String category) =>
      !_defaultCategories.contains(category);
}
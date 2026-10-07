import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/heavy_part.dart';

class HeavyPartLocalDataSource {
  HeavyPartLocalDataSource(this._preferences);

  static const _storageKey = 'heavy_aircraft_parts';

  final SharedPreferences _preferences;

  List<HeavyPart> loadParts() {
    final storedParts = _preferences.getString(_storageKey);
    if (storedParts == null) return const [];

    final decoded = jsonDecode(storedParts) as List<dynamic>;
    return decoded
        .map((part) => HeavyPart.fromJson(part as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveParts(List<HeavyPart> parts) async {
    final encoded = jsonEncode(parts.map((part) => part.toJson()).toList());
    final saved = await _preferences.setString(_storageKey, encoded);
    if (!saved) {
      throw StateError('No se pudo guardar el inventario en este dispositivo.');
    }
  }
}

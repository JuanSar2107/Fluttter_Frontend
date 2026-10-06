import 'package:flutter/foundation.dart';

/// Categoría del repuesto.
enum PartCategory {
  estructura('Estructura'),
  motor('Motor'),
  avionica('Aviónica'),
  hidraulica('Hidráulica'),
  trenAterrizaje('Tren de aterrizaje'),
  interior('Interior'),
  electrico('Eléctrico'),
  instrumentacion('Instrumentación');

  const PartCategory(this.label);
  final String label;
}

/// Estado del repuesto.
enum PartCondition {
  nuevo('Nuevo'),
  reparado('Reparado'),
  revisado('Revisado'),
  usado('Usado'),
  scrap('Scrap');

  const PartCondition(this.label);
  final String label;
}

/// Ítem de inventario (repuesto aeronáutico).
@immutable
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.partNumber,
    required this.description,
    required this.category,
    required this.condition,
    required this.stock,
    required this.minStock,
    required this.location,
    required this.manufacturer,
    this.serialNumbers = const [],
    this.imageUrl,
    this.certificates = const [],
    this.lastUpdated,
    this.notes,
  });

  /// ID único (UUID).
  final String id;

  /// Número de parte (PN).
  final String partNumber;

  /// Descripción legible.
  final String description;

  /// Categoría funcional.
  final PartCategory category;

  /// Condición del repuesto.
  final PartCondition condition;

  /// Cantidad disponible en stock.
  final int stock;

  /// Stock mínimo para alerta.
  final int minStock;

  /// Ubicación en almacén (ej. "A-12-3").
  final String location;

  /// Fabricante.
  final String manufacturer;

  /// Números de serie (para items serializados).
  final List<String> serialNumbers;

  /// URL de imagen (placeholder o real).
  final String? imageUrl;

  /// Certificados asociados (8130, EASA Form 1, etc.).
  final List<String> certificates;

  /// Última actualización.
  final DateTime? lastUpdated;

  /// Notas adicionales.
  final String? notes;

  /// `true` si el stock está por debajo del mínimo.
  bool get isLowStock => stock <= minStock;

  /// `true` si el item está sin stock.
  bool get isOutOfStock => stock == 0;

  /// Color del estado de stock.
  String get stockStatusLabel {
    if (isOutOfStock) return 'Agotado';
    if (isLowStock) return 'Bajo mínimo';
    return 'Disponible';
  }

  InventoryItem copyWith({
    String? id,
    String? partNumber,
    String? description,
    PartCategory? category,
    PartCondition? condition,
    int? stock,
    int? minStock,
    String? location,
    String? manufacturer,
    List<String>? serialNumbers,
    String? imageUrl,
    List<String>? certificates,
    DateTime? lastUpdated,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      partNumber: partNumber ?? this.partNumber,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      location: location ?? this.location,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumbers: serialNumbers ?? this.serialNumbers,
      imageUrl: imageUrl ?? this.imageUrl,
      certificates: certificates ?? this.certificates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          other.id == id &&
          other.partNumber == partNumber &&
          other.description == description &&
          other.category == category &&
          other.condition == condition &&
          other.stock == stock &&
          other.minStock == minStock &&
          other.location == location &&
          other.manufacturer == manufacturer &&
          listEquals(other.serialNumbers, serialNumbers) &&
          other.imageUrl == imageUrl &&
          listEquals(other.certificates, certificates) &&
          other.lastUpdated == lastUpdated &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        id,
        partNumber,
        description,
        category,
        condition,
        stock,
        minStock,
        location,
        manufacturer,
        Object.hashAll(serialNumbers),
        imageUrl,
        Object.hashAll(certificates),
        lastUpdated,
        notes,
      );

  @override
  String toString() => 'InventoryItem($partNumber - $description, stock: $stock)';
}
/// Movimiento de inventario registrado en el backend
/// (`GET /api/inventory/movements`).
class StockMovement {
  const StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.createdAt,
    this.reason,
  });

  final String id;

  /// `entry`, `exit` o `adjustment`.
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final DateTime? createdAt;
  final String? reason;

  String get typeLabel => switch (type) {
    'entry' => 'Ingreso',
    'exit' => 'Retiro',
    'adjustment' => 'Ajuste',
    _ => type,
  };

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'].toString(),
    type: json['movement_type'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    previousStock: (json['previous_stock'] as num?)?.toInt() ?? 0,
    newStock: (json['new_stock'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    reason: json['reason'] as String?,
  );
}

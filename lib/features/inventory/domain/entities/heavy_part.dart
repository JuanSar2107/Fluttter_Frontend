class HeavyPart {
  const HeavyPart({
    required this.id,
    required this.partNumber,
    required this.description,
    required this.quantity,
    required this.location,
    required this.condition,
    required this.category,
    this.serialNumber = '',
    this.imagesBase64 = const [],
  });

  final String id;
  final String partNumber;
  final String description;
  final int quantity;
  final String location;
  final String condition;
  final String category;
  final String serialNumber;
  final List<String> imagesBase64;

  Map<String, Object?> toJson() => {
    'id': id,
    'partNumber': partNumber,
    'description': description,
    'quantity': quantity,
    'location': location,
    'condition': condition,
    'category': category,
    'serialNumber': serialNumber,
    'imagesBase64': imagesBase64,
  };

  factory HeavyPart.fromJson(Map<String, dynamic> json) => HeavyPart(
    id: json['id'] as String,
    partNumber: json['partNumber'] as String,
    description: json['description'] as String,
    quantity: json['quantity'] as int,
    location: json['location'] as String,
    condition: json['condition'] as String,
    category: json['category'] as String? ?? 'General',
    serialNumber: json['serialNumber'] as String? ?? '',
    imagesBase64:
        (json['imagesBase64'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  HeavyPart copyWith({
    String? id,
    String? partNumber,
    String? description,
    int? quantity,
    String? location,
    String? condition,
    String? category,
    String? serialNumber,
    List<String>? imagesBase64,
  }) {
    return HeavyPart(
      id: id ?? this.id,
      partNumber: partNumber ?? this.partNumber,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      condition: condition ?? this.condition,
      category: category ?? this.category,
      serialNumber: serialNumber ?? this.serialNumber,
      imagesBase64: imagesBase64 ?? this.imagesBase64,
    );
  }
}

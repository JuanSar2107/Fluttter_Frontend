class HeavyPart {
  const HeavyPart({
    required this.id,
    required this.partNumber,
    required this.description,
    required this.quantity,
    required this.location,
    required this.condition,
    this.serialNumber = '',
    this.imagesBase64 = const [],
  });

  final String id;
  final String partNumber;
  final String description;
  final int quantity;
  final String location;
  final String condition;
  final String serialNumber;
  final List<String> imagesBase64;

  Map<String, Object?> toJson() => {
    'id': id,
    'partNumber': partNumber,
    'description': description,
    'quantity': quantity,
    'location': location,
    'condition': condition,
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
    serialNumber: json['serialNumber'] as String? ?? '',
    imagesBase64:
        (json['imagesBase64'] as List<dynamic>?)?.cast<String>() ?? const [],
  );
}

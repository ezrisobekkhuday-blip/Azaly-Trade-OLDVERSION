class Product {
  const Product({
    required this.id,
    required this.imagePaths,
    required this.amount,
    required this.material,
    required this.size,
    required this.status,
    required this.createdAt,
    required this.isFavorite,
  });

  final String id;
  final List<String> imagePaths;
  final String amount;
  final String material;
  final String size;
  final String status;
  final DateTime createdAt;
  final bool isFavorite;

  Product copyWith({
    List<String>? imagePaths,
    String? amount,
    String? material,
    String? size,
    String? status,
    bool? isFavorite,
  }) {
    return Product(
      id: id,
      imagePaths: imagePaths ?? this.imagePaths,
      amount: amount ?? this.amount,
      material: material ?? this.material,
      size: size ?? this.size,
      status: status ?? this.status,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePaths': imagePaths,
      'amount': amount,
      'material': material,
      'size': size,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imagePaths'] ?? json['images'];
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawIsFavorite = json['isFavorite'] ?? json['is_favorite'];

    return Product(
      id: '${json['id'] ?? ''}',
      imagePaths: List<String>.from(rawImages as List<dynamic>? ?? const []),
      amount: json['amount'] as String? ?? '',
      material: json['material'] as String? ?? '',
      size: json['size'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      createdAt:
          DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),
      isFavorite: rawIsFavorite as bool? ?? false,
    );
  }
}

String formatProductDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day.$month.$year | $hour:$minute';
}

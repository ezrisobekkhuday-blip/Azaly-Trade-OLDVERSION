class Product {
  const Product({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.imagePaths,
    required this.article,
    required this.amount,
    required this.quantity,
    required this.color,
    required this.material,
    required this.size,
    required this.measurements,
    required this.status,
    required this.createdAt,
    required this.isFavorite,
  });

  final String id;
  final String shopId;
  final String shopName;
  final List<String> imagePaths;
  final String article;
  final String amount;
  final int quantity;
  final String color;
  final String material;
  final String size;
  final String measurements;
  final String status;
  final DateTime createdAt;
  final bool isFavorite;

  double? get amountValue => parseProductAmount(amount);

  double? get grossTotalValue => calculateGrossTotal(amount, quantity);

  double? get supplierShareValue => calculateSupplierShare(amount, quantity);

  double? get totalValue {
    return calculateNetTotal(amount, quantity);
  }

  Product copyWith({
    String? shopId,
    String? shopName,
    List<String>? imagePaths,
    String? article,
    String? amount,
    int? quantity,
    String? color,
    String? material,
    String? size,
    String? measurements,
    String? status,
    bool? isFavorite,
  }) {
    return Product(
      id: id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      imagePaths: imagePaths ?? this.imagePaths,
      article: article ?? this.article,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      color: color ?? this.color,
      material: material ?? this.material,
      size: size ?? this.size,
      measurements: measurements ?? this.measurements,
      status: status ?? this.status,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imagePaths'] ?? json['images'];
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawIsFavorite = json['isFavorite'] ?? json['is_favorite'];

    return Product(
      id: '${json['id'] ?? ''}',
      shopId: '${json['shopId'] ?? json['shop_id'] ?? ''}',
      shopName:
          json['shopName'] as String? ?? json['shop_name'] as String? ?? '',
      imagePaths: List<String>.from(rawImages as List<dynamic>? ?? const []),
      article: json['article'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      color: json['color'] as String? ?? '',
      material: json['material'] as String? ?? '',
      size: json['size'] as String? ?? '',
      measurements: json['measurements'] as String? ?? '',
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

double? parseProductAmount(String value) {
  final normalized = value
      .trim()
      .replaceAll(' ', '')
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9.]'), '');

  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

const double supplierShareRate = 0.10;

double? calculateGrossTotal(String amount, int quantity) {
  final parsedAmount = parseProductAmount(amount);

  if (parsedAmount == null) {
    return null;
  }

  return parsedAmount * quantity;
}

double? calculateSupplierShare(String amount, int quantity) {
  final grossTotal = calculateGrossTotal(amount, quantity);

  if (grossTotal == null) {
    return null;
  }

  return grossTotal * supplierShareRate;
}

double? calculateNetTotal(String amount, int quantity) {
  final grossTotal = calculateGrossTotal(amount, quantity);

  if (grossTotal == null) {
    return null;
  }

  return grossTotal + (grossTotal * supplierShareRate);
}

String formatProductMoney(double value) {
  final hasFraction = value % 1 != 0;
  final fixed = hasFraction
      ? value.toStringAsFixed(2)
      : value.toStringAsFixed(0);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index += 1) {
    final reversedIndex = whole.length - index;
    buffer.write(whole[index]);

    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write(' ');
    }
  }

  if (!hasFraction) {
    return buffer.toString();
  }

  return '${buffer.toString()}.${parts.last}';
}

import 'product.dart';

class ProductBatch {
  const ProductBatch({
    required this.id,
    required this.name,
    required this.note,
    required this.createdAt,
    required this.products,
  });

  final String id;
  final String name;
  final String note;
  final DateTime createdAt;
  final List<Product> products;

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawProducts = json['products'];

    return ProductBatch(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),
      products: (rawProducts as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
    );
  }

  static List<ProductBatch> groupFromProducts({
    required List<ProductBatch> batchMeta,
    required List<Product> products,
  }) {
    final productsByBatchId = <String, List<Product>>{};

    for (final product in products) {
      final batchId = product.batchId;

      if (batchId == null || batchId.isEmpty) {
        continue;
      }

      productsByBatchId.putIfAbsent(batchId, () => []).add(product);
    }

    return [
      for (final batch in batchMeta)
        ProductBatch(
          id: batch.id,
          name: batch.name,
          note: batch.note,
          createdAt: batch.createdAt,
          products: List<Product>.from(productsByBatchId[batch.id] ?? const []),
        ),
    ];
  }
}

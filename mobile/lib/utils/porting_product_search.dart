import '../models/product.dart';
import '../models/product_batch.dart';

List<Product> filterProductsForPortingSearch(
  List<Product> products,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return const [];
  }

  final matches = <Product>[];

  for (final product in products) {
    if (_productMatchesPortingSearch(product, normalized)) {
      matches.add(product);
    }
  }

  matches.sort((left, right) {
    final leftArticle = left.article.trim().toLowerCase();
    final rightArticle = right.article.trim().toLowerCase();
    final leftExact = leftArticle == normalized;
    final rightExact = rightArticle == normalized;

    if (leftExact != rightExact) {
      return leftExact ? -1 : 1;
    }

    final leftStarts = leftArticle.startsWith(normalized);
    final rightStarts = rightArticle.startsWith(normalized);

    if (leftStarts != rightStarts) {
      return leftStarts ? -1 : 1;
    }

    return right.createdAt.compareTo(left.createdAt);
  });

  return matches;
}

bool _productMatchesPortingSearch(Product product, String normalized) {
  final article = product.article.trim().toLowerCase();
  if (article.contains(normalized)) {
    return true;
  }

  final color = product.color.trim().toLowerCase();
  if (color.isNotEmpty && color.contains(normalized)) {
    return true;
  }

  final material = product.material.trim().toLowerCase();
  if (material.isNotEmpty && material.contains(normalized)) {
    return true;
  }

  final size = product.size.trim().toLowerCase();
  if (size.isNotEmpty && size.contains(normalized)) {
    return true;
  }

  final shopName = product.shopName.trim().toLowerCase();
  if (shopName.isNotEmpty && shopName.contains(normalized)) {
    return true;
  }

  final measurements = product.measurements.trim().toLowerCase();
  if (measurements.isNotEmpty && measurements.contains(normalized)) {
    return true;
  }

  return false;
}

String? batchNameForProduct(Product product, Map<String, String> batchNamesById) {
  final batchId = product.batchId;
  if (batchId == null || batchId.isEmpty) {
    return null;
  }

  return batchNamesById[batchId];
}

Map<String, String> buildBatchNamesById(Iterable<ProductBatch> batches) {
  return {
    for (final batch in batches) batch.id: batch.name,
  };
}

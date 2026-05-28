import '../models/product.dart';

class ProductGoodsTotals {
  const ProductGoodsTotals({
    required this.productCount,
    required this.totalPieces,
    required this.totalCny,
    required this.totalUsd,
    required this.totalUzs,
  });

  final int productCount;
  final int totalPieces;
  final double totalCny;
  final double totalUsd;
  final double totalUzs;
}

/// Sums goods totals using each product's saved [Product.usdToCnyRate] and
/// [Product.usdToUzsRate] only (no profile fallback).
ProductGoodsTotals summarizeProductGoodsTotals(List<Product> products) {
  var totalPieces = 0;
  var totalCny = 0.0;
  var totalUsd = 0.0;
  var totalUzs = 0.0;

  for (final product in products) {
    totalPieces += product.quantity;
    final cny = product.totalValue ?? 0;
    totalCny += cny;

    if (product.usdToCnyRate <= 0) {
      continue;
    }

    final converted = convertCnyToCurrencies(
      cny,
      product.usdToCnyRate,
      product.usdToUzsRate,
    );
    totalUsd += converted.usd;
    totalUzs += converted.uzs;
  }

  return ProductGoodsTotals(
    productCount: products.length,
    totalPieces: totalPieces,
    totalCny: totalCny,
    totalUsd: totalUsd,
    totalUzs: totalUzs,
  );
}

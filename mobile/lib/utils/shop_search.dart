import '../models/product.dart';
import '../models/shop.dart';

class ShopSearchResult {
  const ShopSearchResult({
    required this.shop,
    this.matchedProducts = const [],
    this.matchedByShopName = false,
  });

  final Shop shop;
  final List<Product> matchedProducts;
  final bool matchedByShopName;

  bool get hasMatchedProducts => matchedProducts.isNotEmpty;
}

List<ShopSearchResult> filterShopsForSearch({
  required List<Shop> shops,
  required List<Product> products,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return shops.map((shop) => ShopSearchResult(shop: shop)).toList();
  }

  final results = <ShopSearchResult>[];

  for (final shop in shops) {
    final shopProducts = products.where((product) => product.shopId == shop.id);
    final matchedByShopName = _shopMatchesQuery(shop, normalizedQuery);
    final matchedProducts = shopProducts
        .where((product) => _productMatchesQuery(product, normalizedQuery))
        .toList();

    if (matchedByShopName || matchedProducts.isNotEmpty) {
      results.add(
        ShopSearchResult(
          shop: shop,
          matchedProducts: matchedProducts,
          matchedByShopName: matchedByShopName,
        ),
      );
    }
  }

  return results;
}

bool _shopMatchesQuery(Shop shop, String query) {
  return _fieldMatches(shop.name, query) ||
      _fieldMatches(shop.location, query) ||
      _fieldMatches(shop.description, query);
}

bool _productMatchesQuery(Product product, String query) {
  return _fieldMatches(product.article, query) ||
      _fieldMatches(product.color, query) ||
      _fieldMatches(product.material, query) ||
      _fieldMatches(product.size, query) ||
      _fieldMatches(product.amount, query) ||
      _fieldMatches(product.measurements, query);
}

bool _fieldMatches(String value, String query) {
  return value.trim().toLowerCase().contains(query);
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class AppStore extends ChangeNotifier {
  static const _storageKey = 'azaly_trade_flutter_state';

  bool _isReady = false;
  String _displayName = 'Azaly Trade';
  final List<Product> _products = [];

  bool get isReady => _isReady;
  String get displayName => _displayName;
  List<Product> get allProducts => List.unmodifiable(_products);
  List<Product> get products =>
      List.unmodifiable(_products.where((product) => !product.isFavorite));
  List<Product> get favoriteProducts =>
      List.unmodifiable(_products.where((product) => product.isFavorite));

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final rawState = preferences.getString(_storageKey);

      if (rawState != null && rawState.isNotEmpty) {
        final decoded = jsonDecode(rawState) as Map<String, dynamic>;
        final storedName = (decoded['displayName'] as String?)?.trim() ?? '';
        final storedProducts = decoded['products'] as List<dynamic>? ?? const [];

        _displayName = storedName.isEmpty ? 'Azaly Trade' : storedName;
        _products
          ..clear()
          ..addAll(
            storedProducts
                .whereType<Map<String, dynamic>>()
                .map(Product.fromJson),
          );
      }
    } catch (_) {
      _displayName = 'Azaly Trade';
      _products.clear();
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> updateName(String value) async {
    _displayName = value.trim().isEmpty ? 'Azaly Trade' : value.trim();
    notifyListeners();
    await _persist();
  }

  Future<void> createProduct({
    required List<String> imagePaths,
    required String amount,
    required String material,
    required String size,
  }) async {
    _products.insert(
      0,
      Product(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        imagePaths: List<String>.from(imagePaths),
        amount: amount.trim(),
        material: material.trim(),
        size: size.trim(),
        status: 'new',
        createdAt: DateTime.now(),
        isFavorite: false,
      ),
    );

    notifyListeners();
    await _persist();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere((product) => product.id == updatedProduct.id);

    if (index == -1) {
      return;
    }

    _products[index] = updatedProduct;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((product) => product.id == productId);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleFavorite(String productId) async {
    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) {
      return;
    }

    final product = _products[index];
    _products[index] = product.copyWith(isFavorite: !product.isFavorite);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'displayName': _displayName,
      'products': _products.map((product) => product.toJson()).toList(),
    });

    await preferences.setString(_storageKey, encoded);
  }
}

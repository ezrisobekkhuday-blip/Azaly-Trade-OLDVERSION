import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_client.dart';

class AppStore extends ChangeNotifier {
  AppStore({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
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
      final bootstrap = await _apiClient.fetchBootstrap();
      _displayName = bootstrap.displayName;
      _products
        ..clear()
        ..addAll(bootstrap.products);
    } catch (_) {
      _displayName = 'Azaly Trade';
      _products.clear();
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> updateName(String value) async {
    final updatedName = await _apiClient.updateProfileName(
      value.trim().isEmpty ? 'Azaly Trade' : value.trim(),
    );

    _displayName = updatedName;
    notifyListeners();
  }

  Future<void> createProduct({
    required List<String> imagePaths,
    required String amount,
    required String material,
    required String size,
  }) async {
    final preparedImages = await _prepareImagePaths(imagePaths);
    final createdProduct = await _apiClient.createProduct(
      images: preparedImages,
      amount: amount.trim(),
      material: material.trim(),
      size: size.trim(),
    );

    _products.insert(0, createdProduct);
    notifyListeners();
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere(
      (product) => product.id == updatedProduct.id,
    );

    if (index == -1) {
      return;
    }

    final preparedProduct = updatedProduct.copyWith(
      imagePaths: await _prepareImagePaths(updatedProduct.imagePaths),
    );
    final serverProduct = await _apiClient.updateProduct(preparedProduct);

    _products[index] = serverProduct;
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _apiClient.deleteProduct(productId);
    _products.removeWhere((product) => product.id == productId);
    notifyListeners();
  }

  Future<void> toggleFavorite(String productId) async {
    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) {
      return;
    }

    final product = _products[index];
    final serverProduct = await _apiClient.updateProduct(
      product.copyWith(isFavorite: !product.isFavorite),
    );

    _products[index] = serverProduct;
    notifyListeners();
  }

  Future<List<String>> _prepareImagePaths(List<String> imagePaths) async {
    final localPaths = imagePaths
        .where(
          (path) => !path.startsWith('http://') && !path.startsWith('https://'),
        )
        .toList();

    if (localPaths.isEmpty) {
      return List<String>.from(imagePaths);
    }

    final uploadedPaths = await _apiClient.uploadImages(localPaths);
    var uploadedIndex = 0;

    return imagePaths.map((path) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }

      final remotePath = uploadedPaths[uploadedIndex];
      uploadedIndex += 1;
      return remotePath;
    }).toList();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}

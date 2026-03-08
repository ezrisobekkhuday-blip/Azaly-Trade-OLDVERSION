import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_strings.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_client.dart';

class AppStore extends ChangeNotifier {
  AppStore({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static const String _languageStorageKey = 'app_language';
  static const String _pinnedShopsStorageKey = 'pinned_shops';

  final ApiClient _apiClient;
  bool _isReady = false;
  String _displayName = 'Azaly Trade';
  AppLanguage _language = AppLanguage.ru;
  final List<String> _pinnedShopIds = [];
  final List<Shop> _shops = [];
  final List<Product> _products = [];

  bool get isReady => _isReady;
  String get displayName => _displayName;
  AppLanguage get language => _language;
  List<Shop> get shops {
    final orderedShops = List<Shop>.from(_shops);
    orderedShops.sort((left, right) {
      final leftPinnedIndex = _pinnedShopIds.indexOf(left.id);
      final rightPinnedIndex = _pinnedShopIds.indexOf(right.id);
      final leftPinned = leftPinnedIndex != -1;
      final rightPinned = rightPinnedIndex != -1;

      if (leftPinned && rightPinned) {
        return leftPinnedIndex.compareTo(rightPinnedIndex);
      }

      if (leftPinned != rightPinned) {
        return leftPinned ? -1 : 1;
      }

      return right.createdAt.compareTo(left.createdAt);
    });

    return List.unmodifiable(orderedShops);
  }

  List<Product> get allProducts => List.unmodifiable(_products);
  List<Product> get favoriteProducts =>
      List.unmodifiable(_products.where((product) => product.isFavorite));

  bool isShopPinned(String shopId) => _pinnedShopIds.contains(shopId);

  Shop? shopById(String shopId) {
    for (final shop in _shops) {
      if (shop.id == shopId) {
        return shop;
      }
    }

    return null;
  }

  List<Product> productsForShop(String shopId) {
    return List.unmodifiable(
      _products.where((product) => product.shopId == shopId),
    );
  }

  ShopPurchaseSummary purchaseSummaryForShop(String shopId) {
    var totalQuantity = 0;
    var grossTotal = 0.0;
    var netTotal = 0.0;

    for (final product in _products) {
      if (product.shopId != shopId) {
        continue;
      }

      totalQuantity += product.quantity;
      grossTotal += product.grossTotalValue ?? 0;
      netTotal += product.totalValue ?? 0;
    }

    return ShopPurchaseSummary(
      totalQuantity: totalQuantity,
      grossTotal: grossTotal,
      netTotal: netTotal,
    );
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(
      preferences.getString(_languageStorageKey) ?? AppLanguage.ru.code,
    );
    _pinnedShopIds
      ..clear()
      ..addAll(preferences.getStringList(_pinnedShopsStorageKey) ?? const []);

    try {
      final bootstrap = await _apiClient.fetchBootstrap();
      _displayName = bootstrap.displayName;
      _shops
        ..clear()
        ..addAll(bootstrap.shops);
      _products
        ..clear()
        ..addAll(bootstrap.products);
      _syncShopCounts();
      await _cleanupPinnedShops();
    } catch (_) {
      _displayName = 'Azaly Trade';
      _shops.clear();
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

  Future<void> updateLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageStorageKey, language.code);
    notifyListeners();
  }

  Future<void> createShop({
    required String name,
    required String photoPath,
    required List<StorefrontItem> storefrontItems,
    required String location,
    required double? latitude,
    required double? longitude,
    required String description,
    required String businessCardPath,
  }) async {
    final photo = await _prepareSingleImage(photoPath);
    final preparedStorefrontItems = await _prepareStorefrontItems(
      storefrontItems,
    );
    final businessCard = businessCardPath.trim().isEmpty
        ? ''
        : await _prepareSingleImage(businessCardPath);

    final serverShop = await _apiClient.createShop(
      name: name.trim(),
      photo: photo,
      location: location.trim(),
      latitude: latitude,
      longitude: longitude,
      description: description.trim(),
      storefrontItems: preparedStorefrontItems,
      businessCardImage: businessCard,
    );
    final createdShop = serverShop.copyWith(
      photo: serverShop.photo.isEmpty ? photo : serverShop.photo,
      location: serverShop.location.isEmpty
          ? location.trim()
          : serverShop.location,
      latitude: serverShop.latitude ?? latitude,
      longitude: serverShop.longitude ?? longitude,
      storefrontItems: serverShop.storefrontItems.isEmpty
          ? preparedStorefrontItems
          : serverShop.storefrontItems,
      businessCardImage: serverShop.businessCardImage.isEmpty
          ? businessCard
          : serverShop.businessCardImage,
    );

    _shops.insert(0, createdShop);
    _syncShopCounts();
    notifyListeners();
  }

  Future<void> updateShop(Shop updatedShop) async {
    final index = _shops.indexWhere((shop) => shop.id == updatedShop.id);

    if (index == -1) {
      return;
    }

    final preparedStorefrontItems = await _prepareStorefrontItems(
      updatedShop.storefrontItems,
    );
    final preparedShop = updatedShop.copyWith(
      storefrontItems: preparedStorefrontItems,
    );
    final serverShop = await _apiClient.updateShop(preparedShop);
    _shops[index] = serverShop.copyWith(
      photo: serverShop.photo.isEmpty ? preparedShop.photo : serverShop.photo,
      latitude: serverShop.latitude ?? preparedShop.latitude,
      longitude: serverShop.longitude ?? preparedShop.longitude,
      location: serverShop.location.isEmpty
          ? preparedShop.location
          : serverShop.location,
      storefrontItems: serverShop.storefrontItems.isEmpty
          ? preparedShop.storefrontItems
          : serverShop.storefrontItems,
      businessCardImage: serverShop.businessCardImage.isEmpty
          ? preparedShop.businessCardImage
          : serverShop.businessCardImage,
    );
    notifyListeners();
  }

  Future<void> deleteShop(String shopId) async {
    await _apiClient.deleteShop(shopId);
    _shops.removeWhere((shop) => shop.id == shopId);
    _products.removeWhere((product) => product.shopId == shopId);
    _pinnedShopIds.removeWhere((id) => id == shopId);
    await _persistPinnedShops();
    _syncShopCounts();
    notifyListeners();
  }

  Future<void> setShopPinned(String shopId, bool pinned) async {
    final exists = _shops.any((shop) => shop.id == shopId);

    if (!exists) {
      return;
    }

    _pinnedShopIds.removeWhere((id) => id == shopId);
    if (pinned) {
      _pinnedShopIds.insert(0, shopId);
    }

    await _persistPinnedShops();
    notifyListeners();
  }

  Future<void> createProduct({
    required String shopId,
    required List<String> imagePaths,
    required String amount,
    required int quantity,
    required String color,
    required String material,
    required String size,
  }) async {
    final preparedImages = await _prepareImagePaths(imagePaths);
    final createdProduct = await _apiClient.createProduct(
      shopId: shopId,
      images: preparedImages,
      amount: amount.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      color: color.trim(),
      material: material.trim(),
      size: size.trim(),
    );

    _products.insert(0, createdProduct);
    _syncShopCounts();
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
    _syncShopCounts();
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _apiClient.deleteProduct(productId);
    _products.removeWhere((product) => product.id == productId);
    _syncShopCounts();
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

  Future<String> _prepareSingleImage(String imagePath) async {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final uploaded = await _apiClient.uploadImages([imagePath]);
    return uploaded.first;
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

  Future<List<StorefrontItem>> _prepareStorefrontItems(
    List<StorefrontItem> items,
  ) async {
    if (items.isEmpty) {
      return const [];
    }

    final uploadedImagePaths = await _prepareImagePaths(
      items.map((item) => item.imagePath).toList(),
    );

    return List<StorefrontItem>.generate(
      items.length,
      (index) => items[index].copyWith(imagePath: uploadedImagePaths[index]),
      growable: false,
    );
  }

  void _syncShopCounts() {
    final counts = <String, int>{};

    for (final product in _products) {
      counts.update(product.shopId, (value) => value + 1, ifAbsent: () => 1);
    }

    for (var index = 0; index < _shops.length; index += 1) {
      final shop = _shops[index];
      _shops[index] = shop.copyWith(productsCount: counts[shop.id] ?? 0);
    }
  }

  Future<void> _cleanupPinnedShops() async {
    final validIds = _shops.map((shop) => shop.id).toSet();
    final originalLength = _pinnedShopIds.length;
    _pinnedShopIds.removeWhere((shopId) => !validIds.contains(shopId));

    if (_pinnedShopIds.length != originalLength) {
      await _persistPinnedShops();
    }
  }

  Future<void> _persistPinnedShops() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_pinnedShopsStorageKey, _pinnedShopIds);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }
}

class ShopPurchaseSummary {
  const ShopPurchaseSummary({
    required this.totalQuantity,
    required this.grossTotal,
    required this.netTotal,
  });

  final int totalQuantity;
  final double grossTotal;
  final double netTotal;
}

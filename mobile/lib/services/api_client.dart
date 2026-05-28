import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/expense.dart';
import '../models/product.dart';
import '../models/product_batch.dart';
import '../models/shop.dart';
import '../utils/image_source_utils.dart';

class ApiClient {
  ApiClient({http.Client? client})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(_resolveBaseUrl());

  final http.Client _client;
  final Uri _baseUri;

  Future<AppBootstrap> fetchBootstrap() async {
    final responses = await Future.wait([
      _client.get(_uri('/profile')),
      _client.get(_uri('/shops')),
      _client.get(_uri('/products')),
      _getOptional('/expenses'),
      _getOptional(
        '/batches',
        queryParameters: const {'include_products': 'false'},
      ),
    ]);

    final profilePayload = _decodeResponse(responses[0] as http.Response);
    final shopsPayload = _decodeResponse(responses[1] as http.Response);
    final productsPayload = _decodeResponse(responses[2] as http.Response);
    final expensesPayload = responses[3] == null
        ? null
        : _decodeResponse(responses[3] as http.Response);
    final batchesPayload = responses[4] == null
        ? null
        : _decodeResponse(responses[4] as http.Response);

    if (profilePayload is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response.');
    }

    if (shopsPayload is! List || productsPayload is! List) {
      throw const ApiException('Invalid catalog response.');
    }

    final products = _parseList(productsPayload, Product.fromJson);
    final batchMeta = batchesPayload is List
        ? _parseList(batchesPayload, ProductBatch.fromJson)
        : const <ProductBatch>[];

    return AppBootstrap(
      profile: _readProfile(profilePayload),
      shops: _parseList(shopsPayload, Shop.fromJson),
      products: products,
      expenses: expensesPayload is List
          ? _parseList(expensesPayload, Expense.fromJson)
          : const [],
      batches: ProductBatch.groupFromProducts(
        batchMeta: batchMeta,
        products: products,
      ),
    );
  }

  List<T> _parseList<T>(
    List<dynamic> payload,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final items = <T>[];

    for (final entry in payload) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      try {
        items.add(fromJson(entry));
      } catch (error) {
        debugPrint('Skipped invalid API item: $error');
      }
    }

    return items;
  }

  Future<List<ProductBatch>> fetchBatches() async {
    final response = await _client.get(_uri('/batches'));
    final payload = _decodeResponse(response);

    if (payload is! List) {
      throw const ApiException('Invalid batches response.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(ProductBatch.fromJson)
        .toList();
  }

  Future<ProductBatch> createBatch({
    required String name,
    required List<String> productIds,
    String note = '',
  }) async {
    final response = await _client.post(
      _uri('/batches'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'note': note,
        'product_ids': productIds.map(int.parse).toList(),
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid batch response.');
    }

    return ProductBatch.fromJson(payload);
  }

  Future<ProductBatch> addProductsToBatch({
    required String batchId,
    required List<String> productIds,
  }) async {
    final response = await _client.post(
      _uri('/batches/$batchId/products'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'product_ids': productIds.map(int.parse).toList(),
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid batch response.');
    }

    return ProductBatch.fromJson(payload);
  }

  Future<ProductBatch> updateBatch({
    required String batchId,
    required String name,
    String note = '',
  }) async {
    final response = await _client.put(
      _uri('/batches/$batchId'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'note': note}),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid batch response.');
    }

    return ProductBatch.fromJson(payload);
  }

  Future<String> updateProfileName(String name) async {
    final profile = await updateProfile(
      name: name,
    );

    return profile.displayName;
  }

  Future<AppProfile> updateProfile({
    required String name,
    double? usdToCny,
    double? usdToUzs,
  }) async {
    final body = <String, dynamic>{
      'name': name,
    };

    if (usdToCny != null) {
      body['usd_to_cny'] = usdToCny;
    }

    if (usdToUzs != null) {
      body['usd_to_uzs'] = usdToUzs;
    }

    final response = await _client.put(
      _uri('/profile'),
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response.');
    }

    return _readProfile(payload);
  }

  Future<List<String>> uploadImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      return const [];
    }

    final request = http.MultipartRequest('POST', _uri('/media/upload'));
    var index = 0;

    for (final imagePath in imagePaths) {
      if (isInlineDataImageSource(imagePath)) {
        final bytes = decodeInlineDataImage(imagePath);
        if (bytes == null) {
          throw const ApiException('Cannot read selected image.');
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: suggestedUploadFileName(imagePath, index),
          ),
        );
      } else if (isBrowserObjectImageSource(imagePath)) {
        final response = await _client.get(Uri.parse(imagePath));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw const ApiException('Cannot read selected image.');
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            response.bodyBytes,
            filename: suggestedUploadFileName(imagePath, index),
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('files', imagePath));
      }

      index += 1;
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final payload = _decodeResponse(response);

    if (payload is! List) {
      throw const ApiException('Invalid media response.');
    }

    return payload.map((item) => item.toString()).toList();
  }

  Future<Shop> createShop({
    required String name,
    required String photo,
    required String location,
    required double? latitude,
    required double? longitude,
    required String description,
    required List<StorefrontItem> storefrontItems,
    required String businessCardImage,
    required String sellerWechat,
    required String sellerWechatLink,
  }) async {
    final storefrontImages = storefrontItems
        .map((item) => item.imagePath)
        .where((path) => path.trim().isNotEmpty)
        .toList();
    final response = await _client.post(
      _uri('/shops'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'photo': photo,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'storefront_items': storefrontItems
            .map((item) => item.toJson())
            .toList(),
        'storefront_images': storefrontImages,
        'storefront_image': storefrontImages.isEmpty
            ? ''
            : storefrontImages.first,
        'business_card_image': businessCardImage,
        'seller_wechat': sellerWechat,
        'seller_wechat_link': sellerWechatLink,
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid shop response.');
    }

    return Shop.fromJson(payload);
  }

  Future<Shop> updateShop(Shop shop) async {
    final storefrontImages = shop.storefrontItems
        .map((item) => item.imagePath)
        .where((path) => path.trim().isNotEmpty)
        .toList();
    final response = await _client.put(
      _uri('/shops/${shop.id}'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': shop.name,
        'photo': shop.photo,
        'location': shop.location,
        'latitude': shop.latitude,
        'longitude': shop.longitude,
        'description': shop.description,
        'storefront_items': shop.storefrontItems
            .map((item) => item.toJson())
            .toList(),
        'storefront_images': shop.storefrontImages,
        'storefront_image': storefrontImages.isEmpty
            ? ''
            : storefrontImages.first,
        'business_card_image': shop.businessCardImage,
        'seller_wechat': shop.sellerWechat,
        'seller_wechat_link': shop.sellerWechatLink,
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid shop response.');
    }

    return Shop.fromJson(payload);
  }

  Future<void> deleteShop(String shopId) async {
    final response = await _client.delete(_uri('/shops/$shopId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decodeResponse(response);
    }
  }

  Future<Product> createProduct({
    required String shopId,
    required List<String> images,
    required String article,
    required String amount,
    required int quantity,
    required String color,
    required String material,
    required String size,
    required String measurements,
    bool isFavorite = false,
  }) async {
    final response = await _client.post(
      _uri('/products'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'shop_id': int.parse(shopId),
        'images': images,
        'article': article,
        'amount': amount,
        'quantity': quantity,
        'supplier_share_percent': supplierShareRate * 100,
        'color': color,
        'material': material,
        'size': size,
        'measurements': measurements,
        'is_favorite': isFavorite,
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid product response.');
    }

    return Product.fromJson(payload);
  }

  Future<Product> detachProductFromBatch(String productId) async {
    final response = await _client.patch(
      _uri('/products/$productId/batch-membership'),
      headers: _jsonHeaders,
      body: jsonEncode({'batch_id': null}),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid product response.');
    }

    return Product.fromJson(payload);
  }

  Future<Product> updateProductBatchItemType({
    required String productId,
    required String batchItemType,
  }) async {
    final response = await _client.patch(
      _uri('/products/$productId/batch-item-type'),
      headers: _jsonHeaders,
      body: jsonEncode({'batch_item_type': batchItemType}),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid product response.');
    }

    return Product.fromJson(payload);
  }

  Future<Product> updateProduct(Product product) async {
    final response = await _client.put(
      _uri('/products/${product.id}'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'shop_id': int.parse(product.shopId),
        'images': product.imagePaths,
        'article': product.article,
        'amount': product.amount,
        'quantity': product.quantity,
        'supplier_share_percent': product.supplierSharePercent,
        'color': product.color,
        'material': product.material,
        'size': product.size,
        'measurements': product.measurements,
        'is_favorite': product.isFavorite,
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid product response.');
    }

    return Product.fromJson(payload);
  }

  Future<void> deleteProduct(String productId) async {
    final response = await _client.delete(_uri('/products/$productId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decodeResponse(response);
    }
  }

  Future<Expense> createExpense({
    required String title,
    required String amount,
    required String note,
    required String accountingType,
    required String accountingChannel,
    required String currency,
  }) async {
    final response = await _client.post(
      _uri('/expenses'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'note': note,
        'accounting_type': accountingType,
        'accounting_channel': accountingChannel,
        'currency': currency,
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid expense response.');
    }

    return Expense.fromJson(payload);
  }

  Future<Expense> updateExpenseBatchAssignment({
    required String expenseId,
    String? batchId,
  }) async {
    final response = await _client.patch(
      _uri('/expenses/$expenseId/batch-assignment'),
      headers: _jsonHeaders,
      body: jsonEncode({'batch_id': batchId}),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid expense response.');
    }

    return Expense.fromJson(payload);
  }

  Future<Expense> updateExpense(Expense expense) async {
    final response = await _client.put(
      _uri('/expenses/${expense.id}'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'title': expense.title,
        'amount': expense.amount,
        'note': expense.note,
        'accounting_type': expense.accountingType,
        'accounting_channel': expense.accountingChannel,
        'currency': expense.inputCurrency,
      }),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid expense response.');
    }

    return Expense.fromJson(payload);
  }

  Future<void> deleteExpense(String expenseId) async {
    final response = await _client.delete(_uri('/expenses/$expenseId'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decodeResponse(response);
    }
  }

  void dispose() {
    _client.close();
  }

  Future<http.Response?> _getOptional(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      return await _client.get(_uri(path, queryParameters: queryParameters));
    } catch (_) {
      return null;
    }
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final resolved = _baseUri.resolve(path);

    if (queryParameters == null || queryParameters.isEmpty) {
      return resolved;
    }

    return resolved.replace(queryParameters: queryParameters);
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(_extractErrorMessage(body, response.reasonPhrase));
  }

  static double _readUsdToCnyRate(Map<String, dynamic> payload) {
    final usdToCny = (payload['usd_to_cny'] as num?)?.toDouble();
    if (usdToCny != null && usdToCny > 0) {
      return usdToCny;
    }

    final legacy = (payload['cny_to_usd'] as num?)?.toDouble() ?? 0;
    if (legacy <= 0) {
      return 0;
    }

    if (legacy < 2) {
      return 1 / legacy;
    }

    return legacy;
  }

  static AppProfile _readProfile(Map<String, dynamic> payload) {
    final rawName = payload['name']?.toString().trim() ?? '';

    return AppProfile(
      displayName: rawName.isEmpty ? 'Azaly Trade' : rawName,
      usdToCny: _readUsdToCnyRate(payload),
      usdToUzs: (payload['usd_to_uzs'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _extractErrorMessage(dynamic payload, String? fallback) {
    if (payload is Map<String, dynamic>) {
      final detail = payload['detail'];

      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    }

    final fallbackMessage = fallback?.trim() ?? '';
    return fallbackMessage.isEmpty ? 'Request failed.' : fallbackMessage;
  }

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
  };
}

class AppProfile {
  const AppProfile({
    required this.displayName,
    required this.usdToCny,
    required this.usdToUzs,
  });

  final String displayName;
  final double usdToCny;
  final double usdToUzs;
}

class AppBootstrap {
  const AppBootstrap({
    required this.profile,
    required this.shops,
    required this.products,
    required this.expenses,
    required this.batches,
  });

  final AppProfile profile;
  final List<Shop> shops;
  final List<Product> products;
  final List<Expense> expenses;
  final List<ProductBatch> batches;

  String get displayName => profile.displayName;
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

String describeError(Object error, {required String fallbackMessage}) {
  if (error is ApiException && error.message.trim().isNotEmpty) {
    return error.message;
  }

  final message = error.toString().trim();
  if (message.isNotEmpty &&
      message != 'Exception' &&
      message != 'null' &&
      !message.startsWith("Instance of '")) {
    return message;
  }

  return fallbackMessage;
}

String _resolveBaseUrl() {
  const configuredUrl = String.fromEnvironment('AZALY_API_URL');

  if (configuredUrl.isNotEmpty) {
    return _normalizeWebApiUrl(configuredUrl);
  }

  if (kIsWeb) {
    final base = Uri.base;
    final isLocalHost =
        base.host == 'localhost' || base.host == '127.0.0.1';

    if (isLocalHost) {
      return '${base.scheme}://${base.host}:8080';
    }

    return base.origin;
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return 'http://127.0.0.1:8080';
  }

  return 'http://127.0.0.1:8080';
}

String _normalizeWebApiUrl(String configuredUrl) {
  if (!kIsWeb) {
    return configuredUrl;
  }

  final configured = Uri.tryParse(configuredUrl);
  final page = Uri.base;

  if (configured == null || configured.host.isEmpty) {
    return configuredUrl;
  }

  final pageIsLocal =
      page.host == 'localhost' || page.host == '127.0.0.1';
  final apiIsLocal =
      configured.host == 'localhost' || configured.host == '127.0.0.1';

  if (!pageIsLocal || !apiIsLocal) {
    return configuredUrl;
  }

  if (page.host == configured.host) {
    return configuredUrl;
  }

  final port = configured.hasPort ? configured.port : 8080;
  return '${configured.scheme}://${page.host}:$port';
}

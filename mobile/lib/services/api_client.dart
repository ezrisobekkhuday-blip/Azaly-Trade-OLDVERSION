import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/expense.dart';
import '../models/product.dart';
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
    ]);

    final profilePayload = _decodeResponse(responses[0]);
    final shopsPayload = _decodeResponse(responses[1]);
    final productsPayload = _decodeResponse(responses[2]);
    dynamic expensesPayload = const <Map<String, dynamic>>[];

    try {
      final expensesResponse = await _client.get(_uri('/expenses'));
      expensesPayload = _decodeResponse(expensesResponse);
    } catch (_) {
      expensesPayload = const <Map<String, dynamic>>[];
    }

    if (profilePayload is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response.');
    }

    if (shopsPayload is! List ||
        productsPayload is! List ||
        expensesPayload is! List) {
      throw const ApiException('Invalid catalog response.');
    }

    return AppBootstrap(
      displayName: _readProfileName(profilePayload),
      shops: shopsPayload
          .whereType<Map<String, dynamic>>()
          .map(Shop.fromJson)
          .toList(),
      products: productsPayload
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
      expenses: expensesPayload
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList(),
    );
  }

  Future<String> updateProfileName(String name) async {
    final response = await _client.put(
      _uri('/profile'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name}),
    );

    final payload = _decodeResponse(response);

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response.');
    }

    return _readProfileName(payload);
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
  }) async {
    final response = await _client.post(
      _uri('/expenses'),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title, 'amount': amount, 'note': note}),
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

  Uri _uri(String path) {
    return _baseUri.resolve(path);
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

  static String _readProfileName(Map<String, dynamic> payload) {
    final rawName = payload['name']?.toString().trim() ?? '';
    return rawName.isEmpty ? 'Azaly Trade' : rawName;
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

class AppBootstrap {
  const AppBootstrap({
    required this.displayName,
    required this.shops,
    required this.products,
    required this.expenses,
  });

  final String displayName;
  final List<Shop> shops;
  final List<Product> products;
  final List<Expense> expenses;
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
    return configuredUrl;
  }

  if (kIsWeb) {
    return Uri.base.origin;
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    return 'http://34.173.218.175:8080';
  }

  return 'http://34.173.218.175:8080';
}

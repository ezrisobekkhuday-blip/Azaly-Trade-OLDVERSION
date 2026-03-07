import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';

class ApiClient {
  ApiClient({http.Client? client})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(_resolveBaseUrl());

  final http.Client _client;
  final Uri _baseUri;

  Future<AppBootstrap> fetchBootstrap() async {
    final responses = await Future.wait([
      _client.get(_uri('/profile')),
      _client.get(_uri('/products')),
    ]);

    final profilePayload = _decodeResponse(responses[0]);
    final productsPayload = _decodeResponse(responses[1]);

    if (profilePayload is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response.');
    }

    if (productsPayload is! List) {
      throw const ApiException('Invalid products response.');
    }

    return AppBootstrap(
      displayName: _readProfileName(profilePayload),
      products: productsPayload
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
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

    for (final imagePath in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', imagePath));
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final payload = _decodeResponse(response);

    if (payload is! List) {
      throw const ApiException('Invalid media response.');
    }

    return payload.map((item) => item.toString()).toList();
  }

  Future<Product> createProduct({
    required List<String> images,
    required String amount,
    required String material,
    required String size,
    bool isFavorite = false,
  }) async {
    final response = await _client.post(
      _uri('/products'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'images': images,
        'amount': amount,
        'material': material,
        'size': size,
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
        'images': product.imagePaths,
        'amount': product.amount,
        'material': product.material,
        'size': product.size,
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
  const AppBootstrap({required this.displayName, required this.products});

  final String displayName;
  final List<Product> products;
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

  return fallbackMessage;
}

String _resolveBaseUrl() {
  const configuredUrl = String.fromEnvironment('AZALY_API_URL');

  if (configuredUrl.isNotEmpty) {
    return configuredUrl;
  }

  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }

  return 'http://127.0.0.1:8000';
}

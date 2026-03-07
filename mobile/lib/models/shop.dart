class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.photo,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.storefrontImages,
    required this.businessCardImage,
    required this.productsCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String photo;
  final String location;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> storefrontImages;
  final String businessCardImage;
  final int productsCount;
  final DateTime createdAt;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasStorefrontImages => storefrontImages.isNotEmpty;
  String get storefrontPreview =>
      hasStorefrontImages ? storefrontImages.first : '';

  Shop copyWith({
    String? name,
    String? photo,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    List<String>? storefrontImages,
    String? businessCardImage,
    int? productsCount,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      storefrontImages: List<String>.unmodifiable(
        storefrontImages ?? this.storefrontImages,
      ),
      businessCardImage: businessCardImage ?? this.businessCardImage,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawStorefrontImages =
        json['storefrontImages'] ?? json['storefront_images'];
    final storefrontImages = rawStorefrontImages is List
        ? rawStorefrontImages
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];
    final legacyStorefront =
        json['storefrontImage'] as String? ??
        json['storefront_image'] as String? ??
        '';

    if (storefrontImages.isEmpty && legacyStorefront.trim().isNotEmpty) {
      storefrontImages.add(legacyStorefront.trim());
    }

    return Shop(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      storefrontImages: List<String>.unmodifiable(storefrontImages),
      businessCardImage:
          json['businessCardImage'] as String? ??
          json['business_card_image'] as String? ??
          '',
      productsCount:
          json['productsCount'] as int? ?? json['products_count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),
    );
  }
}

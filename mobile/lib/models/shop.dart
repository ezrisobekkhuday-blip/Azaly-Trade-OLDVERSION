class StorefrontItem {
  const StorefrontItem({
    required this.imagePath,
    this.amount = '',
    this.color = '',
    this.material = '',
    this.size = '',
    this.measurements = '',
    this.isFavorite = false,
  });

  final String imagePath;
  final String amount;
  final String color;
  final String material;
  final String size;
  final String measurements;
  final bool isFavorite;

  bool get hasDetails =>
      amount.trim().isNotEmpty ||
      color.trim().isNotEmpty ||
      material.trim().isNotEmpty ||
      size.trim().isNotEmpty ||
      measurements.trim().isNotEmpty;

  StorefrontItem copyWith({
    String? imagePath,
    String? amount,
    String? color,
    String? material,
    String? size,
    String? measurements,
    bool? isFavorite,
  }) {
    return StorefrontItem(
      imagePath: imagePath ?? this.imagePath,
      amount: amount ?? this.amount,
      color: color ?? this.color,
      material: material ?? this.material,
      size: size ?? this.size,
      measurements: measurements ?? this.measurements,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      'amount': amount,
      'color': color,
      'material': material,
      'size': size,
      'measurements': measurements,
      'is_favorite': isFavorite,
    };
  }

  factory StorefrontItem.fromJson(Map<String, dynamic> json) {
    return StorefrontItem(
      imagePath:
          json['imagePath'] as String? ??
          json['image_path'] as String? ??
          json['photo'] as String? ??
          '',
      amount: json['amount'] as String? ?? '',
      color: json['color'] as String? ?? '',
      material: json['material'] as String? ?? '',
      size: json['size'] as String? ?? '',
      measurements: json['measurements'] as String? ?? '',
      isFavorite:
          json['isFavorite'] as bool? ?? json['is_favorite'] as bool? ?? false,
    );
  }
}

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.photo,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.storefrontItems,
    required this.businessCardImage,
    required this.sellerWechat,
    required this.sellerWechatLink,
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
  final List<StorefrontItem> storefrontItems;
  final String businessCardImage;
  final String sellerWechat;
  final String sellerWechatLink;
  final int productsCount;
  final DateTime createdAt;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasStorefrontImages => storefrontItems.isNotEmpty;
  List<String> get storefrontImages => storefrontItems
      .map((item) => item.imagePath.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  String get storefrontPreview =>
      hasStorefrontImages ? storefrontImages.first : '';

  Shop copyWith({
    String? name,
    String? photo,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    List<StorefrontItem>? storefrontItems,
    String? businessCardImage,
    String? sellerWechat,
    String? sellerWechatLink,
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
      storefrontItems: List<StorefrontItem>.unmodifiable(
        storefrontItems ?? this.storefrontItems,
      ),
      businessCardImage: businessCardImage ?? this.businessCardImage,
      sellerWechat: sellerWechat ?? this.sellerWechat,
      sellerWechatLink: sellerWechatLink ?? this.sellerWechatLink,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawStorefrontItems =
        json['storefrontItems'] ?? json['storefront_items'];
    final rawStorefrontImages =
        json['storefrontImages'] ?? json['storefront_images'];
    final storefrontItems = rawStorefrontItems is List
        ? rawStorefrontItems
              .whereType<Map>()
              .map(
                (item) =>
                    StorefrontItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.imagePath.trim().isNotEmpty)
              .toList()
        : <StorefrontItem>[];
    final legacyStorefrontImages = rawStorefrontImages is List
        ? rawStorefrontImages
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];
    final legacyStorefront =
        json['storefrontImage'] as String? ??
        json['storefront_image'] as String? ??
        '';

    if (storefrontItems.isEmpty) {
      for (final image in legacyStorefrontImages) {
        storefrontItems.add(StorefrontItem(imagePath: image));
      }
    }

    if (storefrontItems.isEmpty && legacyStorefront.trim().isNotEmpty) {
      storefrontItems.add(StorefrontItem(imagePath: legacyStorefront.trim()));
    }

    return Shop(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      storefrontItems: List<StorefrontItem>.unmodifiable(storefrontItems),
      businessCardImage:
          json['businessCardImage'] as String? ??
          json['business_card_image'] as String? ??
          '',
      sellerWechat:
          json['sellerWechat'] as String? ??
          json['seller_wechat'] as String? ??
          '',
      sellerWechatLink:
          json['sellerWechatLink'] as String? ??
          json['seller_wechat_link'] as String? ??
          '',
      productsCount:
          json['productsCount'] as int? ?? json['products_count'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),
    );
  }
}

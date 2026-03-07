class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.photo,
    required this.location,
    required this.description,
    required this.businessCardImage,
    required this.productsCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String photo;
  final String location;
  final String description;
  final String businessCardImage;
  final int productsCount;
  final DateTime createdAt;

  Shop copyWith({
    String? name,
    String? photo,
    String? location,
    String? description,
    String? businessCardImage,
    int? productsCount,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      location: location ?? this.location,
      description: description ?? this.description,
      businessCardImage: businessCardImage ?? this.businessCardImage,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];

    return Shop(
      id: '${json['id'] ?? ''}',
      name: json['name'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
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

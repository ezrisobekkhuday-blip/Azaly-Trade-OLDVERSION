enum BatchItemType {
  regular,
  order;

  String get apiValue => name;

  bool get isOrder => this == BatchItemType.order;

  static BatchItemType fromValue(Object? value) {
    final normalized = '$value'.trim().toLowerCase();

    if (normalized == 'order' || normalized == 'заказной') {
      return BatchItemType.order;
    }

    return BatchItemType.regular;
  }
}

import 'product.dart';

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String amount;
  final String note;
  final DateTime createdAt;

  double? get amountValue => parseProductAmount(amount);

  Expense copyWith({String? title, String? amount, String? note}) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];

    return Expense(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),
    );
  }
}

import 'expense_meta.dart';

import 'product.dart';



class Expense {

  const Expense({

    required this.id,

    required this.title,

    required this.accountingType,

    required this.accountingChannel,

    required this.inputCurrency,

    required this.amount,

    required this.amountCny,

    required this.amountUsd,

    required this.amountUzs,

    required this.usdToCnyRate,

    required this.usdToUzsRate,

    required this.note,

    required this.createdAt,

    this.batchId,

  });



  final String id;

  final String title;

  final String accountingType;

  final String accountingChannel;

  final String inputCurrency;

  final String amount;

  final double amountCny;

  final double amountUsd;

  final double amountUzs;

  final double usdToCnyRate;

  final double usdToUzsRate;

  final String note;

  final String? batchId;

  final DateTime createdAt;



  double? get amountValue {

    if (amountCny > 0) {

      return amountCny;

    }



    return parseProductAmount(amount);

  }



  String formattedAmountsLine({

    String cnySymbol = '¥',

    String usdSymbol = r'$',

    String uzsSuffix = ' сум',

  }) {

    final cny = amountCny > 0 ? amountCny : (amountValue ?? 0);

    final usd = amountUsd > 0 ? amountUsd : 0;

    final uzs = amountUzs > 0 ? amountUzs : 0;



    return formatCurrencyTotalsLine(

      totalCny: cny.toDouble(),

      totalUsd: usd.toDouble(),

      totalUzs: uzs.toDouble(),

      cnySymbol: cnySymbol,

      usdSymbol: usdSymbol,

      uzsSuffix: uzsSuffix,

    );

  }



  Expense copyWith({

    String? title,

    String? accountingType,

    String? accountingChannel,

    String? inputCurrency,

    String? amount,

    String? note,

    String? batchId,

    bool clearBatchId = false,

  }) {

    return Expense(

      id: id,

      title: title ?? this.title,

      accountingType: accountingType ?? this.accountingType,

      accountingChannel: accountingChannel ?? this.accountingChannel,

      inputCurrency: inputCurrency ?? this.inputCurrency,

      amount: amount ?? this.amount,

      amountCny: amountCny,

      amountUsd: amountUsd,

      amountUzs: amountUzs,

      usdToCnyRate: usdToCnyRate,

      usdToUzsRate: usdToUzsRate,

      note: note ?? this.note,

      batchId: clearBatchId ? null : (batchId ?? this.batchId),

      createdAt: createdAt,

    );

  }



  static double sumCny(Iterable<Expense> expenses) {

    return expenses.fold<double>(

      0,

      (sum, expense) =>

          sum +

          (expense.amountCny > 0

              ? expense.amountCny

              : (expense.amountValue ?? 0)),

    );

  }



  static double sumUsd(Iterable<Expense> expenses) {

    return expenses.fold<double>(0, (sum, expense) => sum + expense.amountUsd);

  }



  static double sumUzs(Iterable<Expense> expenses) {

    return expenses.fold<double>(0, (sum, expense) => sum + expense.amountUzs);

  }



  factory Expense.fromJson(Map<String, dynamic> json) {

    final rawCreatedAt = json['createdAt'] ?? json['created_at'];

    final parsedAmount = parseProductAmount(json['amount'] as String? ?? '');



    return Expense(

      id: '${json['id'] ?? ''}',

      title: json['title'] as String? ?? '',

      accountingType: normalizeExpenseAccountingType(

        json['accountingType'] as String? ?? json['accounting_type'] as String?,

      ),

      accountingChannel: normalizeExpenseAccountingChannel(

        json['accountingChannel'] as String? ??

            json['accounting_channel'] as String?,

      ),

      inputCurrency: normalizeExpenseInputCurrency(

        json['currency'] as String?,

      ),

      amount: json['amount'] as String? ?? '',

      amountCny:

          (json['amountCny'] as num?)?.toDouble() ??

          (json['amount_cny'] as num?)?.toDouble() ??

          parsedAmount ??

          0,

      amountUsd:

          (json['amountUsd'] as num?)?.toDouble() ??

          (json['amount_usd'] as num?)?.toDouble() ??

          0,

      amountUzs:

          (json['amountUzs'] as num?)?.toDouble() ??

          (json['amount_uzs'] as num?)?.toDouble() ??

          0,

      usdToCnyRate: _parseUsdToCnyRate(json),

      usdToUzsRate:

          (json['usdToUzsRate'] as num?)?.toDouble() ??

          (json['usd_to_uzs_rate'] as num?)?.toDouble() ??

          0,

      note: json['note'] as String? ?? '',

      batchId: _readOptionalExpenseId(json['batchId'] ?? json['batch_id']),

      createdAt:

          DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),

    );

  }

}



double _parseUsdToCnyRate(Map<String, dynamic> json) {
  final usdToCny = (json['usdToCnyRate'] as num?)?.toDouble() ??
      (json['usd_to_cny_rate'] as num?)?.toDouble();
  if (usdToCny != null && usdToCny > 0) {
    return usdToCny;
  }

  final legacy = (json['cnyToUsdRate'] as num?)?.toDouble() ??
      (json['cny_to_usd_rate'] as num?)?.toDouble() ??
      0;
  if (legacy <= 0) {
    return 0;
  }

  if (legacy < 2) {
    return 1 / legacy;
  }

  return legacy;
}

String? _readOptionalExpenseId(Object? value) {
  if (value == null) {
    return null;
  }

  final normalized = '$value'.trim();

  if (normalized.isEmpty || normalized == 'null') {
    return null;
  }

  return normalized;
}

String formatCurrencyTotalsLine({

  required double totalCny,

  required double totalUsd,

  required double totalUzs,

  String cnySymbol = '¥',

  String usdSymbol = r'$',

  String uzsSuffix = ' сум',

}) {

  return '${formatProductMoney(totalCny)} $cnySymbol → '

      '${formatProductMoney(totalUsd)} $usdSymbol → '

      '${formatProductMoney(totalUzs)}$uzsSuffix';

}


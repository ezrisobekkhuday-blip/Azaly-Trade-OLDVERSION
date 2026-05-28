import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/product.dart';

class ExpenseMonthGroup {
  const ExpenseMonthGroup({
    required this.year,
    required this.month,
    required this.expenses,
  });

  final int year;
  final int month;
  final List<Expense> expenses;

  String get key => expenseMonthKey(year, month);

  double get totalCny => Expense.sumCny(expenses);

  double get totalUsd => Expense.sumUsd(expenses);

  double get totalUzs => Expense.sumUzs(expenses);
}

String expenseMonthKey(int year, int month) {
  return '$year-${month.toString().padLeft(2, '0')}';
}

List<ExpenseMonthGroup> groupExpensesByMonth(List<Expense> expenses) {
  if (expenses.isEmpty) {
    return const [];
  }

  final sorted = List<Expense>.from(expenses)
    ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

  final buckets = <String, List<Expense>>{};
  final order = <String>[];

  for (final expense in sorted) {
    final key = expenseMonthKey(expense.createdAt.year, expense.createdAt.month);

    if (!buckets.containsKey(key)) {
      buckets[key] = <Expense>[];
      order.add(key);
    }

    buckets[key]!.add(expense);
  }

  return order.map((key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    return ExpenseMonthGroup(
      year: year,
      month: month,
      expenses: buckets[key]!,
    );
  }).toList();
}

String formatExpenseMonthTitle(AppLanguage language, int year, int month) {
  switch (language) {
    case AppLanguage.ru:
      return '${_russianMonthName(month)} $year';
    case AppLanguage.en:
      return '${_englishMonthName(month)} $year';
    case AppLanguage.zh:
      return '$year年$month月';
  }
}

String formatExpenseMonthSummaryLine(
  AppLanguage language,
  ExpenseMonthGroup group,
) {
  final count = group.expenses.length;
  final countLabel = '$count ${expenseCountWord(language, count)}';
  final totals = formatMonthCurrencyTotalsLine(
    totalCny: group.totalCny,
    totalUsd: group.totalUsd,
    totalUzs: group.totalUzs,
  );

  return '$countLabel • $totals';
}

String formatMonthCurrencyTotalsLine({
  required double totalCny,
  required double totalUsd,
  required double totalUzs,
}) {
  return '${formatProductMoney(totalCny)} ¥ • '
      '${formatProductMoney(totalUsd)} \$ • '
      '${formatProductMoney(totalUzs)} сум';
}

String expenseCountWord(AppLanguage language, int count) {
  switch (language) {
    case AppLanguage.ru:
      final mod10 = count % 10;
      final mod100 = count % 100;

      if (mod10 == 1 && mod100 != 11) {
        return 'расход';
      }

      if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
        return 'расхода';
      }

      return 'расходов';
    case AppLanguage.en:
      return count == 1 ? 'expense' : 'expenses';
    case AppLanguage.zh:
      return '条支出';
  }
}

String initialExpandedExpenseMonthKey(List<ExpenseMonthGroup> groups) {
  if (groups.isEmpty) {
    return '';
  }

  final now = DateTime.now();
  final currentKey = expenseMonthKey(now.year, now.month);

  for (final group in groups) {
    if (group.key == currentKey) {
      return currentKey;
    }
  }

  return groups.first.key;
}

String _russianMonthName(int month) {
  const names = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  return names[(month - 1).clamp(0, 11)];
}

String _englishMonthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return names[(month - 1).clamp(0, 11)];
}

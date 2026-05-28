import '../models/expense.dart';
import '../models/product.dart';

class BatchExpenseSummary {
  const BatchExpenseSummary({
    required this.expenses,
    required this.totalCny,
    required this.totalUsd,
    required this.totalUzs,
    required this.regularQuantity,
    required this.expensePerUnitCny,
  });

  final List<Expense> expenses;
  final double totalCny;
  final double totalUsd;
  final double totalUzs;
  final int regularQuantity;
  final double expensePerUnitCny;
}

List<Expense> expensesForBatch(List<Expense> allExpenses, String batchId) {
  final linked = allExpenses
      .where((expense) => expense.batchId == batchId)
      .toList()
    ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

  return linked;
}

int regularProductQuantityInBatch(List<Product> products) {
  var total = 0;

  for (final product in products) {
    if (product.batchItemType.isOrder) {
      continue;
    }

    total += product.quantity;
  }

  return total;
}

BatchExpenseSummary summarizeBatchExpenses({
  required List<Expense> allExpenses,
  required String batchId,
  required List<Product> batchProducts,
}) {
  final expenses = expensesForBatch(allExpenses, batchId);
  final totalCny = Expense.sumCny(expenses);
  final totalUsd = Expense.sumUsd(expenses);
  final totalUzs = Expense.sumUzs(expenses);
  final regularQuantity = regularProductQuantityInBatch(batchProducts);

  var expensePerUnitCny = 0.0;

  if (regularQuantity > 0 && totalCny > 0) {
    expensePerUnitCny = totalCny / regularQuantity;
  } else {
    for (final product in batchProducts) {
      if (!product.batchItemType.isOrder &&
          product.allocatedExpensePerUnitCny > 0) {
        expensePerUnitCny = product.allocatedExpensePerUnitCny;
        break;
      }
    }
  }

  return BatchExpenseSummary(
    expenses: expenses,
    totalCny: totalCny,
    totalUsd: totalUsd,
    totalUzs: totalUzs,
    regularQuantity: regularQuantity,
    expensePerUnitCny: expensePerUnitCny,
  );
}

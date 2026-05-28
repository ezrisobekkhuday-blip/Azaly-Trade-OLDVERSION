import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/batch_expense_summary.dart';
import 'batch_expense_currency_chips.dart';
import 'expense_details_fields.dart';

class BatchExpensesDetailsLabels {
  const BatchExpensesDetailsLabels({
    required this.title,
    required this.emptyLabel,
    required this.perUnitLabel,
    required this.regularPiecesLabel,
    required this.dateLabel,
    required this.accountingTypeLabel,
    required this.accountingChannelLabel,
    required this.inputCurrencyLabel,
  });

  final String title;
  final String emptyLabel;
  final String perUnitLabel;
  final String regularPiecesLabel;
  final String dateLabel;
  final String accountingTypeLabel;
  final String accountingChannelLabel;
  final String inputCurrencyLabel;
}

Future<void> showBatchExpensesDetails({
  required BuildContext context,
  required AppLanguage language,
  required String batchName,
  required List<Expense> allExpenses,
  required String batchId,
  required List<Product> batchProducts,
  required BatchExpensesDetailsLabels labels,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final child = BatchExpensesDetailsSheet(
    language: language,
    batchName: batchName,
    allExpenses: allExpenses,
    batchId: batchId,
    batchProducts: batchProducts,
    labels: labels,
  );

  if (width >= 720) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
          child: child,
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.92,
        child: child,
      ),
    ),
  );
}

class BatchExpensesDetailsSheet extends StatelessWidget {
  const BatchExpensesDetailsSheet({
    super.key,
    required this.language,
    required this.batchName,
    required this.allExpenses,
    required this.batchId,
    required this.batchProducts,
    required this.labels,
  });

  final AppLanguage language;
  final String batchName;
  final List<Expense> allExpenses;
  final String batchId;
  final List<Product> batchProducts;
  final BatchExpensesDetailsLabels labels;

  @override
  Widget build(BuildContext context) {
    final summary = summarizeBatchExpenses(
      allExpenses: allExpenses,
      batchId: batchId,
      batchProducts: batchProducts,
    );
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.background, AppColors.backgroundSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          batchName,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BatchExpenseCurrencyTotalsLine(
                    cny: summary.totalCny,
                    usd: summary.totalUsd,
                    uzs: summary.totalUzs,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${labels.perUnitLabel}: ${formatProductMoney(summary.expensePerUnitCny)} ¥',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (summary.regularQuantity > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${labels.regularPiecesLabel}: ${summary.regularQuantity}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: summary.expenses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          labels.emptyLabel,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      itemCount: summary.expenses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _BatchExpenseDetailsCard(
                          expense: summary.expenses[index],
                          language: language,
                          labels: labels,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchExpenseDetailsCard extends StatelessWidget {
  const _BatchExpenseDetailsCard({
    required this.expense,
    required this.language,
    required this.labels,
  });

  final Expense expense;
  final AppLanguage language;
  final BatchExpensesDetailsLabels labels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cnyAmount = expense.amountCny > 0
        ? expense.amountCny
        : (expense.amountValue ?? 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${labels.dateLabel}: ${formatProductDate(expense.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ExpenseMetaBadges(
            language: language,
            accountingType: expense.accountingType,
            accountingChannel: expense.accountingChannel,
            inputCurrency: expense.inputCurrency,
          ),
          const SizedBox(height: 12),
          BatchExpenseCurrencyChips(
            cny: cnyAmount,
            usd: expense.amountUsd,
            uzs: expense.amountUzs,
          ),
          if (expense.note.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              expense.note,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

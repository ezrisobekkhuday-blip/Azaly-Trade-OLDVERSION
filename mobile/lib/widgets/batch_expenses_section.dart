import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/batch_expense_summary.dart';
import 'batch_expense_currency_chips.dart';
import 'batch_expenses_details_sheet.dart';

class BatchExpensesSectionLabels {
  const BatchExpensesSectionLabels({
    required this.title,
    required this.emptyLabel,
    required this.perUnitLabel,
    required this.regularPiecesLabel,
    required this.detailsButtonLabel,
    required this.detailsTitle,
    required this.detailsDateLabel,
    required this.detailsAccountingTypeLabel,
    required this.detailsAccountingChannelLabel,
    required this.detailsInputCurrencyLabel,
  });

  final String title;
  final String emptyLabel;
  final String perUnitLabel;
  final String regularPiecesLabel;
  final String detailsButtonLabel;
  final String detailsTitle;
  final String detailsDateLabel;
  final String detailsAccountingTypeLabel;
  final String detailsAccountingChannelLabel;
  final String detailsInputCurrencyLabel;

  BatchExpensesDetailsLabels toDetailsLabels() {
    return BatchExpensesDetailsLabels(
      title: detailsTitle,
      emptyLabel: emptyLabel,
      perUnitLabel: perUnitLabel,
      regularPiecesLabel: regularPiecesLabel,
      dateLabel: detailsDateLabel,
      accountingTypeLabel: detailsAccountingTypeLabel,
      accountingChannelLabel: detailsAccountingChannelLabel,
      inputCurrencyLabel: detailsInputCurrencyLabel,
    );
  }
}

class BatchExpensesSection extends StatelessWidget {
  const BatchExpensesSection({
    super.key,
    required this.language,
    required this.batchName,
    required this.allExpenses,
    required this.batchId,
    required this.batchProducts,
    required this.labels,
    this.accentColor = AppColors.danger,
  });

  final AppLanguage language;
  final String batchName;
  final List<Expense> allExpenses;
  final String batchId;
  final List<Product> batchProducts;
  final BatchExpensesSectionLabels labels;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final summary = summarizeBatchExpenses(
      allExpenses: allExpenses,
      batchId: batchId,
      batchProducts: batchProducts,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: accentColor.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    labels.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (summary.expenses.isEmpty)
              Text(
                labels.emptyLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              )
            else ...[
              BatchExpenseCurrencyTotalsLine(
                cny: summary.totalCny,
                usd: summary.totalUsd,
                uzs: summary.totalUzs,
                compact: true,
              ),
              const SizedBox(height: 10),
              Text(
                '${labels.perUnitLabel}: ${formatProductMoney(summary.expensePerUnitCny)} ¥',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (summary.regularQuantity > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${labels.regularPiecesLabel}: ${summary.regularQuantity}',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => showBatchExpensesDetails(
                    context: context,
                    language: language,
                    batchName: batchName,
                    allExpenses: allExpenses,
                    batchId: batchId,
                    batchProducts: batchProducts,
                    labels: labels.toDetailsLabels(),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(labels.detailsButtonLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'batch_expense_currency_chips.dart';

/// Metrics shown in a batch accordion header (goods only, not batch expenses).
class PortingBatchHeaderSummary {
  const PortingBatchHeaderSummary({
    required this.countsLine,
    required this.goodsTotalsTitle,
    required this.totalCny,
    required this.totalUsd,
    required this.totalUzs,
  });

  /// e.g. "114 товаров • 17252 шт"
  final String countsLine;

  /// e.g. "Итог товаров"
  final String goodsTotalsTitle;

  final double totalCny;
  final double totalUsd;
  final double totalUzs;
}

class PortingBatchHeaderSummaryView extends StatelessWidget {
  const PortingBatchHeaderSummaryView({
    super.key,
    required this.summary,
  });

  final PortingBatchHeaderSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasGoodsTotal =
        summary.totalCny > 0 ||
        summary.totalUsd > 0 ||
        summary.totalUzs > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.countsLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.25,
          ),
        ),
        if (hasGoodsTotal) ...[
          const SizedBox(height: 6),
          Text(
            summary.goodsTotalsTitle,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          BatchExpenseCurrencyTotalsLine(
            cny: summary.totalCny,
            usd: summary.totalUsd,
            uzs: summary.totalUzs,
            compact: true,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
              color: AppColors.primary,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }
}

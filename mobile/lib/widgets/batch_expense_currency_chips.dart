import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

/// Readable single-line (wraps on narrow screens) totals: ¥ → $ → сум.
class BatchExpenseCurrencyTotalsLine extends StatelessWidget {
  const BatchExpenseCurrencyTotalsLine({
    super.key,
    required this.cny,
    required this.usd,
    required this.uzs,
    this.style,
    this.compact = false,
  });

  final double cny;
  final double usd;
  final double uzs;
  final TextStyle? style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = style ??
        textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.35,
          color: AppColors.danger,
          fontSize: compact ? 15 : 16,
        );

    return Text(
      formatCurrencyTotalsLine(
        totalCny: cny,
        totalUsd: usd,
        totalUzs: uzs,
      ),
      style: baseStyle,
      softWrap: true,
    );
  }
}

class BatchExpenseCurrencyChips extends StatelessWidget {
  const BatchExpenseCurrencyChips({
    super.key,
    required this.cny,
    required this.usd,
    required this.uzs,
    this.compact = false,
  });

  final double cny;
  final double usd;
  final double uzs;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chipWidth = compact ? 88.0 : 104.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BatchExpenseCurrencyChip(
          label: 'CNY',
          amount: cny,
          accentColor: AppColors.primary,
          width: chipWidth,
          compact: compact,
        ),
        _BatchExpenseCurrencyChip(
          label: 'USD',
          amount: usd,
          accentColor: AppColors.accent,
          width: chipWidth,
          compact: compact,
        ),
        _BatchExpenseCurrencyChip(
          label: 'UZS',
          amount: uzs,
          accentColor: AppColors.danger,
          width: chipWidth,
          compact: compact,
        ),
      ],
    );
  }
}

class _BatchExpenseCurrencyChip extends StatelessWidget {
  const _BatchExpenseCurrencyChip({
    required this.label,
    required this.amount,
    required this.accentColor,
    required this.width,
    this.compact = false,
  });

  final String label;
  final double amount;
  final Color accentColor;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatProductMoney(amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 14 : 16,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_strings.dart';
import '../models/expense_meta.dart';
import '../theme/app_theme.dart';
import 'suggestion_field.dart';

class ExpenseDetailsFields extends StatelessWidget {
  const ExpenseDetailsFields({
    super.key,
    required this.language,
    required this.categoryLabel,
    required this.categoryHint,
    required this.categorySuggestions,
    required this.quickLabel,
    required this.quickItems,
    required this.noteLabel,
    required this.titleController,
    required this.amountController,
    required this.noteController,
    required this.accountingType,
    required this.accountingChannel,
    required this.inputCurrency,
    required this.onAccountingTypeChanged,
    required this.onAccountingChannelChanged,
    required this.onInputCurrencyChanged,
  });

  final AppLanguage language;
  final String categoryLabel;
  final String categoryHint;
  final List<String> categorySuggestions;
  final String quickLabel;
  final List<String> quickItems;
  final String noteLabel;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String accountingType;
  final String accountingChannel;
  final String inputCurrency;
  final ValueChanged<String> onAccountingTypeChanged;
  final ValueChanged<String> onAccountingChannelChanged;
  final ValueChanged<String> onInputCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SuggestionField(
          controller: titleController,
          label: categoryLabel,
          hint: categoryHint,
          suggestions: categorySuggestions,
          quickGroups: [SuggestionGroup(label: quickLabel, items: quickItems)],
        ),
        const SizedBox(height: 12),
        _ExpenseOptionSection(
          label: expenseAccountingTypeFieldLabel(language),
          values: ExpenseAccountingType.values,
          selected: accountingType,
          labelBuilder: (value) => expenseAccountingTypeLabel(value, language),
          onSelected: onAccountingTypeChanged,
        ),
        const SizedBox(height: 12),
        _ExpenseOptionSection(
          label: expenseAccountingChannelFieldLabel(language),
          values: ExpenseAccountingChannel.values,
          selected: accountingChannel,
          labelBuilder: (value) =>
              expenseAccountingChannelLabel(value, language),
          onSelected: onAccountingChannelChanged,
        ),
        const SizedBox(height: 12),
        _ExpenseOptionSection(
          label: expenseInputCurrencyFieldLabel(language),
          values: ExpenseInputCurrency.values,
          selected: inputCurrency,
          labelBuilder: expenseInputCurrencyLabel,
          onSelected: onInputCurrencyChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
          ],
          decoration: InputDecoration(
            labelText: expenseAmountFieldLabel(language, inputCurrency),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: noteLabel),
        ),
      ],
    );
  }
}

class _ExpenseOptionSection extends StatelessWidget {
  const _ExpenseOptionSection({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String selected;
  final String Function(String value) labelBuilder;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = value == selected;
            return ChoiceChip(
              label: Text(labelBuilder(value)),
              selected: isSelected,
              onSelected: (_) => onSelected(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ExpenseMetaBadges extends StatelessWidget {
  const ExpenseMetaBadges({
    super.key,
    required this.language,
    required this.accountingType,
    required this.accountingChannel,
    required this.inputCurrency,
  });

  final AppLanguage language;
  final String accountingType;
  final String accountingChannel;
  final String inputCurrency;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget badge(String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        badge(
          expenseAccountingTypeLabel(accountingType, language),
          AppColors.accent,
        ),
        badge(
          expenseAccountingChannelLabel(accountingChannel, language),
          AppColors.primary,
        ),
        badge(
          expenseInputCurrencyLabel(inputCurrency),
          AppColors.danger,
        ),
      ],
    );
  }
}

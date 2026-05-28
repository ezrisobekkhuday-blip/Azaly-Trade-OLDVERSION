import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/expense_month_groups.dart';

typedef ExpenseCardBuilder =
    Widget Function(Expense expense);

class ExpensesMonthlyPanel extends StatefulWidget {
  const ExpensesMonthlyPanel({
    super.key,
    required this.expenses,
    required this.language,
    required this.expenseCardBuilder,
  });

  final List<Expense> expenses;
  final AppLanguage language;
  final ExpenseCardBuilder expenseCardBuilder;

  @override
  State<ExpensesMonthlyPanel> createState() => _ExpensesMonthlyPanelState();
}

class _ExpensesMonthlyPanelState extends State<ExpensesMonthlyPanel> {
  final Set<String> _expandedMonthKeys = <String>{};
  bool _expandedMonthsInitialized = false;

  @override
  void didUpdateWidget(covariant ExpensesMonthlyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.expenses.length != widget.expenses.length) {
      _ensureExpandedMonths(groupExpensesByMonth(widget.expenses), force: false);
    }
  }

  void _ensureExpandedMonths(
    List<ExpenseMonthGroup> groups, {
    bool force = false,
  }) {
    if (groups.isEmpty) {
      return;
    }

    if (_expandedMonthsInitialized && !force) {
      return;
    }

    _expandedMonthsInitialized = true;
    _expandedMonthKeys
      ..clear()
      ..add(initialExpandedExpenseMonthKey(groups));
  }

  void _toggleMonth(String key) {
    setState(() {
      if (_expandedMonthKeys.contains(key)) {
        _expandedMonthKeys.remove(key);
      } else {
        _expandedMonthKeys.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupExpensesByMonth(widget.expenses);
    _ensureExpandedMonths(groups);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups)
          _ExpenseMonthAccordionSection(
            key: ValueKey('expense-month-${group.key}'),
            title: formatExpenseMonthTitle(
              widget.language,
              group.year,
              group.month,
            ),
            summaryLine: formatExpenseMonthSummaryLine(widget.language, group),
            expanded: _expandedMonthKeys.contains(group.key),
            onToggle: () => _toggleMonth(group.key),
            expenses: group.expenses,
            expenseCardBuilder: widget.expenseCardBuilder,
          ),
      ],
    );
  }
}

class _ExpenseMonthAccordionSection extends StatefulWidget {
  const _ExpenseMonthAccordionSection({
    super.key,
    required this.title,
    required this.summaryLine,
    required this.expanded,
    required this.onToggle,
    required this.expenses,
    required this.expenseCardBuilder,
  });

  final String title;
  final String summaryLine;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Expense> expenses;
  final ExpenseCardBuilder expenseCardBuilder;

  @override
  State<_ExpenseMonthAccordionSection> createState() =>
      _ExpenseMonthAccordionSectionState();
}

class _ExpenseMonthAccordionSectionState
    extends State<_ExpenseMonthAccordionSection> {
  bool _hasBeenExpanded = false;

  @override
  void didUpdateWidget(covariant _ExpenseMonthAccordionSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.expanded) {
      _hasBeenExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showBody = widget.expanded;
    final keepBodyMounted = _hasBeenExpanded;

    if (widget.expanded) {
      _hasBeenExpanded = true;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surfaceStrong.withValues(alpha: 0.94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.expanded
                ? AppColors.danger.withValues(alpha: 0.38)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(
                alpha: widget.expanded ? 0.08 : 0.04,
              ),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.summaryLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(
                            alpha: widget.expanded ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.28),
                          ),
                        ),
                        child: AnimatedRotation(
                          turns: widget.expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: const Icon(
                            Icons.expand_more,
                            size: 22,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (keepBodyMounted)
              Offstage(
                offstage: !showBody,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(
                        height: 1,
                        color: AppColors.danger.withValues(alpha: 0.16),
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0; index < widget.expenses.length; index += 1)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == widget.expenses.length - 1 ? 0 : 14,
                          ),
                          child: widget.expenseCardBuilder(widget.expenses[index]),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

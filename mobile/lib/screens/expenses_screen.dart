import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/section_cards.dart';
import '../widgets/suggestion_field.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _tabLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расходы';
      case AppLanguage.en:
        return 'Expenses';
      case AppLanguage.zh:
        return '支出';
    }
  }

  String _heroDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Здесь можно записывать все расходы: доставка, дорога, еда, упаковка и другие траты.';
      case AppLanguage.en:
        return 'Track all expenses here: delivery, transport, food, packaging, and other costs.';
      case AppLanguage.zh:
        return '在这里记录所有支出：运费、路费、餐饮、包装和其他费用。';
    }
  }

  String _countLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Всего расходов';
      case AppLanguage.en:
        return 'Total expenses';
      case AppLanguage.zh:
        return '支出总数';
    }
  }

  String _sumLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Общая сумма';
      case AppLanguage.en:
        return 'Total amount';
      case AppLanguage.zh:
        return '总金额';
    }
  }

  String _composerTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Добавить расход';
      case AppLanguage.en:
        return 'Add expense';
      case AppLanguage.zh:
        return '添加支出';
    }
  }

  String _composerDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Напиши название расхода, сумму и при желании заметку.';
      case AppLanguage.en:
        return 'Enter the expense title, amount, and an optional note.';
      case AppLanguage.zh:
        return '填写支出名称、金额，以及可选备注。';
    }
  }

  String _titleLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Категория расхода';
      case AppLanguage.en:
        return 'Expense category';
      case AppLanguage.zh:
        return '支出类别';
    }
  }

  String _titleHint(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Например: аренда, гостиница, доставка';
      case AppLanguage.en:
        return 'Example: rent, hotel, delivery';
      case AppLanguage.zh:
        return '例如：房租、酒店、运费';
    }
  }

  String _categoryQuickLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Популярные категории';
      case AppLanguage.en:
        return 'Popular categories';
      case AppLanguage.zh:
        return '常用类别';
    }
  }

  List<String> _popularCategories(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return const [
          'Аренда',
          'Гостиница',
          'Доставка',
          'Дорога',
          'Еда',
          'Такси',
          'Упаковка',
          'Реклама',
          'Связь',
          'Склад',
        ];
      case AppLanguage.en:
        return const [
          'Rent',
          'Hotel',
          'Delivery',
          'Transport',
          'Food',
          'Taxi',
          'Packaging',
          'Ads',
          'Communication',
          'Warehouse',
        ];
      case AppLanguage.zh:
        return const [
          '房租',
          '酒店',
          '运费',
          '路费',
          '餐饮',
          '打车',
          '包装',
          '广告',
          '通讯',
          '仓库',
        ];
    }
  }

  List<String> _categorySuggestions(AppLanguage language) {
    final items = <String>[];
    final seen = <String>{};

    void addItem(String value) {
      final trimmed = value.trim();
      final key = trimmed.toLowerCase();
      if (trimmed.isEmpty || !seen.add(key)) {
        return;
      }
      items.add(trimmed);
    }

    for (final item in _popularCategories(language)) {
      addItem(item);
    }

    for (final expense in widget.store.expenses) {
      addItem(expense.title);
    }

    return items;
  }

  String _amountLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Сумма';
      case AppLanguage.en:
        return 'Amount';
      case AppLanguage.zh:
        return '金额';
    }
  }

  String _noteLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Заметка';
      case AppLanguage.en:
        return 'Note';
      case AppLanguage.zh:
        return '备注';
    }
  }

  String _saveExpenseLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Сохранить расход';
      case AppLanguage.en:
        return 'Save expense';
      case AppLanguage.zh:
        return '保存支出';
    }
  }

  String _expenseSavedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход сохранён.';
      case AppLanguage.en:
        return 'Expense saved.';
      case AppLanguage.zh:
        return '支出已保存。';
    }
  }

  String _expenseUpdatedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход обновлён.';
      case AppLanguage.en:
        return 'Expense updated.';
      case AppLanguage.zh:
        return '支出已更新。';
    }
  }

  String _expenseDeletedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход удалён.';
      case AppLanguage.en:
        return 'Expense deleted.';
      case AppLanguage.zh:
        return '支出已删除。';
    }
  }

  String _cannotSaveExpenseLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось сохранить расход.';
      case AppLanguage.en:
        return 'Failed to save expense.';
      case AppLanguage.zh:
        return '无法保存支出。';
    }
  }

  String _cannotUpdateExpenseLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось обновить расход.';
      case AppLanguage.en:
        return 'Failed to update expense.';
      case AppLanguage.zh:
        return '无法更新支出。';
    }
  }

  String _cannotDeleteExpenseLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось удалить расход.';
      case AppLanguage.en:
        return 'Failed to delete expense.';
      case AppLanguage.zh:
        return '无法删除支出。';
    }
  }

  String _deleteTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Удалить расход?';
      case AppLanguage.en:
        return 'Delete expense?';
      case AppLanguage.zh:
        return '删除支出？';
    }
  }

  String _deleteMessage(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Этот расход будет удалён без возможности восстановления.';
      case AppLanguage.en:
        return 'This expense will be deleted permanently.';
      case AppLanguage.zh:
        return '该支出将被永久删除。';
    }
  }

  String _emptyTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Пока нет расходов';
      case AppLanguage.en:
        return 'No expenses yet';
      case AppLanguage.zh:
        return '暂时没有支出';
    }
  }

  String _emptyDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Добавь первый расход, и он появится в этом списке.';
      case AppLanguage.en:
        return 'Add your first expense and it will appear in this list.';
      case AppLanguage.zh:
        return '添加第一条支出后，它会显示在这里。';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveExpense() async {
    final strings = AppStrings.of(context);
    final title = _titleController.text.trim();
    final amount = _amountController.text.trim();

    if (title.isEmpty || amount.isEmpty) {
      _showMessage(_cannotSaveExpenseLabel(strings.language));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.store.createExpense(
        title: title,
        amount: amount,
        note: _noteController.text,
      );

      if (!mounted) {
        return;
      }

      _titleController.clear();
      _amountController.clear();
      _noteController.clear();
      _showMessage(_expenseSavedLabel(strings.language));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: _cannotSaveExpenseLabel(strings.language),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseEditorSheet(
        expense: expense,
        titleHint: _titleHint(AppStrings.of(context).language),
        quickLabel: _categoryQuickLabel(AppStrings.of(context).language),
        suggestions: _categorySuggestions(AppStrings.of(context).language),
        quickItems: _popularCategories(AppStrings.of(context).language),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    try {
      await widget.store.updateExpense(updated);
      if (mounted) {
        _showMessage(_expenseUpdatedLabel(AppStrings.of(context).language));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: _cannotUpdateExpenseLabel(
            AppStrings.of(context).language,
          ),
        ),
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_deleteTitle(strings.language)),
        content: Text(_deleteMessage(strings.language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.store.deleteExpense(expense.id);
      if (mounted) {
        _showMessage(_expenseDeletedLabel(strings.language));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: _cannotDeleteExpenseLabel(strings.language),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final language = strings.language;
    final expenses = List<Expense>.from(widget.store.expenses)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final totalAmount = expenses.fold<double>(
      0,
      (sum, expense) => sum + (expense.amountValue ?? 0),
    );

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            SectionHeroCard(
              badge: _tabLabel(language).toUpperCase(),
              badgeColor: AppColors.danger,
              title: _tabLabel(language),
              description: _heroDescription(language),
              count: expenses.length,
              countLabel: _countLabel(language),
              colors: const [Color(0x24FF7D93), Color(0x147C92FF)],
            ),
            const SizedBox(height: 18),
            _ExpenseComposerCard(
              titleLabel: _composerTitle(language),
              description: _composerDescription(language),
              titleFieldLabel: _titleLabel(language),
              titleFieldHint: _titleHint(language),
              titleSuggestions: _categorySuggestions(language),
              quickLabel: _categoryQuickLabel(language),
              quickItems: _popularCategories(language),
              amountFieldLabel: _amountLabel(language),
              noteFieldLabel: _noteLabel(language),
              saveLabel: _saveExpenseLabel(language),
              titleController: _titleController,
              amountController: _amountController,
              noteController: _noteController,
              isSaving: _isSaving,
              onSave: _saveExpense,
            ),
            const SizedBox(height: 18),
            _ExpenseTotalCard(
              countLabel: _countLabel(language),
              amountLabel: _sumLabel(language),
              count: expenses.length,
              totalAmount: totalAmount,
            ),
            const SizedBox(height: 18),
            if (expenses.isEmpty)
              EmptyStateCard(
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.danger,
                title: _emptyTitle(language),
                description: _emptyDescription(language),
              )
            else
              ...expenses.map(
                (expense) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ExpenseCard(
                    expense: expense,
                    onEdit: () => _editExpense(expense),
                    onDelete: () => _deleteExpense(expense),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseComposerCard extends StatelessWidget {
  const _ExpenseComposerCard({
    required this.titleLabel,
    required this.description,
    required this.titleFieldLabel,
    required this.titleFieldHint,
    required this.titleSuggestions,
    required this.quickLabel,
    required this.quickItems,
    required this.amountFieldLabel,
    required this.noteFieldLabel,
    required this.saveLabel,
    required this.titleController,
    required this.amountController,
    required this.noteController,
    required this.isSaving,
    required this.onSave,
  });

  final String titleLabel;
  final String description;
  final String titleFieldLabel;
  final String titleFieldHint;
  final List<String> titleSuggestions;
  final String quickLabel;
  final List<String> quickItems;
  final String amountFieldLabel;
  final String noteFieldLabel;
  final String saveLabel;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleLabel,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SuggestionField(
            controller: titleController,
            label: titleFieldLabel,
            hint: titleFieldHint,
            suggestions: titleSuggestions,
            quickGroups: [
              SuggestionGroup(label: quickLabel, items: quickItems),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
            ],
            decoration: InputDecoration(labelText: amountFieldLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: noteFieldLabel),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF08110F),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: isSaving ? null : onSave,
              child: Text(saveLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTotalCard extends StatelessWidget {
  const _ExpenseTotalCard({
    required this.countLabel,
    required this.amountLabel,
    required this.count,
    required this.totalAmount,
  });

  final String countLabel;
  final String amountLabel;
  final int count;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ExpenseStatBox(label: countLabel, value: '$count'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ExpenseStatBox(
            label: amountLabel,
            value: totalAmount <= 0 ? '0' : formatProductMoney(totalAmount),
            highlighted: true,
          ),
        ),
      ],
    );
  }
}

class _ExpenseStatBox extends StatelessWidget {
  const _ExpenseStatBox({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlighted
              ? [
                  AppColors.danger.withValues(alpha: 0.16),
                  AppColors.surfaceStrong,
                ]
              : [AppColors.surfaceStrong, AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlighted ? AppColors.danger : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ExpenseMenuAction { edit, delete }

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatProductDate(expense.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  expense.amountValue == null
                      ? expense.amount
                      : formatProductMoney(expense.amountValue!),
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_ExpenseMenuAction>(
                tooltip: '',
                padding: EdgeInsets.zero,
                color: const Color(0xF411182B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.more_horiz),
                onSelected: (action) {
                  switch (action) {
                    case _ExpenseMenuAction.edit:
                      onEdit();
                      break;
                    case _ExpenseMenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_ExpenseMenuAction>(
                    value: _ExpenseMenuAction.edit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(strings.t('edit')),
                      ],
                    ),
                  ),
                  PopupMenuItem<_ExpenseMenuAction>(
                    value: _ExpenseMenuAction.delete,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strings.t('delete'),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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

class _ExpenseEditorSheet extends StatefulWidget {
  const _ExpenseEditorSheet({
    required this.expense,
    required this.titleHint,
    required this.quickLabel,
    required this.suggestions,
    required this.quickItems,
  });

  final Expense expense;
  final String titleHint;
  final String quickLabel;
  final List<String> suggestions;
  final List<String> quickItems;

  @override
  State<_ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<_ExpenseEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String _titleLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Название расхода';
      case AppLanguage.en:
        return 'Expense title';
      case AppLanguage.zh:
        return '支出名称';
    }
  }

  String _amountLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Сумма';
      case AppLanguage.en:
        return 'Amount';
      case AppLanguage.zh:
        return '金额';
    }
  }

  String _noteLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Заметка';
      case AppLanguage.en:
        return 'Note';
      case AppLanguage.zh:
        return '备注';
    }
  }

  String _sheetTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Редактировать расход';
      case AppLanguage.en:
        return 'Edit expense';
      case AppLanguage.zh:
        return '编辑支出';
    }
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount);
    _noteController = TextEditingController(text: widget.expense.note);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final language = strings.language;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sheetTitle(language),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SuggestionField(
              controller: _titleController,
              label: _titleLabel(language),
              hint: widget.titleHint,
              suggestions: widget.suggestions,
              quickGroups: [
                SuggestionGroup(
                  label: widget.quickLabel,
                  items: widget.quickItems,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
              ],
              decoration: InputDecoration(labelText: _amountLabel(language)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: _noteLabel(language)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.t('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF08110F),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(
                        widget.expense.copyWith(
                          title: _titleController.text.trim(),
                          amount: _amountController.text.trim(),
                          note: _noteController.text.trim(),
                        ),
                      );
                    },
                    child: Text(strings.t('save')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

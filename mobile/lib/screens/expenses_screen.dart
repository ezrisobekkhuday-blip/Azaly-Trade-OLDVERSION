import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/expense_meta.dart';
import '../models/product_batch.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/attach_expense_to_batch_dialog.dart';
import '../widgets/expense_details_fields.dart';
import '../widgets/expenses_monthly_panel.dart';
import '../widgets/section_cards.dart';

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
  String _accountingType = ExpenseAccountingType.notSelected;
  String _accountingChannel = ExpenseAccountingChannel.notSelected;
  String _inputCurrency = ExpenseInputCurrency.cny;

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

  String _totalCnyLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Общая сумма CNY';
      case AppLanguage.en:
        return 'Total CNY';
      case AppLanguage.zh:
        return 'CNY 总金额';
    }
  }

  String _totalUsdLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Общая сумма USD';
      case AppLanguage.en:
        return 'Total USD';
      case AppLanguage.zh:
        return 'USD 总金额';
    }
  }

  String _totalUzsLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Общая сумма UZS';
      case AppLanguage.en:
        return 'Total UZS';
      case AppLanguage.zh:
        return 'UZS 总金额';
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
        return 'Выбери категорию, тип и канал учёта, валюту ввода, сумму и при желании заметку.';
      case AppLanguage.en:
        return 'Choose category, accounting type and channel, input currency, amount, and an optional note.';
      case AppLanguage.zh:
        return '选择类别、记账类型和渠道、输入货币、金额，以及可选备注。';
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

  String _expenseAttachedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход привязан к партии, себестоимость пересчитана.';
      case AppLanguage.en:
        return 'Expense attached to batch. Unit costs recalculated.';
      case AppLanguage.zh:
        return '支出已关联到批次，单位成本已重新计算。';
    }
  }

  String _expenseBatchChangedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партия расхода изменена, себестоимость пересчитана.';
      case AppLanguage.en:
        return 'Expense batch updated. Unit costs recalculated.';
      case AppLanguage.zh:
        return '支出批次已更新，单位成本已重新计算。';
    }
  }

  String _expenseDetachedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход откреплён от партии, себестоимость пересчитана.';
      case AppLanguage.en:
        return 'Expense detached from batch. Unit costs recalculated.';
      case AppLanguage.zh:
        return '支出已从批次解除关联，单位成本已重新计算。';
    }
  }

  String _detachExpenseTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить расход от партии?';
      case AppLanguage.en:
        return 'Detach expense from batch?';
      case AppLanguage.zh:
        return '从批次解除关联？';
    }
  }

  String _detachExpenseConfirmLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить';
      case AppLanguage.en:
        return 'Detach';
      case AppLanguage.zh:
        return '解除关联';
    }
  }

  String _cannotDetachExpenseLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось открепить расход от партии.';
      case AppLanguage.en:
        return 'Failed to detach expense from batch.';
      case AppLanguage.zh:
        return '无法从批次解除关联。';
    }
  }

  String _cannotChangeExpenseBatchLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось изменить партию расхода.';
      case AppLanguage.en:
        return 'Failed to change expense batch.';
      case AppLanguage.zh:
        return '无法更改支出批次。';
    }
  }

  String _cannotAttachExpenseLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось привязать расход к партии.';
      case AppLanguage.en:
        return 'Failed to attach expense to batch.';
      case AppLanguage.zh:
        return '无法将支出关联到批次。';
    }
  }

  String _expenseBatchLabel(AppLanguage language, String batchName) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партия: $batchName';
      case AppLanguage.en:
        return 'Batch: $batchName';
      case AppLanguage.zh:
        return '批次：$batchName';
    }
  }

  String? _batchNameForExpense(Expense expense) {
    final batchId = expense.batchId;

    if (batchId == null || batchId.isEmpty) {
      return null;
    }

    for (final batch in widget.store.batches) {
      if (batch.id == batchId) {
        return batch.name;
      }
    }

    return null;
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
        accountingType: _accountingType,
        accountingChannel: _accountingChannel,
        currency: _inputCurrency,
      );

      if (!mounted) {
        return;
      }

      _titleController.clear();
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _accountingType = ExpenseAccountingType.notSelected;
        _accountingChannel = ExpenseAccountingChannel.notSelected;
        _inputCurrency = ExpenseInputCurrency.cny;
      });
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
        language: AppStrings.of(context).language,
        categoryLabel: _titleLabel(AppStrings.of(context).language),
        titleHint: _titleHint(AppStrings.of(context).language),
        quickLabel: _categoryQuickLabel(AppStrings.of(context).language),
        suggestions: _categorySuggestions(AppStrings.of(context).language),
        quickItems: _popularCategories(AppStrings.of(context).language),
        noteLabel: _noteLabel(AppStrings.of(context).language),
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

  List<ProductBatch> _sortedBatches() {
    return List<ProductBatch>.from(widget.store.batches)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  Future<String?> _pickExpenseBatchId({
    required AppLanguage language,
    required AttachExpenseToBatchDialogMode mode,
    String? initialBatchId,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AttachExpenseToBatchDialog(
        language: language,
        batches: _sortedBatches(),
        mode: mode,
        initialBatchId: initialBatchId,
      ),
    );
  }

  Future<void> _attachExpenseToBatch(Expense expense) async {
    final language = AppStrings.of(context).language;
    final batchId = await _pickExpenseBatchId(
      language: language,
      mode: AttachExpenseToBatchDialogMode.attach,
    );

    if (batchId == null || !mounted) {
      return;
    }

    try {
      await widget.store.attachExpenseToBatch(
        expenseId: expense.id,
        batchId: batchId,
      );

      if (mounted) {
        _showMessage(_expenseAttachedLabel(language));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: _cannotAttachExpenseLabel(language),
        ),
      );
    }
  }

  Future<void> _changeExpenseBatch(Expense expense) async {
    final language = AppStrings.of(context).language;
    final batchId = await _pickExpenseBatchId(
      language: language,
      mode: AttachExpenseToBatchDialogMode.change,
      initialBatchId: expense.batchId,
    );

    if (batchId == null || !mounted) {
      return;
    }

    if (batchId == expense.batchId) {
      return;
    }

    try {
      await widget.store.attachExpenseToBatch(
        expenseId: expense.id,
        batchId: batchId,
      );

      if (mounted) {
        _showMessage(_expenseBatchChangedLabel(language));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: _cannotChangeExpenseBatchLabel(language),
        ),
      );
    }
  }

  Future<void> _detachExpenseFromBatch(Expense expense) async {
    final strings = AppStrings.of(context);
    final language = strings.language;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_detachExpenseTitle(language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_detachExpenseConfirmLabel(language)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.store.detachExpenseFromBatch(expense.id);

      if (mounted) {
        _showMessage(_expenseDetachedLabel(language));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: _cannotDetachExpenseLabel(language),
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
    final expenses = List<Expense>.from(widget.store.expenses);
    final totalCny = Expense.sumCny(expenses);
    final totalUsd = Expense.sumUsd(expenses);
    final totalUzs = Expense.sumUzs(expenses);

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          cacheExtent: 2400,
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
              language: language,
              categoryLabel: _titleLabel(language),
              categoryHint: _titleHint(language),
              categorySuggestions: _categorySuggestions(language),
              quickLabel: _categoryQuickLabel(language),
              quickItems: _popularCategories(language),
              noteLabel: _noteLabel(language),
              saveLabel: _saveExpenseLabel(language),
              titleController: _titleController,
              amountController: _amountController,
              noteController: _noteController,
              accountingType: _accountingType,
              accountingChannel: _accountingChannel,
              inputCurrency: _inputCurrency,
              onAccountingTypeChanged: (value) {
                setState(() => _accountingType = value);
              },
              onAccountingChannelChanged: (value) {
                setState(() => _accountingChannel = value);
              },
              onInputCurrencyChanged: (value) {
                setState(() => _inputCurrency = value);
              },
              isSaving: _isSaving,
              onSave: _saveExpense,
            ),
            const SizedBox(height: 18),
            _ExpenseStatsGrid(
              countLabel: _countLabel(language),
              totalCnyLabel: _totalCnyLabel(language),
              totalUsdLabel: _totalUsdLabel(language),
              totalUzsLabel: _totalUzsLabel(language),
              count: expenses.length,
              totalCny: totalCny,
              totalUsd: totalUsd,
              totalUzs: totalUzs,
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
              ExpensesMonthlyPanel(
                expenses: expenses,
                language: language,
                expenseCardBuilder: (expense) => _ExpenseCard(
                  expense: expense,
                  language: language,
                  batchLabel: _batchNameForExpense(expense) == null
                      ? null
                      : _expenseBatchLabel(
                          language,
                          _batchNameForExpense(expense)!,
                        ),
                  onEdit: () => _editExpense(expense),
                  onDelete: () => _deleteExpense(expense),
                  onAttachToBatch: () => _attachExpenseToBatch(expense),
                  onChangeBatch: () => _changeExpenseBatch(expense),
                  onDetachFromBatch: () => _detachExpenseFromBatch(expense),
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
    required this.language,
    required this.categoryLabel,
    required this.categoryHint,
    required this.categorySuggestions,
    required this.quickLabel,
    required this.quickItems,
    required this.noteLabel,
    required this.saveLabel,
    required this.titleController,
    required this.amountController,
    required this.noteController,
    required this.accountingType,
    required this.accountingChannel,
    required this.inputCurrency,
    required this.onAccountingTypeChanged,
    required this.onAccountingChannelChanged,
    required this.onInputCurrencyChanged,
    required this.isSaving,
    required this.onSave,
  });

  final String titleLabel;
  final String description;
  final AppLanguage language;
  final String categoryLabel;
  final String categoryHint;
  final List<String> categorySuggestions;
  final String quickLabel;
  final List<String> quickItems;
  final String noteLabel;
  final String saveLabel;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String accountingType;
  final String accountingChannel;
  final String inputCurrency;
  final ValueChanged<String> onAccountingTypeChanged;
  final ValueChanged<String> onAccountingChannelChanged;
  final ValueChanged<String> onInputCurrencyChanged;
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
          ExpenseDetailsFields(
            language: language,
            categoryLabel: categoryLabel,
            categoryHint: categoryHint,
            categorySuggestions: categorySuggestions,
            quickLabel: quickLabel,
            quickItems: quickItems,
            noteLabel: noteLabel,
            titleController: titleController,
            amountController: amountController,
            noteController: noteController,
            accountingType: accountingType,
            accountingChannel: accountingChannel,
            inputCurrency: inputCurrency,
            onAccountingTypeChanged: onAccountingTypeChanged,
            onAccountingChannelChanged: onAccountingChannelChanged,
            onInputCurrencyChanged: onInputCurrencyChanged,
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

class _ExpenseStatsGrid extends StatelessWidget {
  const _ExpenseStatsGrid({
    required this.countLabel,
    required this.totalCnyLabel,
    required this.totalUsdLabel,
    required this.totalUzsLabel,
    required this.count,
    required this.totalCny,
    required this.totalUsd,
    required this.totalUzs,
  });

  final String countLabel;
  final String totalCnyLabel;
  final String totalUsdLabel;
  final String totalUzsLabel;
  final int count;
  final double totalCny;
  final double totalUsd;
  final double totalUzs;

  static const double _cardHeight = 92;
  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return const SizedBox.shrink();
        }

        final columns = width >= 900 ? 4 : width >= 520 ? 2 : 1;
        final tileWidth = (width - (columns - 1) * _spacing) / columns;

        Widget tile(_ExpenseSummaryStatCard card) {
          return SizedBox(
            width: tileWidth,
            height: _cardHeight,
            child: card,
          );
        }

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            tile(
              _ExpenseSummaryStatCard(
                label: countLabel,
                value: '$count',
              ),
            ),
            tile(
              _ExpenseSummaryStatCard(
                label: totalCnyLabel,
                value: formatProductMoney(totalCny),
                accentColor: AppColors.primary,
              ),
            ),
            tile(
              _ExpenseSummaryStatCard(
                label: totalUsdLabel,
                value: formatProductMoney(totalUsd),
                accentColor: AppColors.accent,
              ),
            ),
            tile(
              _ExpenseSummaryStatCard(
                label: totalUzsLabel,
                value: formatProductMoney(totalUzs),
                accentColor: AppColors.danger,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseSummaryStatCard extends StatelessWidget {
  const _ExpenseSummaryStatCard({
    required this.label,
    required this.value,
    this.accentColor,
  });

  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = accentColor;
    final gradientColors = accent != null
        ? [accent.withValues(alpha: 0.14), AppColors.surfaceStrong]
        : const [AppColors.surfaceStrong, AppColors.surfaceMuted];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent?.withValues(alpha: 0.32) ?? AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.2,
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent ?? AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ExpenseMenuAction {
  attachToBatch,
  changeBatch,
  detachFromBatch,
  edit,
  delete,
}

class _ExpenseCurrencyChip extends StatelessWidget {
  const _ExpenseCurrencyChip({
    required this.currencyLabel,
    required this.amount,
    required this.accentColor,
    this.compact = false,
  });

  final String currencyLabel;
  final double amount;
  final Color accentColor;
  final bool compact;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountFontSize = compact ? 11.5 : 13.0;

    return SizedBox(
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatProductMoney(amount),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    fontSize: amountFontSize,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currencyLabel,
                maxLines: 1,
                style: textTheme.labelSmall?.copyWith(
                  color: accentColor.withValues(alpha: 0.9),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseCurrencyChipsRow extends StatelessWidget {
  const _ExpenseCurrencyChipsRow({
    required this.cny,
    required this.usd,
    required this.uzs,
    this.alignEnd = false,
  });

  final double cny;
  final double usd;
  final double uzs;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final chipWidth = compact ? 74.0 : 86.0;

    Widget chip(String label, double amount, Color color) {
      return SizedBox(
        width: chipWidth,
        child: _ExpenseCurrencyChip(
          currencyLabel: label,
          amount: amount,
          accentColor: color,
          compact: compact,
        ),
      );
    }

    final chips = <Widget>[
      chip('CNY', cny, AppColors.primary),
      chip('USD', usd, AppColors.accent),
      chip('UZS', uzs, AppColors.danger),
    ];

    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}

class _ExpenseCurrencyChips extends StatelessWidget {
  const _ExpenseCurrencyChips({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final cnyAmount = expense.amountCny > 0
        ? expense.amountCny
        : (expense.amountValue ?? 0);

    return _ExpenseCurrencyChipsRow(
      cny: cnyAmount,
      usd: expense.amountUsd,
      uzs: expense.amountUzs,
      alignEnd: true,
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.language,
    required this.onEdit,
    required this.onDelete,
    required this.onAttachToBatch,
    required this.onChangeBatch,
    required this.onDetachFromBatch,
    this.batchLabel,
  });

  final Expense expense;
  final AppLanguage language;
  final String? batchLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAttachToBatch;
  final VoidCallback onChangeBatch;
  final VoidCallback onDetachFromBatch;

  bool get _isLinkedToBatch =>
      expense.batchId != null && expense.batchId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(26),
        child: Container(
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
                    if (batchLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          batchLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ExpenseMetaBadges(
                      language: language,
                      accountingType: expense.accountingType,
                      accountingChannel: expense.accountingChannel,
                      inputCurrency: expense.inputCurrency,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: _ExpenseCurrencyChips(expense: expense),
                ),
              ),
              const SizedBox(width: 4),
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
                    case _ExpenseMenuAction.attachToBatch:
                      onAttachToBatch();
                      break;
                    case _ExpenseMenuAction.changeBatch:
                      onChangeBatch();
                      break;
                    case _ExpenseMenuAction.detachFromBatch:
                      onDetachFromBatch();
                      break;
                    case _ExpenseMenuAction.edit:
                      onEdit();
                      break;
                    case _ExpenseMenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<_ExpenseMenuAction>>[];

                  if (_isLinkedToBatch) {
                    items.addAll([
                      PopupMenuItem<_ExpenseMenuAction>(
                        value: _ExpenseMenuAction.changeBatch,
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(_changeExpenseBatchMenuLabel(language)),
                          ],
                        ),
                      ),
                      PopupMenuItem<_ExpenseMenuAction>(
                        value: _ExpenseMenuAction.detachFromBatch,
                        child: Row(
                          children: [
                            const Icon(Icons.link_off_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(_detachExpenseMenuLabel(language)),
                          ],
                        ),
                      ),
                    ]);
                  } else {
                    items.add(
                      PopupMenuItem<_ExpenseMenuAction>(
                        value: _ExpenseMenuAction.attachToBatch,
                        child: Row(
                          children: [
                            const Icon(Icons.link_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(_attachExpenseMenuLabel(language)),
                          ],
                        ),
                      ),
                    );
                  }

                  items.addAll([
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
                  ]);

                  return items;
                },
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
        ),
      ),
    );
  }

  String _attachExpenseMenuLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Привязать к партии';
      case AppLanguage.en:
        return 'Attach to batch';
      case AppLanguage.zh:
        return '关联到批次';
    }
  }

  String _changeExpenseBatchMenuLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Изменить партию';
      case AppLanguage.en:
        return 'Change batch';
      case AppLanguage.zh:
        return '更换批次';
    }
  }

  String _detachExpenseMenuLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить от партии';
      case AppLanguage.en:
        return 'Detach from batch';
      case AppLanguage.zh:
        return '从批次解除关联';
    }
  }
}

class _ExpenseEditorSheet extends StatefulWidget {
  const _ExpenseEditorSheet({
    required this.expense,
    required this.language,
    required this.categoryLabel,
    required this.titleHint,
    required this.quickLabel,
    required this.suggestions,
    required this.quickItems,
    required this.noteLabel,
  });

  final Expense expense;
  final AppLanguage language;
  final String categoryLabel;
  final String titleHint;
  final String quickLabel;
  final List<String> suggestions;
  final List<String> quickItems;
  final String noteLabel;

  @override
  State<_ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<_ExpenseEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _accountingType;
  late String _accountingChannel;
  late String _inputCurrency;

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
    _accountingType = widget.expense.accountingType;
    _accountingChannel = widget.expense.accountingChannel;
    _inputCurrency = widget.expense.inputCurrency;
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
    final language = widget.language;
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
            ExpenseDetailsFields(
              language: language,
              categoryLabel: widget.categoryLabel,
              categoryHint: widget.titleHint,
              categorySuggestions: widget.suggestions,
              quickLabel: widget.quickLabel,
              quickItems: widget.quickItems,
              noteLabel: widget.noteLabel,
              titleController: _titleController,
              amountController: _amountController,
              noteController: _noteController,
              accountingType: _accountingType,
              accountingChannel: _accountingChannel,
              inputCurrency: _inputCurrency,
              onAccountingTypeChanged: (value) {
                setState(() => _accountingType = value);
              },
              onAccountingChannelChanged: (value) {
                setState(() => _accountingChannel = value);
              },
              onInputCurrencyChanged: (value) {
                setState(() => _inputCurrency = value);
              },
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
                          accountingType: _accountingType,
                          accountingChannel: _accountingChannel,
                          inputCurrency: _inputCurrency,
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

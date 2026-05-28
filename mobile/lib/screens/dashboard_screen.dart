import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/batch_item_type.dart';
import '../models/expense.dart';
import '../models/expense_meta.dart';
import '../models/product.dart';
import '../models/product_batch.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/add_to_batch_dialog.dart';
import '../widgets/app_background.dart';
import '../utils/batch_expense_summary.dart';
import '../widgets/batch_expenses_section.dart';
import '../widgets/batch_item_type_controls.dart';
import '../utils/product_goods_totals.dart';
import '../widgets/porting_batch_header_summary.dart';
import '../widgets/porting_batches_panel.dart';
import '../widgets/product_thumbnail_card.dart';
import '../widgets/section_cards.dart';
import 'photo_viewer_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ValueNotifier<Set<String>> _selectedProductIds =
      ValueNotifier<Set<String>>(<String>{});
  bool _isCreatingBatch = false;

  @override
  void dispose() {
    _selectedProductIds.dispose();
    super.dispose();
  }

  String _tabLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Портировка';
      case AppLanguage.en:
        return 'Porting';
      case AppLanguage.zh:
        return '分拣';
    }
  }

  String _heroDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Выбери закупы и объедини их в партию. Товары без партии остаются в отдельном блоке.';
      case AppLanguage.en:
        return 'Select purchases and group them into batches. Items without a batch stay in a separate section.';
      case AppLanguage.zh:
        return '选择采购并合并为批次。未分组的商品会显示在单独区域。';
    }
  }

  String _purchaseCountLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Всего закупов';
      case AppLanguage.en:
        return 'Total purchases';
      case AppLanguage.zh:
        return '采购总数';
    }
  }

  String _piecesTotalLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Всего штук';
      case AppLanguage.en:
        return 'Total pieces';
      case AppLanguage.zh:
        return '总件数';
    }
  }

  String _netTotalLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Итог с 10%';
      case AppLanguage.en:
        return 'Net after 10%';
      case AppLanguage.zh:
        return '扣除10%后';
    }
  }

  String _expensesTotalLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расходы';
      case AppLanguage.en:
        return 'Expenses';
      case AppLanguage.zh:
        return '支出';
    }
  }

  String _grandTotalLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return '\u041E\u0431\u0449\u0438\u0439 \u0438\u0442\u043E\u0433';
      case AppLanguage.en:
        return 'Grand total';
      case AppLanguage.zh:
        return '\u603B\u8BA1';
    }
  }

  String _batchesTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партии';
      case AppLanguage.en:
        return 'Batches';
      case AppLanguage.zh:
        return '批次';
    }
  }

  String _batchTitle(AppLanguage language, String name) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партия: $name';
      case AppLanguage.en:
        return 'Batch: $name';
      case AppLanguage.zh:
        return '批次：$name';
    }
  }

  String _allInBatchesHint(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Все закупы уже распределены по партиям.';
      case AppLanguage.en:
        return 'All purchases are already assigned to batches.';
      case AppLanguage.zh:
        return '所有采购已分配到批次。';
    }
  }

  String _unbatchedTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Без партии';
      case AppLanguage.en:
        return 'Without batch';
      case AppLanguage.zh:
        return '未分批';
    }
  }

  String _portingSearchHint(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Поиск по артикулу, цвету, размеру, магазину…';
      case AppLanguage.en:
        return 'Search by article, color, size, shop…';
      case AppLanguage.zh:
        return '按货号、颜色、尺码、店铺搜索…';
    }
  }

  String _portingSearchResultsTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Результаты поиска';
      case AppLanguage.en:
        return 'Search results';
      case AppLanguage.zh:
        return '搜索结果';
    }
  }

  String _batchItemTypeRegularLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Обычный';
      case AppLanguage.en:
        return 'Regular';
      case AppLanguage.zh:
        return '普通';
    }
  }

  String _batchItemTypeOrderLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Заказной';
      case AppLanguage.en:
        return 'Order';
      case AppLanguage.zh:
        return '订购';
    }
  }

  String _batchExpensesTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расходы партии CNY / USD / UZS';
      case AppLanguage.en:
        return 'Batch expenses CNY / USD / UZS';
      case AppLanguage.zh:
        return '批次支出 CNY / USD / UZS';
    }
  }

  String _batchExpensesEmptyLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Нет привязанных расходов.';
      case AppLanguage.en:
        return 'No expenses linked to this batch.';
      case AppLanguage.zh:
        return '没有关联到此批次的支出。';
    }
  }

  String _batchExpensePerUnitLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход на 1 шт';
      case AppLanguage.en:
        return 'Expense per piece';
      case AppLanguage.zh:
        return '每件支出';
    }
  }

  String _batchExpenseDetailsButtonLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Детали расходов';
      case AppLanguage.en:
        return 'Expense details';
      case AppLanguage.zh:
        return '支出明细';
    }
  }

  String _batchExpenseDetailsTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Детали расходов';
      case AppLanguage.en:
        return 'Expense details';
      case AppLanguage.zh:
        return '支出明细';
    }
  }

  String _batchExpenseDetailsDateLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Дата';
      case AppLanguage.en:
        return 'Date';
      case AppLanguage.zh:
        return '日期';
    }
  }

  String _batchRegularPiecesLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Обычных штук';
      case AppLanguage.en:
        return 'Regular pieces';
      case AppLanguage.zh:
        return '批次普通件数';
    }
  }

  String _allocatedExpensePerUnitLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Расход партии на 1 шт';
      case AppLanguage.en:
        return 'Batch expense per unit';
      case AppLanguage.zh:
        return '批次单位支出';
    }
  }

  String _finalUnitCostLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Себестоимость 1 шт';
      case AppLanguage.en:
        return 'Final unit cost';
      case AppLanguage.zh:
        return '单位最终成本';
    }
  }

  String _orderExpenseExcludedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Заказной — расходы не распределяются';
      case AppLanguage.en:
        return 'Order item — expenses are not allocated';
      case AppLanguage.zh:
        return '订购商品 — 不分配支出';
    }
  }

  String _changeBatchItemStatusLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Изменить статус';
      case AppLanguage.en:
        return 'Change status';
      case AppLanguage.zh:
        return '更改状态';
    }
  }

  String _detachFromBatchLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить от партии';
      case AppLanguage.en:
        return 'Remove from batch';
      case AppLanguage.zh:
        return '从批次移除';
    }
  }

  String _detachFromBatchConfirmTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить товар?';
      case AppLanguage.en:
        return 'Remove from batch?';
      case AppLanguage.zh:
        return '从批次移除？';
    }
  }

  String _detachFromBatchConfirmMessage(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить этот товар от партии?';
      case AppLanguage.en:
        return 'Remove this product from the batch?';
      case AppLanguage.zh:
        return '将此商品从批次中移除？';
    }
  }

  String _detachFromBatchActionLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Открепить';
      case AppLanguage.en:
        return 'Remove';
      case AppLanguage.zh:
        return '移除';
    }
  }

  String _cancelActionLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Отмена';
      case AppLanguage.en:
        return 'Cancel';
      case AppLanguage.zh:
        return '取消';
    }
  }

  String _portingSearchEmptyLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Ничего не найдено. Попробуй другой артикул или параметр.';
      case AppLanguage.en:
        return 'No matches. Try another article or attribute.';
      case AppLanguage.zh:
        return '未找到结果，请尝试其他货号或条件。';
    }
  }

  String _selectedCountLabel(AppLanguage language, int count) {
    switch (language) {
      case AppLanguage.ru:
        return 'Выбрано: $count ${_productCountWord(language, count)}';
      case AppLanguage.en:
        return 'Selected: $count ${_productCountWord(language, count)}';
      case AppLanguage.zh:
        return '已选：$count 件商品';
    }
  }

  String _batchGoodsTotalsTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Итог товаров';
      case AppLanguage.en:
        return 'Goods total';
      case AppLanguage.zh:
        return '商品合计';
    }
  }

  String _piecesShortLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'шт';
      case AppLanguage.en:
        return 'pcs';
      case AppLanguage.zh:
        return '件';
    }
  }

  PortingBatchHeaderSummary _buildBatchHeaderSummary(
    AppLanguage language,
    ProductGoodsTotals totals,
  ) {
    final productsLabel =
        '${totals.productCount} ${_productCountWord(language, totals.productCount)}';
    final piecesLabel = '${totals.totalPieces} ${_piecesShortLabel(language)}';

    return PortingBatchHeaderSummary(
      countsLine: '$productsLabel • $piecesLabel',
      goodsTotalsTitle: _batchGoodsTotalsTitle(language),
      totalCny: totals.totalCny,
      totalUsd: totals.totalUsd,
      totalUzs: totals.totalUzs,
    );
  }

  String _showMoreLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Показать ещё';
      case AppLanguage.en:
        return 'Show more';
      case AppLanguage.zh:
        return '显示更多';
    }
  }

  String _productCountWord(AppLanguage language, int count) {
    switch (language) {
      case AppLanguage.ru:
        if (count % 10 == 1 && count % 100 != 11) {
          return 'товар';
        }
        if (count % 10 >= 2 &&
            count % 10 <= 4 &&
            (count % 100 < 10 || count % 100 >= 20)) {
          return 'товара';
        }
        return 'товаров';
      case AppLanguage.en:
        return count == 1 ? 'item' : 'items';
      case AppLanguage.zh:
        return '件商品';
    }
  }

  String _addToBatchLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Добавить в партию';
      case AppLanguage.en:
        return 'Add to batch';
      case AppLanguage.zh:
        return '添加到批次';
    }
  }

  String _batchCreatedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Партия создана.';
      case AppLanguage.en:
        return 'Batch created.';
      case AppLanguage.zh:
        return '批次已创建。';
    }
  }

  String _batchProductsAddedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Товары добавлены в партию.';
      case AppLanguage.en:
        return 'Products added to the batch.';
      case AppLanguage.zh:
        return '商品已添加到批次。';
    }
  }

  String _batchAssignFailedLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Не удалось добавить товары в партию.';
      case AppLanguage.en:
        return 'Failed to add products to the batch.';
      case AppLanguage.zh:
        return '无法将商品添加到批次。';
    }
  }

  String _batchNameRequiredLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Введите название партии.';
      case AppLanguage.en:
        return 'Enter a batch name.';
      case AppLanguage.zh:
        return '请输入批次名称。';
    }
  }

  String _emptyTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Пока нет закупов';
      case AppLanguage.en:
        return 'No purchases yet';
      case AppLanguage.zh:
        return '暂时没有采购';
    }
  }

  String _emptyDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Когда создашь закуп товара, он сразу появится здесь.';
      case AppLanguage.en:
        return 'Once you create a purchase, it will appear here immediately.';
      case AppLanguage.zh:
        return '创建采购后，它会立即显示在这里。';
    }
  }

  String _expensesSectionTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Последние расходы';
      case AppLanguage.en:
        return 'Recent expenses';
      case AppLanguage.zh:
        return '最近支出';
    }
  }

  String _emptyExpensesTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Пока нет расходов';
      case AppLanguage.en:
        return 'No expenses yet';
      case AppLanguage.zh:
        return '暂时没有支出';
    }
  }

  String _emptyExpensesDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Когда добавишь расход, он появится здесь.';
      case AppLanguage.en:
        return 'Once you add an expense, it will appear here.';
      case AppLanguage.zh:
        return '添加支出后，它会显示在这里。';
    }
  }

  Future<void> _openViewer(
    BuildContext context,
    Product product,
    int initialIndex,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PhotoViewerPage(product: product, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }

  void _toggleProductSelection(String productId, bool selected) {
    final next = Set<String>.from(_selectedProductIds.value);
    if (selected) {
      next.add(productId);
    } else {
      next.remove(productId);
    }
    _selectedProductIds.value = next;
  }

  Future<void> _openAddToBatchDialog(AppLanguage language) async {
    if (_selectedProductIds.value.isEmpty || _isCreatingBatch) {
      return;
    }

    final result = await showDialog<AddToBatchDialogResult>(
      context: context,
      builder: (dialogContext) => AddToBatchDialog(
        language: language,
        batches: List<ProductBatch>.from(widget.store.batches),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result.mode == AddToBatchMode.createNew &&
        (result.batchName == null || result.batchName!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_batchNameRequiredLabel(language))),
      );
      return;
    }

    if (result.mode == AddToBatchMode.existing &&
        (result.batchId == null || result.batchId!.isEmpty)) {
      return;
    }

    setState(() {
      _isCreatingBatch = true;
    });

    final productIds = _selectedProductIds.value.toList();

    try {
      if (result.mode == AddToBatchMode.createNew) {
        await widget.store.createBatch(
          name: result.batchName!.trim(),
          productIds: productIds,
        );
      } else {
        await widget.store.addProductsToBatch(
          batchId: result.batchId!,
          productIds: productIds,
        );
      }

      if (!mounted) {
        return;
      }

      _selectedProductIds.value = <String>{};

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.mode == AddToBatchMode.createNew
                ? _batchCreatedLabel(language)
                : _batchProductsAddedLabel(language),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            describeError(
              error,
              fallbackMessage: _batchAssignFailedLabel(language),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBatch = false;
        });
      }
    }
  }

  Future<void> _updateProductBatchItemType(
    BuildContext context,
    AppLanguage language,
    String productId,
    BatchItemType batchItemType,
  ) async {
    try {
      await widget.store.updateProductBatchItemType(
        productId: productId,
        batchItemType: batchItemType,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = switch (language) {
        AppLanguage.ru => 'Не удалось обновить тип товара: $error',
        AppLanguage.en => 'Failed to update item type: $error',
        AppLanguage.zh => '无法更新商品类型：$error',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _confirmDetachProductFromBatch(
    BuildContext context,
    AppLanguage language,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceStrong,
          title: Text(_detachFromBatchConfirmTitle(language)),
          content: Text(_detachFromBatchConfirmMessage(language)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_cancelActionLabel(language)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_detachFromBatchActionLabel(language)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.store.detachProductFromBatch(product.id);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = switch (language) {
        AppLanguage.ru => 'Не удалось открепить товар: $error',
        AppLanguage.en => 'Failed to remove product from batch: $error',
        AppLanguage.zh => '无法从批次移除商品：$error',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleBatchProductMenuAction(
    BuildContext context,
    AppLanguage language,
    Product product,
    BatchProductMenuAction action,
  ) async {
    switch (action) {
      case BatchProductMenuAction.setRegular:
        if (product.batchItemType == BatchItemType.regular) {
          return;
        }

        await _updateProductBatchItemType(
          context,
          language,
          product.id,
          BatchItemType.regular,
        );
      case BatchProductMenuAction.setOrder:
        if (product.batchItemType == BatchItemType.order) {
          return;
        }

        await _updateProductBatchItemType(
          context,
          language,
          product.id,
          BatchItemType.order,
        );
      case BatchProductMenuAction.detach:
        await _confirmDetachProductFromBatch(context, language, product);
    }
  }

  double _resolvedAllocatedExpensePerUnitCny(
    Product product,
    AppStore store,
  ) {
    if (product.allocatedExpensePerUnitCny > 0) {
      return product.allocatedExpensePerUnitCny;
    }

    final batchId = product.batchId;
    if (batchId == null || batchId.isEmpty || product.batchItemType.isOrder) {
      return 0;
    }

    for (final batch in store.batches) {
      if (batch.id != batchId) {
        continue;
      }

      return summarizeBatchExpenses(
        allExpenses: store.expenses,
        batchId: batchId,
        batchProducts: batch.products,
      ).expensePerUnitCny;
    }

    return 0;
  }

  double _resolvedFinalUnitCostCny(Product product, double allocatedCny) {
    if (product.finalUnitCostCny > product.unitPriceWithShare + 0.000001) {
      return product.finalUnitCostCny;
    }

    final unitWithShare = product.unitPriceWithShareValue ?? product.unitPriceWithShare;

    if (allocatedCny > 0 && unitWithShare > 0) {
      return unitWithShare + allocatedCny;
    }

    return product.effectiveUnitCostCny;
  }

  Widget _buildPortingProductCard(
    BuildContext context,
    Product product, {
    required bool selectable,
    required bool selected,
    required ValueChanged<bool>? onSelectedChanged,
    required double usdToCny,
    required double usdToUzs,
    required AppLanguage language,
    required AppStore store,
    bool showBatchItemTypeControls = false,
  }) {
    final inBatch = product.batchId != null && product.batchId!.isNotEmpty;
    final showBatchControls = showBatchItemTypeControls && inBatch;
    final allocatedCny = showBatchControls && !product.batchItemType.isOrder
        ? _resolvedAllocatedExpensePerUnitCny(product, store)
        : 0.0;
    final finalCny = showBatchControls && !product.batchItemType.isOrder
        ? _resolvedFinalUnitCostCny(product, allocatedCny)
        : product.effectiveUnitCostCny;

    return _DashboardPurchaseCard(
      key: ValueKey('porting-product-${product.id}'),
      product: product,
      usdToCny: usdToCny,
      usdToUzs: usdToUzs,
      selectable: selectable,
      selected: selected,
      onSelectedChanged: onSelectedChanged,
      onOpenImage: (index) => _openViewer(context, product, index),
      showBatchProductActions: showBatchControls,
      batchItemTypeRegularLabel: _batchItemTypeRegularLabel(language),
      batchItemTypeOrderLabel: _batchItemTypeOrderLabel(language),
      changeBatchItemStatusLabel: _changeBatchItemStatusLabel(language),
      detachFromBatchLabel: _detachFromBatchLabel(language),
      onBatchProductMenuAction: showBatchControls
          ? (action) => _handleBatchProductMenuAction(
              context,
              language,
              product,
              action,
            )
          : null,
      orderExpenseExcludedLabel: _orderExpenseExcludedLabel(language),
      allocatedExpensePerUnitLabel: _allocatedExpensePerUnitLabel(language),
      finalUnitCostLabel: _finalUnitCostLabel(language),
      allocatedExpensePerUnitCny: allocatedCny,
      finalUnitCostCny: finalCny,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final language = strings.language;
    final store = widget.store;
    final purchases = List<Product>.from(store.allProducts)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final expenses = List<Expense>.from(store.expenses)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    final totalQuantity = purchases.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    final netTotal = purchases.fold<double>(
      0,
      (sum, product) => sum + (product.totalValue ?? 0),
    );
    final expensesTotalCny = Expense.sumCny(expenses);
    final expensesTotalUsd = Expense.sumUsd(expenses);
    final expensesTotalUzs = Expense.sumUzs(expenses);
    final grandTotal = netTotal + expensesTotalCny;

    return AppBackground(
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  _selectedProductIds.value.isNotEmpty ? 168 : 120,
                ),
                children: [
            SectionHeroCard(
              badge: _tabLabel(language).toUpperCase(),
              badgeColor: AppColors.primary,
              title: _tabLabel(language),
              description: _heroDescription(language),
              count: purchases.length,
              countLabel: _purchaseCountLabel(language),
              colors: const [Color(0x245FE0B8), Color(0x147C92FF)],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DashboardStatCard(
                    label: _piecesTotalLabel(language),
                    value: '$totalQuantity',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardStatCard(
                    label: _netTotalLabel(language),
                    value: netTotal <= 0 ? '0' : formatProductMoney(netTotal),
                    highlighted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DashboardStatCard(
                    label: _expensesTotalLabel(language),
                    value: expensesTotalCny <= 0 &&
                            expensesTotalUsd <= 0 &&
                            expensesTotalUzs <= 0
                        ? '0'
                        : formatCurrencyTotalsLine(
                            totalCny: expensesTotalCny,
                            totalUsd: expensesTotalUsd,
                            totalUzs: expensesTotalUzs,
                          ),
                    danger: true,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardStatCard(
                    label: _grandTotalLabel(language),
                    value: grandTotal <= 0
                        ? '0'
                        : formatProductMoney(grandTotal),
                    highlighted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (purchases.isEmpty)
              EmptyStateCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.accent,
                title: _emptyTitle(language),
                description: _emptyDescription(language),
              )
            else
              PortingBatchesPanel(
                store: store,
                language: language,
                searchHint: _portingSearchHint(language),
                searchResultsTitle: _portingSearchResultsTitle(language),
                searchEmptyLabel: _portingSearchEmptyLabel(language),
                batchesTitle: _batchesTitle(language),
                unbatchedTitle: _unbatchedTitle(language),
                allInBatchesHint: _allInBatchesHint(language),
                emptyProductsLabel: strings.t('notSpecified'),
                showMoreLabel: _showMoreLabel(language),
                batchTitleBuilder: (name) => _batchTitle(language, name),
                batchSummaryBuilder: (totals) =>
                    _buildBatchHeaderSummary(language, totals),
                batchExpensesLabels: BatchExpensesSectionLabels(
                  title: _batchExpensesTitle(language),
                  emptyLabel: _batchExpensesEmptyLabel(language),
                  perUnitLabel: _batchExpensePerUnitLabel(language),
                  regularPiecesLabel: _batchRegularPiecesLabel(language),
                  detailsButtonLabel: _batchExpenseDetailsButtonLabel(language),
                  detailsTitle: _batchExpenseDetailsTitle(language),
                  detailsDateLabel: _batchExpenseDetailsDateLabel(language),
                  detailsAccountingTypeLabel:
                      expenseAccountingTypeFieldLabel(language),
                  detailsAccountingChannelLabel:
                      expenseAccountingChannelFieldLabel(language),
                  detailsInputCurrencyLabel:
                      expenseInputCurrencyFieldLabel(language),
                ),
                selectedProductIds: _selectedProductIds,
                onToggleProductSelection: _toggleProductSelection,
                productCardBuilder: (
                  product, {
                  required selectable,
                  required selected,
                  required onSelectedChanged,
                  showBatchItemTypeControls = false,
                }) =>
                    _buildPortingProductCard(
                      context,
                      product,
                      selectable: selectable,
                      selected: selected,
                      onSelectedChanged: onSelectedChanged,
                      usdToCny: store.usdToCny,
                      usdToUzs: store.usdToUzs,
                      language: language,
                      store: store,
                      showBatchItemTypeControls: showBatchItemTypeControls,
                    ),
              ),
            const SizedBox(height: 18),
            Text(
              _expensesSectionTitle(language),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              EmptyStateCard(
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.danger,
                title: _emptyExpensesTitle(language),
                description: _emptyExpensesDescription(language),
              )
            else
              ...expenses
                  .take(6)
                  .map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DashboardExpenseCard(expense: expense),
                    ),
                  ),
              ],
              ),
            ),
            ValueListenableBuilder<Set<String>>(
              valueListenable: _selectedProductIds,
              builder: (context, selectedIds, _) {
                if (selectedIds.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _BatchSelectionBar(
                    selectedLabel: _selectedCountLabel(
                      language,
                      selectedIds.length,
                    ),
                    actionLabel: _addToBatchLabel(language),
                    isLoading: _isCreatingBatch,
                    onCreate: () => _openAddToBatchDialog(language),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchSelectionBar extends StatelessWidget {
  const _BatchSelectionBar({
    required this.selectedLabel,
    required this.actionLabel,
    required this.isLoading,
    required this.onCreate,
  });

  final String selectedLabel;
  final String actionLabel;
  final bool isLoading;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      elevation: 10,
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF08110F),
              ),
              onPressed: isLoading ? null : onCreate,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.danger = false,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final bool highlighted;
  final bool danger;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlighted
              ? [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.surfaceStrong,
                ]
              : danger
              ? [
                  AppColors.danger.withValues(alpha: 0.14),
                  AppColors.surfaceStrong,
                ]
              : [AppColors.surfaceStrong, AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.35)
              : danger
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
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: (maxLines > 1 ? textTheme.titleSmall : textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: highlighted
                  ? AppColors.primary
                  : danger
                  ? AppColors.danger
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardExpenseCard extends StatelessWidget {
  const _DashboardExpenseCard({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.note.trim().isEmpty
                      ? formatProductDate(expense.createdAt)
                      : expense.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                expense.formattedAmountsLine(),
                textAlign: TextAlign.end,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardPurchaseCard extends StatelessWidget {
  const _DashboardPurchaseCard({
    super.key,
    required this.product,
    required this.usdToCny,
    required this.usdToUzs,
    required this.onOpenImage,
    this.selectable = false,
    this.selected = false,
    this.onSelectedChanged,
    this.showBatchProductActions = false,
    this.batchItemTypeRegularLabel = 'Regular',
    this.batchItemTypeOrderLabel = 'Order',
    this.changeBatchItemStatusLabel = 'Change status',
    this.detachFromBatchLabel = 'Remove from batch',
    this.onBatchProductMenuAction,
    this.orderExpenseExcludedLabel = 'Order item — expenses are not allocated',
    this.allocatedExpensePerUnitLabel = 'Batch expense per unit',
    this.finalUnitCostLabel = 'Final unit cost',
    this.allocatedExpensePerUnitCny,
    this.finalUnitCostCny,
  });

  final Product product;
  final double usdToCny;
  final double usdToUzs;
  final ValueChanged<int> onOpenImage;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;
  final bool showBatchProductActions;
  final String batchItemTypeRegularLabel;
  final String batchItemTypeOrderLabel;
  final String changeBatchItemStatusLabel;
  final String detachFromBatchLabel;
  final Future<void> Function(BatchProductMenuAction action)?
      onBatchProductMenuAction;
  final String orderExpenseExcludedLabel;
  final String allocatedExpensePerUnitLabel;
  final String finalUnitCostLabel;
  final double? allocatedExpensePerUnitCny;
  final double? finalUnitCostCny;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final title = product.shopName.trim().isEmpty
        ? strings.t('newShop')
        : product.shopName;
    final unitCny = product.amountValue ?? 0;
    final shareCny = product.unitPriceWithShareValue ?? 0;
    final productUsdToCny =
        product.usdToCnyRate > 0 ? product.usdToCnyRate : usdToCny;
    final productUsdToUzs =
        product.usdToUzsRate > 0 ? product.usdToUzsRate : usdToUzs;
    final unitPrices =
        convertCnyToCurrencies(unitCny, productUsdToCny, productUsdToUzs);
    final sharePrices =
        convertCnyToCurrencies(shareCny, productUsdToCny, productUsdToUzs);
    final notSpecified = strings.t('notSpecified');

    final isOrderInBatch =
        showBatchProductActions && product.batchItemType.isOrder;

    final batchItemTypeBadge = showBatchProductActions && !isOrderInBatch
        ? BatchItemTypeBadge(
            type: product.batchItemType,
            regularLabel: batchItemTypeRegularLabel,
            orderLabel: batchItemTypeOrderLabel,
          )
        : null;

    final allocatedCny = allocatedExpensePerUnitCny ?? product.allocatedExpensePerUnitCny;
    final resolvedFinalCny = finalUnitCostCny ??
        (product.finalUnitCostCny > 0
            ? product.finalUnitCostCny
            : product.effectiveUnitCostCny);
    final finalUsd = product.finalUnitCostUsd > 0
        ? product.finalUnitCostUsd
        : (productUsdToCny > 0 ? resolvedFinalCny / productUsdToCny : 0.0);
    final finalUzs = product.finalUnitCostUzs > 0
        ? product.finalUnitCostUzs
        : finalUsd * (productUsdToUzs > 0 ? productUsdToUzs : 0.0);
    final allocatedPrices = convertCnyToCurrencies(
      allocatedCny,
      productUsdToCny,
      productUsdToUzs,
    );
    final hasAllocatedExpense = allocatedCny > 0;
    final finalPrices = CurrencyAmounts(
      cny: resolvedFinalCny,
      usd: finalUsd,
      uzs: finalUzs,
    );

    final cardInner = Container(
      padding: EdgeInsets.fromLTRB(14, 14, showBatchProductActions ? 40 : 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceStrong.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final useWideLayout = width >= 920;
          final useMediumLayout = width >= 640;

          final leftSection = _DashboardPurchaseLeftSection(
            title: title,
            createdAt: product.createdAt,
            imageSource:
                product.imagePaths.isEmpty ? '' : product.imagePaths.first,
            onOpenImage: product.imagePaths.isEmpty
                ? null
                : () => onOpenImage(0),
          );

          final metricsSection = _DashboardPurchaseMetricsSection(
            articleLabel: strings.t('articleLabel'),
            articleValue: product.article.trim().isEmpty
                ? notSpecified
                : product.article.trim(),
            articleBadge: batchItemTypeBadge,
            piecesLabel: strings.t('piecesLabel'),
            piecesValue: '${product.quantity}',
            totalLabel: strings.t('totalLabel'),
            totalValue: product.totalValue == null
                ? notSpecified
                : formatProductMoney(product.totalValue!),
          );

          final pricesSection = _DashboardPurchasePricesSection(
            priceTitle: strings.t('priceLabel'),
            sharePriceTitle: strings.t('unitPriceWithShareLabel'),
            unitPrices: unitPrices,
            sharePrices: sharePrices,
            hasUnitPrice: product.amountValue != null && unitCny > 0,
            hasSharePrice: product.unitPriceWithShareValue != null && shareCny > 0,
            notSpecified: notSpecified,
          );

          final batchCostSection = showBatchProductActions && !isOrderInBatch
              ? _DashboardBatchUnitCostSection(
                  allocatedLabel: allocatedExpensePerUnitLabel,
                  finalLabel: finalUnitCostLabel,
                  allocatedPrices: allocatedPrices,
                  finalPrices: finalPrices,
                  hasAllocatedExpense: hasAllocatedExpense,
                  hasFinalCost: resolvedFinalCny > 0,
                  notSpecified: notSpecified,
                )
              : null;

          final orderExclusionBanner = isOrderInBatch
              ? BatchOrderExpenseExclusionBadge(
                  label: orderExpenseExcludedLabel,
                )
              : null;

          if (useWideLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: leftSection),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: metricsSection),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: pricesSection),
                  ],
                ),
                if (orderExclusionBanner != null) ...[
                  const SizedBox(height: 12),
                  orderExclusionBanner,
                ],
                if (batchCostSection != null) ...[
                  const SizedBox(height: 12),
                  batchCostSection,
                ],
              ],
            );
          }

          if (useMediumLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftSection,
                const SizedBox(height: 12),
                metricsSection,
                const SizedBox(height: 12),
                pricesSection,
                if (orderExclusionBanner != null) ...[
                  const SizedBox(height: 12),
                  orderExclusionBanner,
                ],
                if (batchCostSection != null) ...[
                  const SizedBox(height: 12),
                  batchCostSection,
                ],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leftSection,
              const SizedBox(height: 12),
              metricsSection,
              const SizedBox(height: 12),
              pricesSection,
              if (orderExclusionBanner != null) ...[
                const SizedBox(height: 12),
                orderExclusionBanner,
              ],
              if (batchCostSection != null) ...[
                const SizedBox(height: 12),
                batchCostSection,
              ],
            ],
          );
        },
      ),
    );

    final cardBody = showBatchProductActions
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              cardInner,
              Positioned(
                top: 2,
                right: 0,
                child: BatchProductActionsMenu(
                  currentType: product.batchItemType,
                  changeStatusTitle: changeBatchItemStatusLabel,
                  regularLabel: batchItemTypeRegularLabel,
                  orderLabel: batchItemTypeOrderLabel,
                  detachLabel: detachFromBatchLabel,
                  onAction: onBatchProductMenuAction ??
                      (_) async {},
                ),
              ),
            ],
          )
        : cardInner;

    if (!selectable) {
      return cardBody;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Checkbox(
            value: selected,
            onChanged: onSelectedChanged == null
                ? null
                : (value) => onSelectedChanged!(value ?? false),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: cardBody),
      ],
    );
  }
}

class _DashboardPurchaseLeftSection extends StatelessWidget {
  const _DashboardPurchaseLeftSection({
    required this.title,
    required this.createdAt,
    required this.imageSource,
    this.onOpenImage,
  });

  final String title;
  final DateTime createdAt;
  final String imageSource;
  final VoidCallback? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductThumbnailCard(
          source: imageSource,
          width: 80,
          height: 96,
          onTap: onOpenImage,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatProductDate(createdAt),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardPurchaseMetricsSection extends StatelessWidget {
  const _DashboardPurchaseMetricsSection({
    required this.articleLabel,
    required this.articleValue,
    required this.piecesLabel,
    required this.piecesValue,
    required this.totalLabel,
    required this.totalValue,
    this.articleBadge,
  });

  final String articleLabel;
  final String articleValue;
  final Widget? articleBadge;
  final String piecesLabel;
  final String piecesValue;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 280;

        final articleChip = _DashboardMetricChip(
          label: articleLabel,
          value: articleValue,
          icon: Icons.sell_outlined,
          trailing: articleBadge,
          emphasizeValue: true,
          stackTrailingBelow: articleBadge != null,
        );
        final piecesChip = _DashboardMetricChip(
          label: piecesLabel,
          value: piecesValue,
          icon: Icons.inventory_2_outlined,
        );
        final totalChip = _DashboardMetricChip(
          label: totalLabel,
          value: totalValue,
          icon: Icons.account_balance_wallet_outlined,
          highlighted: true,
        );

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              articleChip,
              const SizedBox(height: 8),
              piecesChip,
              const SizedBox(height: 8),
              totalChip,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: articleChip),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: piecesChip),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: totalChip),
          ],
        );
      },
    );
  }
}

class _DashboardMetricChip extends StatelessWidget {
  const _DashboardMetricChip({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
    this.trailing,
    this.emphasizeValue = false,
    this.stackTrailingBelow = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;
  final Widget? trailing;
  final bool emphasizeValue;
  final bool stackTrailingBelow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = highlighted ? AppColors.primary : AppColors.textMuted;
    final valueStyle = (emphasizeValue ? textTheme.titleLarge : textTheme.titleSmall)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      fontSize: emphasizeValue ? 22 : null,
      height: emphasizeValue ? 1.1 : null,
      letterSpacing: emphasizeValue ? 0.4 : null,
      color: highlighted ? AppColors.primary : AppColors.textPrimary,
    );

    final valueWidget = emphasizeValue
        ? Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: valueStyle,
            ),
          );

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        stackTrailingBelow && trailing != null ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlighted
              ? [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.surfaceStrong,
                ]
              : [AppColors.surfaceStrong, AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              if (stackTrailingBelow && trailing != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    valueWidget,
                    const SizedBox(height: 6),
                    trailing!,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: valueWidget),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      trailing!,
                    ],
                  ],
                ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Icon(icon, size: 16, color: accent.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _DashboardBatchUnitCostSection extends StatelessWidget {
  const _DashboardBatchUnitCostSection({
    required this.allocatedLabel,
    required this.finalLabel,
    required this.allocatedPrices,
    required this.finalPrices,
    required this.hasAllocatedExpense,
    required this.hasFinalCost,
    required this.notSpecified,
  });

  final String allocatedLabel;
  final String finalLabel;
  final CurrencyAmounts allocatedPrices;
  final CurrencyAmounts finalPrices;
  final bool hasAllocatedExpense;
  final bool hasFinalCost;
  final String notSpecified;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 300;
        final cards = [
          _DashboardPriceCard(
            title: allocatedLabel,
            icon: Icons.receipt_long_outlined,
            amounts: allocatedPrices,
            hasAmounts: hasAllocatedExpense,
            notSpecified: notSpecified,
          ),
          _DashboardPriceCard(
            title: finalLabel,
            icon: Icons.price_check_outlined,
            amounts: finalPrices,
            hasAmounts: hasFinalCost,
            notSpecified: notSpecified,
          ),
        ];

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Container(width: 1, height: 108, color: AppColors.border),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cards[0],
            const SizedBox(height: 10),
            cards[1],
          ],
        );
      },
    );
  }
}

class _DashboardPurchasePricesSection extends StatelessWidget {
  const _DashboardPurchasePricesSection({
    required this.priceTitle,
    required this.sharePriceTitle,
    required this.unitPrices,
    required this.sharePrices,
    required this.hasUnitPrice,
    required this.hasSharePrice,
    required this.notSpecified,
  });

  final String priceTitle;
  final String sharePriceTitle;
  final CurrencyAmounts unitPrices;
  final CurrencyAmounts sharePrices;
  final bool hasUnitPrice;
  final bool hasSharePrice;
  final String notSpecified;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 300;

        final cards = [
          _DashboardPriceCard(
            title: priceTitle,
            icon: Icons.payments_outlined,
            amounts: unitPrices,
            hasAmounts: hasUnitPrice,
            notSpecified: notSpecified,
          ),
          _DashboardPriceCard(
            title: sharePriceTitle,
            icon: Icons.pie_chart_outline,
            amounts: sharePrices,
            hasAmounts: hasSharePrice,
            notSpecified: notSpecified,
          ),
        ];

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Container(
                width: 1,
                height: 108,
                color: AppColors.border,
              ),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cards[0],
            const SizedBox(height: 10),
            cards[1],
          ],
        );
      },
    );
  }
}

class _DashboardPriceCard extends StatelessWidget {
  const _DashboardPriceCard({
    required this.title,
    required this.icon,
    required this.amounts,
    required this.hasAmounts,
    required this.notSpecified,
  });

  final String title;
  final IconData icon;
  final CurrencyAmounts amounts;
  final bool hasAmounts;
  final String notSpecified;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasAmounts)
            Text(
              notSpecified,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            )
          else ...[
            _DashboardCurrencyLine(
              value: formatProductMoney(amounts.cny),
              suffix: '¥',
              color: AppColors.primary,
            ),
            const SizedBox(height: 6),
            _DashboardCurrencyLine(
              value: formatProductMoney(amounts.usd),
              suffix: r'$',
              color: AppColors.accent,
            ),
            const SizedBox(height: 6),
            _DashboardCurrencyLine(
              value: formatProductMoney(amounts.uzs),
              suffix: ' сум',
              color: AppColors.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardCurrencyLine extends StatelessWidget {
  const _DashboardCurrencyLine({
    required this.value,
    required this.suffix,
    required this.color,
  });

  final String value;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        maxLines: 1,
        text: TextSpan(
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
          children: [
            TextSpan(text: value),
            TextSpan(
              text: suffix,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

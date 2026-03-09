import 'package:flutter/material.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_thumbnail_card.dart';
import '../widgets/section_cards.dart';
import 'photo_viewer_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});

  final AppStore store;

  String _tabLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Дашборд';
      case AppLanguage.en:
        return 'Dashboard';
      case AppLanguage.zh:
        return '看板';
    }
  }

  String _heroDescription(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Здесь видны все товары, которые уже закуплены. Каждый новый закуп автоматически попадает сюда.';
      case AppLanguage.en:
        return 'All purchased items are shown here. Every new purchase appears here automatically.';
      case AppLanguage.zh:
        return '这里会显示所有已经采购的商品。每次新采购都会自动出现在这里。';
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

  String _allPurchasesTitle(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Все закупы';
      case AppLanguage.en:
        return 'All purchases';
      case AppLanguage.zh:
        return '全部采购';
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final language = strings.language;
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
    final expensesTotal = expenses.fold<double>(
      0,
      (sum, expense) => sum + (expense.amountValue ?? 0),
    );
    final grandTotal = netTotal + expensesTotal;

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                    value: expensesTotal <= 0
                        ? '0'
                        : formatProductMoney(expensesTotal),
                    danger: true,
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
            Text(
              _allPurchasesTitle(language),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (purchases.isEmpty)
              EmptyStateCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.accent,
                title: _emptyTitle(language),
                description: _emptyDescription(language),
              )
            else
              ...purchases.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DashboardPurchaseCard(
                    product: product,
                    location:
                        store.shopById(product.shopId)?.location.trim() ?? '',
                    onOpenImage: (index) =>
                        _openViewer(context, product, index),
                  ),
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
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.label,
    required this.value,
    this.highlighted = false,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool highlighted;
  final bool danger;

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
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
                expense.amountValue == null
                    ? expense.amount
                    : formatProductMoney(expense.amountValue!),
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.danger,
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
        ],
      ),
    );
  }
}

class _DashboardPurchaseCard extends StatelessWidget {
  const _DashboardPurchaseCard({
    required this.product,
    required this.location,
    required this.onOpenImage,
  });

  final Product product;
  final String location;
  final ValueChanged<int> onOpenImage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final language = strings.language;
    final title = product.shopName.trim().isEmpty
        ? strings.t('newShop')
        : product.shopName;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumbnailCard(
            source: product.imagePaths.isEmpty ? '' : product.imagePaths.first,
            width: 92,
            height: 118,
            onTap: product.imagePaths.isEmpty ? null : () => onOpenImage(0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatProductDate(product.createdAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DashboardInfoChip(
                      label: strings.t('priceLabel'),
                      value: product.amount.isEmpty
                          ? strings.t('notSpecified')
                          : product.amount,
                    ),
                    _DashboardInfoChip(
                      label: strings.t('piecesLabel'),
                      value: '${product.quantity}',
                    ),
                    _DashboardInfoChip(
                      label: strings.t('totalLabel'),
                      value: product.totalValue == null
                          ? strings.t('notSpecified')
                          : formatProductMoney(product.totalValue!),
                      highlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  [
                    if (product.color.trim().isNotEmpty)
                      localizeColorValue(language, product.color),
                    if (product.material.trim().isNotEmpty)
                      localizeMaterialValue(language, product.material),
                    if (product.size.trim().isNotEmpty)
                      localizeSizeValue(language, product.size),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardInfoChip extends StatelessWidget {
  const _DashboardInfoChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

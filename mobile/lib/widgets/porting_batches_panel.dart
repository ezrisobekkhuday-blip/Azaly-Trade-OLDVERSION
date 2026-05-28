import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/product_batch.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../utils/porting_product_search.dart';
import '../utils/product_goods_totals.dart';
import 'batch_expenses_section.dart';
import 'porting_batch_header_summary.dart';

const int kPortingBatchPageSize = 25;

typedef PortingProductCardBuilder =
    Widget Function(
      Product product, {
      required bool selectable,
      required bool selected,
      required ValueChanged<bool>? onSelectedChanged,
      bool showBatchItemTypeControls,
    });

class PortingBatchesPanel extends StatefulWidget {
  const PortingBatchesPanel({
    super.key,
    required this.store,
    required this.language,
    required this.searchHint,
    required this.searchResultsTitle,
    required this.searchEmptyLabel,
    required this.batchesTitle,
    required this.unbatchedTitle,
    required this.allInBatchesHint,
    required this.emptyProductsLabel,
    required this.showMoreLabel,
    required this.batchTitleBuilder,
    required this.batchSummaryBuilder,
    required this.batchExpensesLabels,
    required this.selectedProductIds,
    required this.onToggleProductSelection,
    required this.productCardBuilder,
  });

  final AppStore store;
  final AppLanguage language;
  final String searchHint;
  final String searchResultsTitle;
  final String searchEmptyLabel;
  final String batchesTitle;
  final String unbatchedTitle;
  final String allInBatchesHint;
  final String emptyProductsLabel;
  final String showMoreLabel;
  final String Function(String batchName) batchTitleBuilder;
  final PortingBatchHeaderSummary Function(ProductGoodsTotals totals)
  batchSummaryBuilder;
  final BatchExpensesSectionLabels batchExpensesLabels;
  final ValueNotifier<Set<String>> selectedProductIds;
  final void Function(String productId, bool selected) onToggleProductSelection;
  final PortingProductCardBuilder productCardBuilder;

  @override
  State<PortingBatchesPanel> createState() => _PortingBatchesPanelState();
}

class _PortingBatchesPanelState extends State<PortingBatchesPanel> {
  static const String _unbatchedAccordionKey = '__unbatched__';

  final Set<String> _expandedAccordionKeys = <String>{};
  final TextEditingController _searchController = TextEditingController();
  List<ProductBatch> _sortedBatches = const [];
  List<Product> _sortedUnbatched = const [];
  List<Product> _searchResults = const [];
  Map<String, String> _batchNamesById = const {};
  String _searchQuery = '';
  bool _hasPurchases = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    widget.store.addListener(_syncFromStore);
    _syncFromStore();
  }

  @override
  void didUpdateWidget(covariant PortingBatchesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_syncFromStore);
      widget.store.addListener(_syncFromStore);
      _syncFromStore();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    widget.store.removeListener(_syncFromStore);
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = query;
      _searchResults = filterProductsForPortingSearch(
        widget.store.allProducts,
        query,
      );
    });
  }

  void _syncFromStore() {
    final batches = List<ProductBatch>.from(widget.store.batches)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final unbatched = List<Product>.from(widget.store.unbatchedProducts)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final hasPurchases = widget.store.allProducts.isNotEmpty;
    final batchNamesById = buildBatchNamesById(batches);
    final searchResults = filterProductsForPortingSearch(
      widget.store.allProducts,
      _searchQuery,
    );

    if (mounted) {
      setState(() {
        _sortedBatches = batches;
        _sortedUnbatched = unbatched;
        _batchNamesById = batchNamesById;
        _searchResults = searchResults;
        _hasPurchases = hasPurchases;
      });
    }
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) {
      return;
    }

    _searchController.clear();
  }

  void _toggleAccordion(String key) {
    setState(() {
      if (_expandedAccordionKeys.contains(key)) {
        _expandedAccordionKeys.remove(key);
      } else {
        _expandedAccordionKeys.add(key);
      }
    });
  }

  ProductGoodsTotals _summarizeProducts(List<Product> products) {
    return summarizeProductGoodsTotals(products);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPurchases) {
      return const SizedBox.shrink();
    }

    final hasSearchQuery = _searchQuery.trim().isNotEmpty;
    final searchSummary = _summarizeProducts(_searchResults);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PortingSearchField(
          controller: _searchController,
          hintText: widget.searchHint,
          onClear: _clearSearch,
        ),
        if (hasSearchQuery) ...[
          const SizedBox(height: 14),
          _PortingSearchResultsSection(
            key: ValueKey('search-$_searchQuery-${_searchResults.length}'),
            title: widget.searchResultsTitle,
            summary: widget.batchSummaryBuilder(searchSummary),
            products: _searchResults,
            emptyLabel: widget.searchEmptyLabel,
            showMoreLabel: widget.showMoreLabel,
            batchNamesById: _batchNamesById,
            batchTitleBuilder: widget.batchTitleBuilder,
            selectedProductIds: widget.selectedProductIds,
            onToggleProductSelection: widget.onToggleProductSelection,
            productCardBuilder: widget.productCardBuilder,
          ),
          const SizedBox(height: 18),
        ],
        if (_sortedBatches.isNotEmpty) ...[
          Text(
            widget.batchesTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ..._sortedBatches.map((batch) {
            final products = List<Product>.from(batch.products)
              ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
            final summary = _summarizeProducts(products);

            return _PortingAccordionSection(
              key: ValueKey('batch-${batch.id}'),
              title: widget.batchTitleBuilder(batch.name),
              batchName: batch.name,
              language: widget.language,
              summary: widget.batchSummaryBuilder(summary),
              expanded: _expandedAccordionKeys.contains(batch.id),
              onToggle: () => _toggleAccordion(batch.id),
              batchId: batch.id,
              batchExpenses: List<Expense>.from(widget.store.expenses),
              batchExpensesLabels: widget.batchExpensesLabels,
              products: products,
              emptyLabel: widget.emptyProductsLabel,
              showMoreLabel: widget.showMoreLabel,
              selectedProductIds: widget.selectedProductIds,
              onToggleProductSelection: widget.onToggleProductSelection,
              productCardBuilder: widget.productCardBuilder,
              showBatchItemTypeControls: true,
            );
          }),
        ],
        if (_sortedUnbatched.isNotEmpty) ...[
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final unbatchedSummary = _summarizeProducts(_sortedUnbatched);

              return _PortingAccordionSection(
            key: const ValueKey(_unbatchedAccordionKey),
            title: widget.unbatchedTitle,
            summary: widget.batchSummaryBuilder(unbatchedSummary),
            expanded: _expandedAccordionKeys.contains(_unbatchedAccordionKey),
            onToggle: () => _toggleAccordion(_unbatchedAccordionKey),
            accentColor: AppColors.accent,
            products: _sortedUnbatched,
            emptyLabel: widget.emptyProductsLabel,
            showMoreLabel: widget.showMoreLabel,
            selectable: true,
            selectedProductIds: widget.selectedProductIds,
            onToggleProductSelection: widget.onToggleProductSelection,
            productCardBuilder: widget.productCardBuilder,
              );
            },
          ),
        ] else if (_sortedBatches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              widget.allInBatchesHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _PortingAccordionSection extends StatefulWidget {
  const _PortingAccordionSection({
    super.key,
    required this.title,
    this.batchName = '',
    this.language = AppLanguage.ru,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.products,
    required this.emptyLabel,
    required this.showMoreLabel,
    required this.selectedProductIds,
    required this.onToggleProductSelection,
    required this.productCardBuilder,
    this.accentColor = AppColors.primary,
    this.selectable = false,
    this.showBatchItemTypeControls = false,
    this.batchId,
    this.batchExpenses = const [],
    this.batchExpensesLabels,
  });

  final String title;
  final String batchName;
  final AppLanguage language;
  final PortingBatchHeaderSummary summary;
  final bool expanded;
  final VoidCallback onToggle;
  final String? batchId;
  final List<Expense> batchExpenses;
  final BatchExpensesSectionLabels? batchExpensesLabels;
  final List<Product> products;
  final String emptyLabel;
  final String showMoreLabel;
  final Color accentColor;
  final bool selectable;
  final bool showBatchItemTypeControls;
  final ValueNotifier<Set<String>> selectedProductIds;
  final void Function(String productId, bool selected) onToggleProductSelection;
  final PortingProductCardBuilder productCardBuilder;

  @override
  State<_PortingAccordionSection> createState() => _PortingAccordionSectionState();
}

class _PortingAccordionSectionState extends State<_PortingAccordionSection> {
  bool _hasBeenExpanded = false;

  @override
  void didUpdateWidget(covariant _PortingAccordionSection oldWidget) {
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
                ? widget.accentColor.withValues(alpha: 0.42)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(
                alpha: widget.expanded ? 0.1 : 0.04,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            PortingBatchHeaderSummaryView(
                              summary: widget.summary,
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
                          color: widget.accentColor.withValues(
                            alpha: widget.expanded ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.accentColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: AnimatedRotation(
                          turns: widget.expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Icon(
                            Icons.expand_more,
                            size: 22,
                            color: widget.accentColor,
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
                        color: widget.accentColor.withValues(alpha: 0.16),
                      ),
                      const SizedBox(height: 12),
                      if (widget.batchId != null &&
                          widget.batchExpensesLabels != null) ...[
                        BatchExpensesSection(
                          language: widget.language,
                          batchName: widget.batchName,
                          allExpenses: widget.batchExpenses,
                          batchId: widget.batchId!,
                          batchProducts: widget.products,
                          labels: widget.batchExpensesLabels!,
                          accentColor: widget.accentColor,
                        ),
                        const SizedBox(height: 14),
                      ],
                      _PortingAccordionProductsBody(
                        key: ValueKey(
                          'products-${widget.title}-${widget.products.length}',
                        ),
                        products: widget.products,
                        emptyLabel: widget.emptyLabel,
                        showMoreLabel: widget.showMoreLabel,
                        selectable: widget.selectable,
                        selectedProductIds: widget.selectedProductIds,
                        onToggleProductSelection: widget.onToggleProductSelection,
                        productCardBuilder: widget.productCardBuilder,
                        showBatchItemTypeControls: widget.showBatchItemTypeControls,
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

class _PortingAccordionProductsBody extends StatefulWidget {
  const _PortingAccordionProductsBody({
    super.key,
    required this.products,
    required this.emptyLabel,
    required this.showMoreLabel,
    required this.selectable,
    required this.selectedProductIds,
    required this.onToggleProductSelection,
    required this.productCardBuilder,
    this.showBatchItemTypeControls = false,
  });

  final List<Product> products;
  final String emptyLabel;
  final String showMoreLabel;
  final bool selectable;
  final bool showBatchItemTypeControls;
  final ValueNotifier<Set<String>> selectedProductIds;
  final void Function(String productId, bool selected) onToggleProductSelection;
  final PortingProductCardBuilder productCardBuilder;

  @override
  State<_PortingAccordionProductsBody> createState() =>
      _PortingAccordionProductsBodyState();
}

class _PortingAccordionProductsBodyState
    extends State<_PortingAccordionProductsBody>
    with AutomaticKeepAliveClientMixin {
  int _visibleCount = kPortingBatchPageSize;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _PortingAccordionProductsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products.length < _visibleCount) {
      _visibleCount = widget.products.length;
    } else if (oldWidget.products.length != widget.products.length &&
        _visibleCount < kPortingBatchPageSize) {
      _visibleCount = kPortingBatchPageSize.clamp(0, widget.products.length);
    }
  }

  void _showMore() {
    setState(() {
      _visibleCount = (_visibleCount + kPortingBatchPageSize).clamp(
        0,
        widget.products.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.products.isEmpty) {
      return Text(
        widget.emptyLabel,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textMuted,
        ),
      );
    }

    final visibleCount = _visibleCount.clamp(0, widget.products.length);
    final hasMore = visibleCount < widget.products.length;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.selectedProductIds,
      builder: (context, selectedIds, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < visibleCount; index += 1)
              RepaintBoundary(
                key: ValueKey(widget.products[index].id),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleCount - 1 && !hasMore ? 0 : 14,
                  ),
                  child: widget.productCardBuilder(
                    widget.products[index],
                    selectable: widget.selectable,
                    selected: selectedIds.contains(widget.products[index].id),
                    onSelectedChanged: widget.selectable
                        ? (value) => widget.onToggleProductSelection(
                            widget.products[index].id,
                            value,
                          )
                        : null,
                    showBatchItemTypeControls: widget.showBatchItemTypeControls,
                  ),
                ),
              ),
            if (hasMore)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _showMore,
                  child: Text(
                    '${widget.showMoreLabel} (${widget.products.length - visibleCount})',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PortingSearchField extends StatelessWidget {
  const _PortingSearchField({
    required this.controller,
    required this.hintText,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.surfaceStrong.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _PortingSearchResultsSection extends StatelessWidget {
  const _PortingSearchResultsSection({
    super.key,
    required this.title,
    required this.summary,
    required this.products,
    required this.emptyLabel,
    required this.showMoreLabel,
    required this.batchNamesById,
    required this.batchTitleBuilder,
    required this.selectedProductIds,
    required this.onToggleProductSelection,
    required this.productCardBuilder,
  });

  final String title;
  final PortingBatchHeaderSummary summary;
  final List<Product> products;
  final String emptyLabel;
  final String showMoreLabel;
  final Map<String, String> batchNamesById;
  final String Function(String batchName) batchTitleBuilder;
  final ValueNotifier<Set<String>> selectedProductIds;
  final void Function(String productId, bool selected) onToggleProductSelection;
  final PortingProductCardBuilder productCardBuilder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            PortingBatchHeaderSummaryView(summary: summary),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Text(
                emptyLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              )
            else
              _PortingSearchResultsBody(
                products: products,
                showMoreLabel: showMoreLabel,
                batchNamesById: batchNamesById,
                batchTitleBuilder: batchTitleBuilder,
                selectedProductIds: selectedProductIds,
                onToggleProductSelection: onToggleProductSelection,
                productCardBuilder: productCardBuilder,
              ),
          ],
        ),
      ),
    );
  }
}

class _PortingSearchResultsBody extends StatefulWidget {
  const _PortingSearchResultsBody({
    required this.products,
    required this.showMoreLabel,
    required this.batchNamesById,
    required this.batchTitleBuilder,
    required this.selectedProductIds,
    required this.onToggleProductSelection,
    required this.productCardBuilder,
  });

  final List<Product> products;
  final String showMoreLabel;
  final Map<String, String> batchNamesById;
  final String Function(String batchName) batchTitleBuilder;
  final ValueNotifier<Set<String>> selectedProductIds;
  final void Function(String productId, bool selected) onToggleProductSelection;
  final PortingProductCardBuilder productCardBuilder;

  @override
  State<_PortingSearchResultsBody> createState() =>
      _PortingSearchResultsBodyState();
}

class _PortingSearchResultsBodyState extends State<_PortingSearchResultsBody> {
  int _visibleCount = kPortingBatchPageSize;

  @override
  void didUpdateWidget(covariant _PortingSearchResultsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _visibleCount = kPortingBatchPageSize.clamp(0, widget.products.length);
    }
  }

  void _showMore() {
    setState(() {
      _visibleCount = (_visibleCount + kPortingBatchPageSize).clamp(
        0,
        widget.products.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _visibleCount.clamp(0, widget.products.length);
    final hasMore = visibleCount < widget.products.length;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.selectedProductIds,
      builder: (context, selectedIds, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < visibleCount; index += 1)
              RepaintBoundary(
                key: ValueKey(widget.products[index].id),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleCount - 1 && !hasMore ? 0 : 14,
                  ),
                  child: _PortingSearchResultCard(
                    product: widget.products[index],
                    batchLabel: batchNameForProduct(
                      widget.products[index],
                      widget.batchNamesById,
                    ),
                    batchTitleBuilder: widget.batchTitleBuilder,
                    selected: selectedIds.contains(widget.products[index].id),
                    onSelectedChanged: (value) =>
                        widget.onToggleProductSelection(
                          widget.products[index].id,
                          value,
                        ),
                    productCardBuilder: widget.productCardBuilder,
                  ),
                ),
              ),
            if (hasMore)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _showMore,
                  child: Text(
                    '${widget.showMoreLabel} (${widget.products.length - visibleCount})',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PortingSearchResultCard extends StatelessWidget {
  const _PortingSearchResultCard({
    required this.product,
    required this.batchLabel,
    required this.batchTitleBuilder,
    required this.selected,
    required this.onSelectedChanged,
    required this.productCardBuilder,
  });

  final Product product;
  final String? batchLabel;
  final String Function(String batchName) batchTitleBuilder;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final PortingProductCardBuilder productCardBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (batchLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              batchTitleBuilder(batchLabel!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        productCardBuilder(
          product,
          selectable: true,
          selected: selected,
          onSelectedChanged: onSelectedChanged,
          showBatchItemTypeControls: product.batchId != null,
        ),
      ],
    );
  }
}

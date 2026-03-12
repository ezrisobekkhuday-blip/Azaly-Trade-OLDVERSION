import 'package:flutter/material.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';
import 'product_thumbnail_card.dart';
import 'suggestion_field.dart';

class StorefrontItemSummaryCard extends StatelessWidget {
  const StorefrontItemSummaryCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onRemove,
  });

  final StorefrontItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final chips = <Widget>[
      if (item.amount.trim().isNotEmpty)
        _StorefrontOverlayChip(
          icon: Icons.payments_outlined,
          label: item.amount.trim(),
        ),
      if (item.color.trim().isNotEmpty)
        _StorefrontOverlayChip(
          icon: Icons.palette_outlined,
          label: item.color.trim(),
        ),
      if (item.material.trim().isNotEmpty)
        _StorefrontOverlayChip(
          icon: Icons.checkroom_outlined,
          label: item.material.trim(),
        ),
      if (item.size.trim().isNotEmpty)
        _StorefrontOverlayChip(
          icon: Icons.straighten_outlined,
          label: item.size.trim(),
        ),
      if (item.measurements.trim().isNotEmpty)
        _StorefrontOverlayChip(
          icon: Icons.square_foot_outlined,
          label: item.measurements.trim(),
        ),
    ];

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 152,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF111A2D), Color(0xFF0C1323)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProductThumbnailCard(
                source: item.imagePath,
                width: 112,
                height: 148,
                onTap: onEdit,
                onRemove: onRemove,
              ),
            ),
            const SizedBox(height: 8),
            if (chips.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _StorefrontOverlayChip(
                  icon: Icons.edit_outlined,
                  label: strings.t('fillDetails'),
                  highlighted: true,
                ),
              )
            else
              Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
        ),
      ),
    );
  }
}

class StorefrontItemEditorSheet extends StatefulWidget {
  const StorefrontItemEditorSheet({super.key, required this.item});

  final StorefrontItem item;

  @override
  State<StorefrontItemEditorSheet> createState() =>
      _StorefrontItemEditorSheetState();
}

class _StorefrontItemEditorSheetState extends State<StorefrontItemEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _colorController;
  late final TextEditingController _materialController;
  late final TextEditingController _sizeController;
  late final TextEditingController _measurementsController;
  bool _isAmountExpanded = true;
  bool _isColorExpanded = false;
  bool _isMaterialExpanded = false;
  bool _isSizeExpanded = false;
  bool _isMeasurementsExpanded = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.item.amount);
    _colorController = TextEditingController(text: widget.item.color);
    _materialController = TextEditingController(text: widget.item.material);
    _sizeController = TextEditingController(text: widget.item.size);
    _measurementsController = TextEditingController(
      text: widget.item.measurements,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _sizeController.dispose();
    _measurementsController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      widget.item.copyWith(
        amount: _amountController.text.trim(),
        color: _colorController.text.trim(),
        material: _materialController.text.trim(),
        size: _sizeController.text.trim(),
        measurements: _measurementsController.text.trim(),
      ),
    );
  }

  String _summaryOf(String value, AppStrings strings) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? strings.t('notSpecified') : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.background, AppColors.backgroundSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.t('storefrontPhotos'),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF04120F),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(strings.t('save')),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ProductImage(
                    source: widget.item.imagePath,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                _StorefrontEditorSection(
                  title: strings.t('purchasePriceLabel'),
                  summary: _summaryOf(_amountController.text, strings),
                  isExpanded: _isAmountExpanded,
                  onToggle: () {
                    setState(() {
                      _isAmountExpanded = !_isAmountExpanded;
                    });
                  },
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: strings.t('purchasePriceLabel'),
                      hintText: strings.t('purchasePriceHint'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _StorefrontEditorSection(
                  title: strings.t('colorLabel'),
                  summary: _summaryOf(_colorController.text, strings),
                  isExpanded: _isColorExpanded,
                  onToggle: () {
                    setState(() {
                      _isColorExpanded = !_isColorExpanded;
                    });
                  },
                  child: SuggestionField(
                    controller: _colorController,
                    label: strings.t('colorLabel'),
                    hint: strings.t('colorHint'),
                    suggestions: localizedColorSuggestions(strings.language),
                    quickGroups: [
                      SuggestionGroup(
                        label: strings.t('popularColors'),
                        items: localizedPopularColorSuggestions(
                          strings.language,
                        ),
                      ),
                    ],
                    allowMultiSelect: true,
                  ),
                ),
                const SizedBox(height: 14),
                _StorefrontEditorSection(
                  title: strings.t('materialLabel'),
                  summary: _summaryOf(_materialController.text, strings),
                  isExpanded: _isMaterialExpanded,
                  onToggle: () {
                    setState(() {
                      _isMaterialExpanded = !_isMaterialExpanded;
                    });
                  },
                  child: SuggestionField(
                    controller: _materialController,
                    label: strings.t('materialLabel'),
                    hint: strings.t('materialHint'),
                    suggestions: localizedMaterialSuggestions(strings.language),
                    quickGroups: [
                      SuggestionGroup(
                        label: strings.t('popular'),
                        items: localizedPopularMaterialSuggestions(
                          strings.language,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _StorefrontEditorSection(
                  title: strings.t('sizeLabel'),
                  summary: _summaryOf(_sizeController.text, strings),
                  isExpanded: _isSizeExpanded,
                  onToggle: () {
                    setState(() {
                      _isSizeExpanded = !_isSizeExpanded;
                    });
                  },
                  child: SuggestionField(
                    controller: _sizeController,
                    label: strings.t('sizeLabel'),
                    hint: strings.t('sizeHint'),
                    suggestions: localizedSizeSuggestions(strings.language),
                    quickGroups: [
                      SuggestionGroup(
                        label: strings.t('alphaSizes'),
                        items: alphaSizeSuggestions,
                      ),
                      SuggestionGroup(
                        label: strings.t('numericSizes'),
                        items: numericSizeSuggestions,
                      ),
                      SuggestionGroup(
                        label: strings.t('specialSizes'),
                        items: localizedSpecialSizeSuggestions(
                          strings.language,
                        ),
                      ),
                    ],
                    allowMultiSelect: true,
                    collapsibleSuggestions: true,
                    initiallyExpanded: false,
                  ),
                ),
                const SizedBox(height: 14),
                _StorefrontEditorSection(
                  title: strings.t('measurementsLabel'),
                  summary: _summaryOf(_measurementsController.text, strings),
                  isExpanded: _isMeasurementsExpanded,
                  onToggle: () {
                    setState(() {
                      _isMeasurementsExpanded = !_isMeasurementsExpanded;
                    });
                  },
                  child: TextField(
                    controller: _measurementsController,
                    decoration: InputDecoration(
                      labelText: strings.t('measurementsLabel'),
                      hintText: strings.t('measurementsHint'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorefrontOverlayChip extends StatelessWidget {
  const _StorefrontOverlayChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.88)
            : const Color(0xB311182B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlighted ? const Color(0xFF08110F) : AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlighted
                    ? const Color(0xFF08110F)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorefrontEditorSection extends StatelessWidget {
  const _StorefrontEditorSection({
    required this.title,
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String summary;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isExpanded
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: onToggle,
                child: Text(strings.t('collapse')),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_thumbnail_card.dart';
import '../widgets/suggestion_field.dart';

const double _pickedImageMaxDimension = 1440;
const int _pickedImageQuality = 70;

class ProductEditorSheet extends StatefulWidget {
  const ProductEditorSheet({super.key, required this.product});

  final Product product;

  @override
  State<ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<ProductEditorSheet> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _amountController;
  late final TextEditingController _colorController;
  late final TextEditingController _materialController;
  late final TextEditingController _sizeController;
  late final TextEditingController _quantityController;
  late final List<String> _imagePaths;
  late int _quantity;
  bool _didApplyLocalizedValues = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.product.amount);
    _colorController = TextEditingController(text: widget.product.color);
    _materialController = TextEditingController(text: widget.product.material);
    _sizeController = TextEditingController(text: widget.product.size);
    _quantity = widget.product.quantity < 1 ? 1 : widget.product.quantity;
    _quantityController = TextEditingController(text: '$_quantity');
    _imagePaths = List<String>.from(widget.product.imagePaths);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didApplyLocalizedValues) {
      return;
    }

    final language = AppStrings.of(context).language;
    _colorController.text = localizeColorValue(language, _colorController.text);
    _materialController.text = localizeMaterialValue(
      language,
      _materialController.text,
    );
    _sizeController.text = localizeSizeValue(language, _sizeController.text);
    _didApplyLocalizedValues = true;
  }

  double? get _draftTotal {
    return calculateNetTotal(_amountController.text, _quantity);
  }

  void _setQuantity(int value) {
    final normalized = value < 1 ? 1 : value;

    setState(() {
      _quantity = normalized;
      _quantityController.value = TextEditingValue(
        text: '$normalized',
        selection: TextSelection.collapsed(offset: '$normalized'.length),
      );
    });
  }

  void _syncQuantityFromText(String value) {
    final parsed = int.tryParse(value.trim());

    if (parsed == null) {
      return;
    }

    _setQuantity(parsed);
  }

  Future<void> _pickFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || files.isEmpty) {
        return;
      }

      setState(() {
        _imagePaths.addAll(files.map((file) => file.path));
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotOpenGallery'));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _imagePaths.add(file.path);
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotOpenCamera'));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (_imagePaths.isEmpty) {
      _showMessage(AppStrings.of(context).t('keepAtLeastOnePhoto'));
      return;
    }

    Navigator.of(context).pop(
      widget.product.copyWith(
        imagePaths: List<String>.from(_imagePaths),
        amount: _amountController.text.trim(),
        quantity: _quantity,
        color: _colorController.text.trim(),
        material: _materialController.text.trim(),
        size: _sizeController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final language = strings.language;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.t('editPurchaseTitle'),
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.t('editPurchaseDescription'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(strings.t('gallery')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(strings.t('camera')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_imagePaths.isEmpty)
                  const _EmptyEditorImages()
                else
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final path = _imagePaths[index];

                        return ProductThumbnailCard(
                          source: path,
                          onRemove: () =>
                              setState(() => _imagePaths.removeAt(index)),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 18),
                _EditorPurchaseSummaryCard(
                  amount: _amountController.text,
                  quantity: _quantity,
                  total: _draftTotal,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amountController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: strings.t('purchasePriceLabel'),
                    hintText: strings.t('purchasePriceHint'),
                  ),
                ),
                const SizedBox(height: 14),
                _EditorQuantityStepper(
                  controller: _quantityController,
                  quantity: _quantity,
                  onChanged: _syncQuantityFromText,
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _colorController,
                  label: strings.t('colorLabel'),
                  hint: strings.t('colorHint'),
                  suggestions: localizedColorSuggestions(language),
                  quickGroups: [
                    SuggestionGroup(
                      label: strings.t('popularColors'),
                      items: localizedPopularColorSuggestions(language),
                    ),
                  ],
                  allowMultiSelect: true,
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _materialController,
                  label: strings.t('materialLabel'),
                  hint: strings.t('materialHint'),
                  suggestions: localizedMaterialSuggestions(language),
                  quickGroups: [
                    SuggestionGroup(
                      label: strings.t('popular'),
                      items: localizedPopularMaterialSuggestions(language),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _sizeController,
                  label: strings.t('sizeLabel'),
                  hint: strings.t('sizeHint'),
                  suggestions: localizedSizeSuggestions(language),
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
                      items: localizedSpecialSizeSuggestions(language),
                    ),
                  ],
                  allowMultiSelect: true,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF08110F),
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _save,
                    child: Text(strings.t('savePurchase')),
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

class _EditorPurchaseSummaryCard extends StatelessWidget {
  const _EditorPurchaseSummaryCard({
    required this.amount,
    required this.quantity,
    required this.total,
  });

  final String amount;
  final int quantity;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final grossTotal = calculateGrossTotal(amount, quantity);
    final supplierShare = calculateSupplierShare(amount, quantity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('purchaseTotalTitle'),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            total == null
                ? strings.t('enterPriceAndQuantity')
                : '${amount.trim().isEmpty ? '0' : amount.trim()} x $quantity = ${formatProductMoney(grossTotal!)}',
            style: textTheme.bodyLarge?.copyWith(
              color: total == null
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
          if (total != null && supplierShare != null) ...[
            const SizedBox(height: 6),
            Text(
              '${strings.t('supplierShareLabel')}: +${formatProductMoney(supplierShare)}',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${strings.t('totalLabel')}: ${formatProductMoney(total!)}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorQuantityStepper extends StatelessWidget {
  const _EditorQuantityStepper({
    required this.controller,
    required this.quantity,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int quantity;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('quantityLabel'),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '1'),
          ),
        ],
      ),
    );
  }
}

class _EmptyEditorImages extends StatelessWidget {
  const _EmptyEditorImages();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        strings.t('addAtLeastOnePhoto'),
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/product_presets.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/suggestion_field.dart';

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

  double? get _draftTotal {
    final amount = parseProductAmount(_amountController.text);

    if (amount == null) {
      return null;
    }

    return amount * _quantity;
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
      final files = await _picker.pickMultiImage(imageQuality: 74);

      if (!mounted || files.isEmpty) {
        return;
      }

      setState(() {
        _imagePaths.addAll(files.map((file) => file.path));
      });
    } catch (_) {
      _showMessage('Не удалось открыть галерею.');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 74,
      );

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _imagePaths.add(file.path);
      });
    } catch (_) {
      _showMessage('Не удалось открыть камеру.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (_imagePaths.isEmpty) {
      _showMessage('У закупа должно остаться хотя бы одно фото.');
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
                            'Редактировать закуп',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Обнови фото, цену закупа, количество и остальные поля.',
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
                        label: const Text('Галерея'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Камера'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_imagePaths.isEmpty)
                  const _EmptyEditorImages()
                else
                  SizedBox(
                    height: 122,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final path = _imagePaths[index];

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: ProductImage(
                                source: path,
                                width: 122,
                                height: 122,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.background
                                      .withValues(alpha: 0.82),
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                onPressed: () =>
                                    setState(() => _imagePaths.removeAt(index)),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
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
                  decoration: const InputDecoration(
                    labelText: 'Цена закупа',
                    hintText: 'Например: 120 000',
                  ),
                ),
                const SizedBox(height: 14),
                _EditorQuantityStepper(
                  controller: _quantityController,
                  quantity: _quantity,
                  onChanged: _syncQuantityFromText,
                  onDecrease: () => _setQuantity(_quantity - 1),
                  onIncrease: () => _setQuantity(_quantity + 1),
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _colorController,
                  label: 'Цвет',
                  hint: 'Например: Black, Beige, Blue',
                  suggestions: colorSuggestions,
                  quickGroups: const [
                    SuggestionGroup(
                      label: 'Популярные цвета',
                      items: popularColorSuggestions,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _materialController,
                  label: 'Материал',
                  hint: 'Например: Angora, Cotton, Leather',
                  suggestions: materialSuggestions,
                  quickGroups: const [
                    SuggestionGroup(
                      label: 'Популярные',
                      items: popularMaterialSuggestions,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _sizeController,
                  label: 'Размер',
                  hint: 'Например: XL, 58, Standard',
                  suggestions: sizeSuggestions,
                  quickGroups: const [
                    SuggestionGroup(
                      label: 'Буквенные размеры',
                      items: alphaSizeSuggestions,
                    ),
                    SuggestionGroup(
                      label: 'Числовые размеры',
                      items: numericSizeSuggestions,
                    ),
                    SuggestionGroup(
                      label: 'Особые',
                      items: specialSizeSuggestions,
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
                    child: const Text('Сохранить закуп'),
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
            'Итог закупа',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            total == null
                ? 'Укажи цену и количество'
                : '${amount.trim().isEmpty ? '0' : amount.trim()} x $quantity = ${formatProductMoney(total!)}',
            style: textTheme.bodyLarge?.copyWith(
              color: total == null
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
          ),
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
    required this.onDecrease,
    required this.onIncrease,
  });

  final TextEditingController controller;
  final int quantity;
  final ValueChanged<String> onChanged;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            'Количество',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: quantity > 1 ? onDecrease : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Штук',
                    hintText: '1',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onIncrease,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF08110F),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Добавь хотя бы одно фото, чтобы сохранить закуп.',
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

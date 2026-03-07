import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';

class ProductEditorSheet extends StatefulWidget {
  const ProductEditorSheet({super.key, required this.product});

  final Product product;

  @override
  State<ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<ProductEditorSheet> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _amountController;
  late final TextEditingController _materialController;
  late final TextEditingController _sizeController;
  late final List<String> _imagePaths;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.product.amount);
    _materialController = TextEditingController(text: widget.product.material);
    _sizeController = TextEditingController(text: widget.product.size);
    _imagePaths = List<String>.from(widget.product.imagePaths);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _materialController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);

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
        imageQuality: 85,
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
      _showMessage('У товара должно остаться хотя бы одно фото.');
      return;
    }

    Navigator.of(context).pop(
      widget.product.copyWith(
        imagePaths: List<String>.from(_imagePaths),
        amount: _amountController.text.trim(),
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
          padding: const EdgeInsets.all(20),
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
                            'Редактировать товар',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Можно поменять фото, сумму, материал и размер.',
                            style: textTheme.bodyLarge?.copyWith(
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
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    hintText: 'Например: 120 000',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _materialController,
                  decoration: const InputDecoration(
                    labelText: 'Материал',
                    hintText: 'Например: кожа',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Размер',
                    hintText: 'Например: 42 x 30',
                  ),
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
                    child: const Text('Сохранить'),
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
        'Добавь хотя бы одно фото, чтобы сохранить товар.',
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

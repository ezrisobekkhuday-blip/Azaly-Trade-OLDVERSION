import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({
    super.key,
    required this.store,
    required this.onOpenProducts,
  });

  final AppStore store;
  final VoidCallback onOpenProducts;

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  final List<String> _imagePaths = [];
  bool _isSubmitting = false;

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

  Future<void> _createProduct() async {
    if (_imagePaths.isEmpty) {
      _showMessage('Сначала добавьте хотя бы одно фото товара.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.store.createProduct(
        imagePaths: _imagePaths,
        amount: _amountController.text,
        material: _materialController.text,
        size: _sizeController.text,
      );

      if (!mounted) {
        return;
      }

      _amountController.clear();
      _materialController.clear();
      _sizeController.clear();

      setState(() {
        _imagePaths.clear();
      });

      widget.onOpenProducts();
      _showMessage('Товар создан и уже лежит во вкладке «Товары».');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: 'Не удалось сохранить товар на сервере.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
          children: [
            _HeroCard(
              userName: widget.store.displayName,
              totalProducts: widget.store.allProducts.length,
              currentImages: _imagePaths.length,
            ),
            const SizedBox(height: 18),
            _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Фото товара',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Можно добавить сколько угодно фото из галереи или камеры.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Галерея',
                          onPressed: _isSubmitting ? null : _pickFromGallery,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_camera_outlined,
                          label: 'Камера',
                          onPressed: _isSubmitting ? null : _takePhoto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _imagePaths.isEmpty
                      ? const _EmptyImagesCard()
                      : SizedBox(
                          height: 124,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imagePaths.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final path = _imagePaths[index];

                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: ProductImage(
                                      source: path,
                                      width: 124,
                                      height: 124,
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
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => setState(
                                              () => _imagePaths.removeAt(index),
                                            ),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 18),
                  _LabeledField(
                    controller: _amountController,
                    label: 'Сумма',
                    hint: 'Например: 120 000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _materialController,
                    label: 'Материал',
                    hint: 'Например: кожа',
                  ),
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _sizeController,
                    label: 'Размер',
                    hint: 'Например: 42 x 30',
                  ),
                  const SizedBox(height: 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF56B7DD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF04120F),
                        shadowColor: Colors.transparent,
                        minimumSize: const Size.fromHeight(64),
                        disabledBackgroundColor: Colors.transparent,
                        disabledForegroundColor: const Color(0x8804120F),
                      ),
                      onPressed: _isSubmitting ? null : _createProduct,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSubmitting
                                    ? 'Сохраняем товар...'
                                    : 'Создать товар',
                                style: textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF04120F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Статус после создания: Новый',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xAA04120F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF04120F),
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _NextStepCard(),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.userName,
    required this.totalProducts,
    required this.currentImages,
  });

  final String userName;
  final int totalProducts;
  final int currentImages;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          colors: [Color(0x2E7C92FF), Color(0x1461E5BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'DARK FLOW',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Создать товар',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$userName, добавьте фото, заполните поля и сохраните карточку товара со статусом «Новый».',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: currentImages.toString(),
                  label: 'Фото сейчас',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: totalProducts.toString(),
                  label: 'Всего товаров',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x73060A14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.surfaceStrong,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.surfaceStrong.withValues(alpha: 0.5),
        disabledForegroundColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _EmptyImagesCard extends StatelessWidget {
  const _EmptyImagesCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.image_outlined, size: 30, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Фото пока не добавлены',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Сначала выберите изображения товара. Ограничения по количеству нет.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Дальше смотри во вкладке «Товары»',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'После создания карточка сразу попадёт во второй раздел, где её можно открыть, редактировать, добавить в избранное или удалить.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
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

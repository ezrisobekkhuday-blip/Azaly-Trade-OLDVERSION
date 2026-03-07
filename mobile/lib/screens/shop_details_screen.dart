import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/product_presets.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/suggestion_field.dart';
import 'photo_viewer_page.dart';
import 'product_editor_sheet.dart';

class ShopDetailsScreen extends StatefulWidget {
  const ShopDetailsScreen({
    super.key,
    required this.store,
    required this.shopId,
  });

  final AppStore store;
  final String shopId;

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  final List<String> _imagePaths = [];
  bool _isSubmitting = false;

  Shop? get _shop => widget.store.shopById(widget.shopId);

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
    final shop = _shop;

    if (shop == null) {
      return;
    }

    if (_imagePaths.isEmpty) {
      _showMessage('Сначала добавьте фото товара.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.store.createProduct(
        shopId: shop.id,
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
      _showMessage('Товар создан внутри магазина.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(error, fallbackMessage: 'Не удалось создать товар.'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openEditor(Product product) async {
    final updated = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditorSheet(product: product),
    );

    if (updated == null || !mounted) {
      return;
    }

    try {
      await widget.store.updateProduct(updated);
      if (mounted) {
        _showMessage('Товар обновлён.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(error, fallbackMessage: 'Не удалось обновить товар.'),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: const Text(
          'Товар будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.store.deleteProduct(product.id);
      if (mounted) {
        _showMessage('Товар удалён.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(error, fallbackMessage: 'Не удалось удалить товар.'),
      );
    }
  }

  Future<void> _toggleFavorite(Product product) async {
    try {
      await widget.store.toggleFavorite(product.id);
      if (mounted) {
        _showMessage('Товар перенесён в избранные.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(error, fallbackMessage: 'Не удалось обновить избранное.'),
      );
    }
  }

  Future<void> _openViewer(Product product, int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerPage(product: product, initialIndex: index),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _openImagePreview(String title, String imageSource) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _SingleImagePage(title: title, imageSource: imageSource),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final shop = _shop;

    if (shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Магазин')),
        body: const AppBackground(
          child: Center(child: Text('Магазин не найден')),
        ),
      );
    }

    final products = widget.store.productsForShop(shop.id);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name.isEmpty ? 'Новый магазин' : shop.name),
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _ShopHero(
                shop: shop,
                onOpenPhoto: shop.photo.isEmpty
                    ? null
                    : () => _openImagePreview('Фото магазина', shop.photo),
                onOpenCard: shop.businessCardImage.isEmpty
                    ? null
                    : () =>
                          _openImagePreview('Визитка', shop.businessCardImage),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Создать товар',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Материал и размер можно выбрать из подсказок или написать своё значение.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isSubmitting ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Галерея'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _isSubmitting ? null : _takePhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Камера'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _imagePaths.isEmpty
                        ? const _EmptyProductImages()
                        : SizedBox(
                            height: 122,
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
                                        width: 122,
                                        height: 122,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton.filledTonal(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () => setState(
                                                () =>
                                                    _imagePaths.removeAt(index),
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
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Сумма',
                        hintText: 'Например: 120 000',
                      ),
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
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF08110F),
                        minimumSize: const Size.fromHeight(60),
                      ),
                      onPressed: _isSubmitting ? null : _createProduct,
                      child: Text(
                        _isSubmitting ? 'Создаём товар...' : 'Создать товар',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Товары магазина',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const _EmptyShopProducts()
              else
                ...products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ShopProductCard(
                      product: product,
                      onEdit: () => _openEditor(product),
                      onDelete: () => _deleteProduct(product),
                      onToggleFavorite: () => _toggleFavorite(product),
                      onOpenImage: (index) => _openViewer(product, index),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({
    required this.shop,
    required this.onOpenPhoto,
    required this.onOpenCard,
  });

  final Shop shop;
  final VoidCallback? onOpenPhoto;
  final VoidCallback? onOpenCard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: shop.photo.isEmpty
                ? Container(
                    height: 200,
                    color: AppColors.surfaceStrong,
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront_outlined, size: 40),
                  )
                : GestureDetector(
                    onTap: onOpenPhoto,
                    child: ProductImage(
                      source: shop.photo,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            shop.name.isEmpty ? 'Новый магазин' : shop.name,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (shop.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              shop.location,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (shop.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shop.description,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Pill(label: '${shop.productsCount} товаров'),
              const SizedBox(width: 10),
              if (shop.businessCardImage.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: onOpenCard,
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Визитка'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label),
    );
  }
}

class _EmptyProductImages extends StatelessWidget {
  const _EmptyProductImages();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Добавь фото товара, затем заполни сумму, материал и размер.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmptyShopProducts extends StatelessWidget {
  const _EmptyShopProducts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 34, color: AppColors.accent),
          SizedBox(height: 14),
          Text('В этом магазине пока нет товаров'),
        ],
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onOpenImage,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final ValueChanged<int> onOpenImage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatProductDate(product.createdAt),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onToggleFavorite,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceStrong,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.favorite),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: product.imagePaths.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => InkWell(
                onTap: () => onOpenImage(index),
                borderRadius: BorderRadius.circular(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ProductImage(
                    source: product.imagePaths[index],
                    width: 110,
                    height: 110,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniInfo(
                label: 'Сумма',
                value: product.amount.isEmpty ? 'Не указано' : product.amount,
              ),
              _MiniInfo(
                label: 'Материал',
                value: product.material.isEmpty
                    ? 'Не указано'
                    : product.material,
              ),
              _MiniInfo(
                label: 'Размер',
                value: product.size.isEmpty ? 'Не указано' : product.size,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Редактировать'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SingleImagePage extends StatelessWidget {
  const _SingleImagePage({required this.title, required this.imageSource});

  final String title;
  final String imageSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ProductImage(source: imageSource, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

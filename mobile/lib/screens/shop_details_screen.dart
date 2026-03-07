import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/product_presets.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_map_preview.dart';
import '../widgets/suggestion_field.dart';
import 'image_gallery_page.dart';
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
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  final List<String> _imagePaths = [];
  int _quantity = 1;
  bool _isSubmitting = false;

  Shop? get _shop => widget.store.shopById(widget.shopId);

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
        text: normalized.toString(),
        selection: TextSelection.collapsed(
          offset: normalized.toString().length,
        ),
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
        quantity: _quantity,
        color: _colorController.text,
        material: _materialController.text,
        size: _sizeController.text,
      );

      if (!mounted) {
        return;
      }

      _amountController.clear();
      _colorController.clear();
      _materialController.clear();
      _sizeController.clear();
      setState(() {
        _imagePaths.clear();
        _quantity = 1;
        _quantityController.text = '1';
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

  Future<void> _changeQuantity(Product product, int nextQuantity) async {
    final normalized = nextQuantity < 1 ? 1 : nextQuantity;

    try {
      await widget.store.updateProduct(product.copyWith(quantity: normalized));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: 'Не удалось обновить количество.',
        ),
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

  Future<void> _openImageGallery(
    String title,
    List<String> images, {
    int initialIndex = 0,
  }) async {
    if (images.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageGalleryPage(
          title: title,
          imageSources: images,
          initialIndex: initialIndex,
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              _ShopHero(
                shop: shop,
                onOpenPhoto: shop.photo.isEmpty
                    ? null
                    : () => _openImagePreview('Фото магазина', shop.photo),
                onOpenStorefront: shop.storefrontImages.isEmpty
                    ? null
                    : (index) => _openImageGallery(
                        'Фото витрины',
                        shop.storefrontImages,
                        initialIndex: index,
                      ),
                onOpenCard: shop.businessCardImage.isEmpty
                    ? null
                    : () =>
                          _openImagePreview('Визитка', shop.businessCardImage),
              ),
              const SizedBox(height: 18),
              Container(
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
                      'Закуп товара',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Добавь фото, цену закупа, количество и нужные поля.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    _PurchaseSummaryCard(
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
                    _QuantityStepper(
                      controller: _quantityController,
                      quantity: _quantity,
                      onChanged: _syncQuantityFromText,
                      onDecrease: _isSubmitting
                          ? null
                          : () => _setQuantity(_quantity - 1),
                      onIncrease: _isSubmitting
                          ? null
                          : () => _setQuantity(_quantity + 1),
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
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF08110F),
                        minimumSize: const Size.fromHeight(60),
                      ),
                      onPressed: _isSubmitting ? null : _createProduct,
                      child: Text(
                        _isSubmitting
                            ? 'Сохраняем закуп...'
                            : 'Сохранить закуп',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Закупы магазина',
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
                      onDecreaseQuantity: () =>
                          _changeQuantity(product, product.quantity - 1),
                      onIncreaseQuantity: () =>
                          _changeQuantity(product, product.quantity + 1),
                      onSubmitQuantity: (value) {
                        final parsed = int.tryParse(value.trim());

                        if (parsed == null) {
                          return;
                        }

                        _changeQuantity(product, parsed);
                      },
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
    required this.onOpenStorefront,
    required this.onOpenCard,
  });

  final Shop shop;
  final VoidCallback? onOpenPhoto;
  final ValueChanged<int>? onOpenStorefront;
  final VoidCallback? onOpenCard;

  Future<void> _openRoute(BuildContext context) async {
    if (!shop.hasCoordinates) {
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${shop.latitude},${shop.longitude}',
    );

    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть маршрут.')),
      );
    }
  }

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
          if (shop.storefrontImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Фото витрины',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 156,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shop.storefrontImages.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => InkWell(
                  onTap: onOpenStorefront == null
                      ? null
                      : () => onOpenStorefront!(index),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 116,
                    height: 156,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceStrong,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ProductImage(
                        source: shop.storefrontImages[index],
                        width: 100,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (shop.hasCoordinates) ...[
            const SizedBox(height: 16),
            ShopMapPreview(
              latitude: shop.latitude!,
              longitude: shop.longitude!,
              height: 180,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _openRoute(context),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Открыть маршрут'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(label: '${shop.productsCount} товаров'),
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
    required this.onDecreaseQuantity,
    required this.onIncreaseQuantity,
    required this.onSubmitQuantity,
    required this.onOpenImage,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onIncreaseQuantity;
  final ValueChanged<String> onSubmitQuantity;
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
          const SizedBox(height: 14),
          _InlineTotalCard(product: product),
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
                label: 'Цена',
                value: product.amount.isEmpty ? 'Не указано' : product.amount,
              ),
              _MiniInfo(
                label: 'Итог',
                value: product.totalValue == null
                    ? 'Не указано'
                    : formatProductMoney(product.totalValue!),
              ),
              _MiniInfo(
                label: 'Цвет',
                value: product.color.isEmpty ? 'Не указано' : product.color,
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
          _QuantityAdjuster(
            quantity: product.quantity,
            onDecrease: onDecreaseQuantity,
            onIncrease: onIncreaseQuantity,
            onSubmitted: onSubmitQuantity,
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

class _PurchaseSummaryCard extends StatelessWidget {
  const _PurchaseSummaryCard({
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
                : '${amount.trim().isEmpty ? '0' : amount.trim()} × $quantity = ${formatProductMoney(total!)}',
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.controller,
    required this.quantity,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  final TextEditingController controller;
  final int quantity;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

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

class _InlineTotalCard extends StatelessWidget {
  const _InlineTotalCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final total = product.totalValue;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Итог закупа',
            style: textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            total == null
                ? 'Цена не указана'
                : '${product.amount} × ${product.quantity} = ${formatProductMoney(total)}',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _QuantityAdjuster extends StatelessWidget {
  const _QuantityAdjuster({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSubmitted,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(
            'Количество',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          IconButton.filledTonal(
            onPressed: quantity > 1 ? onDecrease : null,
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: TextFormField(
              initialValue: '$quantity',
              onFieldSubmitted: onSubmitted,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Штук',
                hintText: '1',
                isDense: true,
              ),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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

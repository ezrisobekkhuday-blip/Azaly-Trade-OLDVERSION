import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../services/web_camera_capture.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../utils/image_source_utils.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/product_thumbnail_card.dart';
import '../widgets/shop_map_preview.dart';
import '../widgets/suggestion_field.dart';
import 'image_gallery_page.dart';
import 'photo_viewer_page.dart';
import 'product_editor_sheet.dart';

const double _pickedImageMaxDimension = 1440;
const int _pickedImageQuality = 70;

class ShopDetailsScreen extends StatefulWidget {
  const ShopDetailsScreen({
    super.key,
    required this.store,
    required this.shopId,
    this.initialStorefrontIndex,
  });

  final AppStore store;
  final String shopId;
  final int? initialStorefrontIndex;

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
  bool _isPurchaseFormExpanded = true;
  String? _pendingStorefrontImagePath;

  Shop? get _shop => widget.store.shopById(widget.shopId);

  @override
  void initState() {
    super.initState();
    _applyInitialStorefrontDraft();
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
    return calculateNetTotal(_amountController.text, _quantity);
  }

  void _applyInitialStorefrontDraft() {
    final storefrontIndex = widget.initialStorefrontIndex;
    final shop = _shop;

    if (storefrontIndex == null ||
        shop == null ||
        storefrontIndex < 0 ||
        storefrontIndex >= shop.storefrontItems.length) {
      return;
    }

    final item = shop.storefrontItems[storefrontIndex];
    _imagePaths
      ..clear()
      ..add(item.imagePath);
    _amountController.text = item.amount;
    _colorController.text = item.color;
    _materialController.text = item.material;
    _sizeController.text = item.size;
    _quantity = 1;
    _quantityController.text = '1';
    _isPurchaseFormExpanded = true;
    _pendingStorefrontImagePath = item.imagePath;
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
      final files = await _picker.pickMultiImage(
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || files.isEmpty) {
        return;
      }

      final imageSources = await Future.wait(files.map(normalizePickedImageSource));
      if (!mounted) {
        return;
      }

      setState(() {
        _imagePaths.addAll(imageSources);
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotOpenGallery'));
    }
  }

  Future<void> _takePhoto() async {
    try {
      if (kIsWeb) {
        final imageSource = await captureImageWithWebCamera(context);

        if (!mounted || imageSource == null || imageSource.isEmpty) {
          return;
        }

        setState(() {
          _imagePaths.add(imageSource);
        });
        return;
      }

      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || file == null) {
        return;
      }

      final imageSource = await normalizePickedImageSource(file);
      if (!mounted) {
        return;
      }

      setState(() {
        _imagePaths.add(imageSource);
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotOpenCamera'));
    }
  }

  Future<void> _createProduct() async {
    final shop = _shop;

    if (shop == null) {
      return;
    }

    if (_imagePaths.isEmpty) {
      _showMessage(AppStrings.of(context).t('addProductPhotoFirst'));
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

      final storefrontImagePath = _pendingStorefrontImagePath;
      if (storefrontImagePath != null) {
        final storefrontIndex = _shop?.storefrontItems.indexWhere(
          (item) => item.imagePath == storefrontImagePath,
        );

        if (storefrontIndex != null && storefrontIndex >= 0) {
          try {
            await widget.store.removeStorefrontItem(shop.id, storefrontIndex);
          } catch (_) {
            if (mounted) {
              _showMessage(AppStrings.of(context).t('cannotUpdateShop'));
            }
          }
        }
      }

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
        _isPurchaseFormExpanded = false;
        _pendingStorefrontImagePath = null;
      });
      _showMessage(AppStrings.of(context).t('productCreated'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: AppStrings.of(context).t('cannotCreateProduct'),
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
        _showMessage(AppStrings.of(context).t('productUpdated'));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: AppStrings.of(context).t('cannotUpdateProduct'),
        ),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('deleteProductTitle')),
        content: Text(strings.t('deleteProductMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.t('delete')),
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
        _showMessage(strings.t('productDeleted'));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(error, fallbackMessage: strings.t('cannotDeleteProduct')),
      );
    }
  }

  Future<void> _toggleStorefrontFavorite(int storefrontIndex) async {
    final shop = _shop;

    if (shop == null ||
        storefrontIndex < 0 ||
        storefrontIndex >= shop.storefrontItems.length) {
      return;
    }

    final item = shop.storefrontItems[storefrontIndex];

    try {
      await widget.store.toggleStorefrontFavorite(shop.id, storefrontIndex);
      if (mounted) {
        final strings = AppStrings.of(context);
        _showMessage(
          item.isFavorite
              ? strings.t('favoriteRemoved')
              : strings.t('favoriteMarked'),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: AppStrings.of(context).t('cannotUpdateFavorite'),
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

  void _togglePurchaseForm() {
    setState(() {
      _isPurchaseFormExpanded = !_isPurchaseFormExpanded;
    });
  }

  Widget _buildPurchaseComposer(
    BuildContext context,
    AppStrings strings,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
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
                      strings.t('purchaseTitle'),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.t('purchaseDescription'),
                      maxLines: _isPurchaseFormExpanded ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _togglePurchaseForm,
                tooltip: _isPurchaseFormExpanded
                    ? strings.t('collapse')
                    : strings.t('expand'),
                icon: Icon(
                  _isPurchaseFormExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                strings.t('purchaseCollapsedHint'),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isSubmitting ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(strings.t('gallery')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isSubmitting ? null : _takePhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(strings.t('camera')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _imagePaths.isEmpty
                    ? const _EmptyProductImages()
                    : SizedBox(
                        height: 148,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imagePaths.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final path = _imagePaths[index];

                            return ProductThumbnailCard(
                              source: path,
                              onRemove: _isSubmitting
                                  ? null
                                  : () => setState(
                                      () => _imagePaths.removeAt(index),
                                    ),
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
                  decoration: InputDecoration(
                    labelText: strings.t('purchasePriceLabel'),
                    hintText: strings.t('purchasePriceHint'),
                  ),
                ),
                const SizedBox(height: 14),
                _QuantityStepper(
                  controller: _quantityController,
                  quantity: _quantity,
                  onChanged: _syncQuantityFromText,
                ),
                const SizedBox(height: 14),
                SuggestionField(
                  controller: _colorController,
                  label: strings.t('colorLabel'),
                  hint: strings.t('colorHint'),
                  suggestions: localizedColorSuggestions(strings.language),
                  quickGroups: [
                    SuggestionGroup(
                      label: strings.t('popularColors'),
                      items: localizedPopularColorSuggestions(strings.language),
                    ),
                  ],
                  allowMultiSelect: true,
                ),
                const SizedBox(height: 14),
                SuggestionField(
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
                const SizedBox(height: 14),
                SuggestionField(
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
                      items: localizedSpecialSizeSuggestions(strings.language),
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
                        ? strings.t('savingPurchase')
                        : strings.t('savePurchase'),
                  ),
                ),
              ],
            ),
            crossFadeState: _isPurchaseFormExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final shop = _shop;
        final strings = AppStrings.of(context);

        if (shop == null) {
          return Scaffold(
            appBar: AppBar(title: Text(strings.t('shopsHeroTitle'))),
            body: AppBackground(
              child: Center(child: Text(strings.t('shopNotFound'))),
            ),
          );
        }

        final products = widget.store.productsForShop(shop.id);
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(shop.name.isEmpty ? strings.t('newShop') : shop.name),
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
                        : () => _openImagePreview(
                            strings.t('shopPhoto'),
                            shop.photo,
                          ),
                    onOpenStorefront: shop.storefrontItems.isEmpty
                        ? null
                        : (index) => _openImageGallery(
                            strings.t('storefrontPhotos'),
                            shop.storefrontImages,
                            initialIndex: index,
                          ),
                    onOpenCard: shop.businessCardImage.isEmpty
                        ? null
                        : () => _openImagePreview(
                            strings.t('businessCardShort'),
                            shop.businessCardImage,
                          ),
                    onToggleStorefrontFavorite: (index) =>
                        _toggleStorefrontFavorite(index),
                  ),
                  const SizedBox(height: 18),
                  _buildPurchaseComposer(context, strings, textTheme),
                  const SizedBox(height: 18),
                  Text(
                    strings.t('shopPurchases'),
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
                          onOpenImage: (index) => _openViewer(product, index),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({
    required this.shop,
    required this.onOpenPhoto,
    required this.onOpenStorefront,
    required this.onOpenCard,
    required this.onToggleStorefrontFavorite,
  });

  final Shop shop;
  final VoidCallback? onOpenPhoto;
  final ValueChanged<int>? onOpenStorefront;
  final VoidCallback? onOpenCard;
  final ValueChanged<int>? onToggleStorefrontFavorite;

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
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('cannotOpenRoute'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

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
            shop.name.isEmpty ? strings.t('newShop') : shop.name,
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
          if (shop.storefrontItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              strings.t('storefrontPhotos'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shop.storefrontItems.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = shop.storefrontItems[index];
                  final language = strings.language;
                  final isFavorite = item.isFavorite;

                  return InkWell(
                    onTap: onOpenStorefront == null
                        ? null
                        : () => onOpenStorefront!(index),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 156,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFavorite
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isFavorite
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ProductImage(
                                  source: item.imagePath,
                                  width: 140,
                                  height: 104,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton.filledTonal(
                                  onPressed: onToggleStorefrontFavorite == null
                                      ? null
                                      : () =>
                                            onToggleStorefrontFavorite!(index),
                                  style: IconButton.styleFrom(
                                    backgroundColor: isFavorite
                                        ? AppColors.primary.withValues(
                                            alpha: 0.22,
                                          )
                                        : AppColors.surfaceStrong.withValues(
                                            alpha: 0.92,
                                          ),
                                    foregroundColor: isFavorite
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _StorefrontMetaLine(
                            label: strings.t('priceLabel'),
                            value: item.amount.isEmpty
                                ? strings.t('notSpecified')
                                : item.amount,
                          ),
                          const SizedBox(height: 4),
                          _StorefrontMetaLine(
                            label: strings.t('colorLabel'),
                            value: item.color.isEmpty
                                ? strings.t('notSpecified')
                                : localizeColorValue(language, item.color),
                          ),
                          const SizedBox(height: 4),
                          _StorefrontMetaLine(
                            label: strings.t('materialLabel'),
                            value: item.material.isEmpty
                                ? strings.t('notSpecified')
                                : localizeMaterialValue(
                                    language,
                                    item.material,
                                  ),
                          ),
                          const SizedBox(height: 4),
                          _StorefrontMetaLine(
                            label: strings.t('sizeLabel'),
                            value: item.size.isEmpty
                                ? strings.t('notSpecified')
                                : localizeSizeValue(language, item.size),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                label: Text(strings.t('openRoute')),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(label: strings.formatShopItemCount(shop.productsCount)),
              if (shop.businessCardImage.isNotEmpty)
                FilledButton.tonalIcon(
                  onPressed: onOpenCard,
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(strings.t('businessCardShort')),
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
    final strings = AppStrings.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(strings.t('emptyProductImages'), textAlign: TextAlign.center),
    );
  }
}

class _EmptyShopProducts extends StatelessWidget {
  const _EmptyShopProducts();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: AppColors.accent,
          ),
          const SizedBox(height: 14),
          Text(strings.t('emptyShopProducts')),
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
    required this.onOpenImage,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onOpenImage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final language = strings.language;

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
          Text(
            formatProductDate(product.createdAt),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          _InlineTotalCard(product: product),
          const SizedBox(height: 16),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: product.imagePaths.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ProductThumbnailCard(
                source: product.imagePaths[index],
                onTap: () => onOpenImage(index),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniInfo(
                label: strings.t('priceLabel'),
                value: product.amount.isEmpty
                    ? strings.t('notSpecified')
                    : product.amount,
              ),
              _MiniInfo(
                label: strings.t('totalLabel'),
                value: product.totalValue == null
                    ? strings.t('notSpecified')
                    : formatProductMoney(product.totalValue!),
              ),
              _MiniInfo(
                label: strings.t('piecesLabel'),
                value: '${product.quantity}',
              ),
              _MiniInfo(
                label: strings.t('colorLabel'),
                value: product.color.isEmpty
                    ? strings.t('notSpecified')
                    : localizeColorValue(language, product.color),
              ),
              _MiniInfo(
                label: strings.t('materialLabel'),
                value: product.material.isEmpty
                    ? strings.t('notSpecified')
                    : localizeMaterialValue(language, product.material),
              ),
              _MiniInfo(
                label: strings.t('sizeLabel'),
                value: product.size.isEmpty
                    ? strings.t('notSpecified')
                    : localizeSizeValue(language, product.size),
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
                  label: Text(strings.t('edit')),
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
                  label: Text(strings.t('delete')),
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
                : '${amount.trim().isEmpty ? '0' : amount.trim()} × $quantity = ${formatProductMoney(grossTotal!)}',
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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

class _InlineTotalCard extends StatelessWidget {
  const _InlineTotalCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final total = product.totalValue;
    final grossTotal = product.grossTotalValue;
    final supplierShare = product.supplierShareValue;
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

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
            strings.t('purchaseTotalTitle'),
            style: textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            total == null
                ? strings.t('priceNotSpecified')
                : '${product.amount} × ${product.quantity} = ${formatProductMoney(grossTotal!)}',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
              '${strings.t('totalLabel')}: ${formatProductMoney(total)}',
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

class _StorefrontMetaLine extends StatelessWidget {
  const _StorefrontMetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
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

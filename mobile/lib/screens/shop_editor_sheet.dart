import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../localization/app_strings.dart';
import '../models/map_selection_result.dart';
import '../models/shop.dart';
import '../services/web_camera_capture.dart';
import '../theme/app_theme.dart';
import '../utils/image_source_utils.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_map_preview.dart';
import '../widgets/storefront_item_widgets.dart';
import 'location_picker_page.dart';

const double _pickedImageMaxDimension = 1440;
const int _pickedImageQuality = 70;

class ShopEditorSheet extends StatefulWidget {
  const ShopEditorSheet({super.key, required this.shop});

  final Shop shop;

  @override
  State<ShopEditorSheet> createState() => _ShopEditorSheetState();
}

class _ShopEditorSheetState extends State<ShopEditorSheet> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final List<StorefrontItem> _storefrontItems;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _locationController = TextEditingController(text: widget.shop.location);
    _descriptionController = TextEditingController(
      text: widget.shop.description,
    );
    _storefrontItems = List<StorefrontItem>.from(widget.shop.storefrontItems);
    _latitude = widget.shop.latitude;
    _longitude = widget.shop.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.of(context).push<MapSelectionResult>(
      MaterialPageRoute<MapSelectionResult>(
        builder: (_) => LocationPickerPage(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _locationController.value = TextEditingValue(
        text: result.label,
        selection: TextSelection.collapsed(offset: result.label.length),
      );
    });
  }

  Future<void> _pickStorefrontFromGallery() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || pickedFiles.isEmpty) {
        return;
      }

      final imageSources = await Future.wait(
        pickedFiles.map(normalizePickedImageSource),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _storefrontItems.addAll(
          imageSources.map((source) => StorefrontItem(imagePath: source)),
        );
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).t('cannotLoadStorefront'))),
        );
      }
    }
  }

  Future<void> _pickStorefrontFromCamera() async {
    try {
      if (kIsWeb) {
        final imageSource = await captureImageWithWebCamera(context);

        if (!mounted || imageSource == null || imageSource.isEmpty) {
          return;
        }

        setState(() {
          _storefrontItems.add(StorefrontItem(imagePath: imageSource));
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
        _storefrontItems.add(StorefrontItem(imagePath: imageSource));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).t('cannotOpenStorefrontCamera')),
          ),
        );
      }
    }
  }

  Future<void> _editStorefrontItem(int index) async {
    final updatedItem = await showModalBottomSheet<StorefrontItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StorefrontItemEditorSheet(item: _storefrontItems[index]),
    );

    if (updatedItem == null || !mounted) {
      return;
    }

    setState(() {
      _storefrontItems[index] = updatedItem;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      widget.shop.copyWith(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        description: _descriptionController.text.trim(),
        storefrontItems: _storefrontItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textTheme = Theme.of(context).textTheme;
    final hasCoordinates = _latitude != null && _longitude != null;
    final strings = AppStrings.of(context);

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
                            strings.t('editShopTitle'),
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.t('editShopDescription'),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.shop.photo.isEmpty
                      ? Container(
                          height: 150,
                          color: AppColors.surfaceStrong,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 34,
                          ),
                        )
                      : ProductImage(
                          source: widget.shop.photo,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: strings.t('shopNameLabel'),
                    hintText: strings.t('shopNameHint'),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: strings.t('shopLocationLabel'),
                    hintText: strings.t('locationHintShort'),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: strings.t('extraDescriptionLabel'),
                    hintText: strings.t('shortShopDescriptionHint'),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
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
                        strings.t('storefrontPhotos'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _pickStorefrontFromGallery,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(strings.t('gallery')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _pickStorefrontFromCamera,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(strings.t('camera')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_storefrontItems.isEmpty)
                        Text(
                          strings.t('storefrontHelper'),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List<Widget>.generate(
                            _storefrontItems.length,
                            (index) => StorefrontItemSummaryCard(
                              item: _storefrontItems[index],
                              onEdit: () => _editStorefrontItem(index),
                              onRemove: () {
                                setState(() {
                                  _storefrontItems.removeAt(index);
                                });
                              },
                            ),
                            growable: false,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
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
                        strings.t('pointOnMap'),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (hasCoordinates)
                        ShopMapPreview(
                          latitude: _latitude!,
                          longitude: _longitude!,
                          height: 160,
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 22,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.t('pointNotSelected'),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _pickLocationOnMap,
                          icon: const Icon(Icons.map_outlined),
                          label: Text(
                            hasCoordinates
                                ? strings.t('changePoint')
                                : strings.t('pickOnMap'),
                          ),
                        ),
                      ),
                    ],
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
                    child: Text(strings.t('save')),
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

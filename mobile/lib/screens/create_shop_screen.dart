import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/map_selection_result.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/product_thumbnail_card.dart';
import '../widgets/shop_map_preview.dart';
import '../widgets/suggestion_field.dart';
import 'location_picker_page.dart';

const double _pickedImageMaxDimension = 1440;
const int _pickedImageQuality = 70;

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({
    super.key,
    required this.store,
    required this.onOpenShops,
  });

  final AppStore store;
  final VoidCallback onOpenShops;

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _shopPhotoPath = '';
  final List<StorefrontItem> _storefrontItems = [];
  String _businessCardPath = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isResolvingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickShopPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _shopPhotoPath = file.path;
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotLoadShopPhoto'));
    }
  }

  Future<void> _pickBusinessCard(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: _pickedImageQuality,
        maxWidth: _pickedImageMaxDimension,
        maxHeight: _pickedImageMaxDimension,
      );

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _businessCardPath = file.path;
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotLoadBusinessCard'));
    }
  }

  Future<void> _pickStorefrontFromGallery() async {
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
        _storefrontItems.addAll(
          files.map((file) => StorefrontItem(imagePath: file.path)),
        );
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotLoadStorefront'));
    }
  }

  Future<void> _pickStorefrontFromCamera() async {
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
        _storefrontItems.add(StorefrontItem(imagePath: file.path));
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotOpenStorefrontCamera'));
    }
  }

  Future<void> _editStorefrontItem(int index) async {
    final updatedItem = await showModalBottomSheet<StorefrontItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StorefrontItemEditorSheet(item: _storefrontItems[index]),
    );

    if (updatedItem == null || !mounted) {
      return;
    }

    setState(() {
      _storefrontItems[index] = updatedItem;
    });
  }

  Future<void> _createShop() async {
    if (_shopPhotoPath.isEmpty) {
      _showMessage(AppStrings.of(context).t('addShopPhotoFirst'));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.store.createShop(
        name: _nameController.text,
        photoPath: _shopPhotoPath,
        storefrontItems: _storefrontItems,
        location: _locationController.text,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        description: _descriptionController.text,
        businessCardPath: _businessCardPath,
      );

      if (!mounted) {
        return;
      }

      _nameController.clear();
      _locationController.clear();
      _descriptionController.clear();

      setState(() {
        _shopPhotoPath = '';
        _storefrontItems.clear();
        _businessCardPath = '';
        _selectedLatitude = null;
        _selectedLongitude = null;
      });

      widget.onOpenShops();
      _showMessage(AppStrings.of(context).t('shopCreated'));
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: AppStrings.of(context).t('cannotSaveShop'),
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

  void _applyLocationText(String value) {
    _locationController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _applyMapSelection({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    _selectedLatitude = latitude;
    _selectedLongitude = longitude;
    _applyLocationText(label);
  }

  String _buildCoordinateLabel(Position position) {
    return '${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)}';
  }

  String? _buildPlacemarkLabel(Placemark? place) {
    final locationParts = <String>{
      if (place?.street?.trim().isNotEmpty ?? false) place!.street!.trim(),
      if (place?.subLocality?.trim().isNotEmpty ?? false)
        place!.subLocality!.trim(),
      if (place?.locality?.trim().isNotEmpty ?? false) place!.locality!.trim(),
      if (place?.administrativeArea?.trim().isNotEmpty ?? false)
        place!.administrativeArea!.trim(),
      if (place?.country?.trim().isNotEmpty ?? false) place!.country!.trim(),
    }.toList();

    if (locationParts.isEmpty) {
      return null;
    }

    return locationParts.join(', ');
  }

  Future<void> _fillCurrentLocation() async {
    final strings = AppStrings.of(context);

    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage(strings.t('turnOnLocation'));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(strings.t('allowLocationAccess'));
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } on TimeoutException {
        position ??= await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _showMessage(strings.t('cannotGetQuickLocation'));
        return;
      }

      final coordinateLabel = _buildCoordinateLabel(position);
      _applyMapSelection(
        latitude: position.latitude,
        longitude: position.longitude,
        label: coordinateLabel,
      );

      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 3));
        final resolvedLocation = _buildPlacemarkLabel(
          placemarks.isNotEmpty ? placemarks.first : null,
        );

        if (!mounted || resolvedLocation == null) {
          return;
        }

        _applyMapSelection(
          latitude: position.latitude,
          longitude: position.longitude,
          label: resolvedLocation,
        );
      } catch (_) {
        // Leave coordinates in the field if reverse geocoding is slow.
      }
    } catch (_) {
      _showMessage(strings.t('cannotDetermineLocation'));
    } finally {
      if (mounted && _isResolvingLocation) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.of(context).push<MapSelectionResult>(
      MaterialPageRoute<MapSelectionResult>(
        builder: (_) => LocationPickerPage(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _applyMapSelection(
        latitude: result.latitude,
        longitude: result.longitude,
        label: result.label,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _HeroCard(
              totalShops: widget.store.shops.length,
              hasPhoto: _shopPhotoPath.isNotEmpty,
            ),
            const SizedBox(height: 18),
            _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('createShopTitle'),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.t('createShopDescription'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ImagePickerCard(
                    title: strings.t('shopPhoto'),
                    imagePath: _shopPhotoPath,
                    onGallery: _isSubmitting
                        ? null
                        : () => _pickShopPhoto(ImageSource.gallery),
                    onCamera: _isSubmitting
                        ? null
                        : () => _pickShopPhoto(ImageSource.camera),
                    onClear: _shopPhotoPath.isEmpty || _isSubmitting
                        ? null
                        : () => setState(() => _shopPhotoPath = ''),
                  ),
                  const SizedBox(height: 14),
                  _StorefrontItemsCard(
                    title: strings.t('storefrontPhotos'),
                    helperText: strings.t('storefrontHelper'),
                    items: _storefrontItems,
                    onGallery: _isSubmitting
                        ? null
                        : _pickStorefrontFromGallery,
                    onCamera: _isSubmitting ? null : _pickStorefrontFromCamera,
                    onClearAll: _storefrontItems.isEmpty || _isSubmitting
                        ? null
                        : () => setState(_storefrontItems.clear),
                    onEditAt: _isSubmitting ? null : _editStorefrontItem,
                    onRemoveAt: _isSubmitting
                        ? null
                        : (index) =>
                              setState(() => _storefrontItems.removeAt(index)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: strings.t('shopNameLabel'),
                      hintText: strings.t('shopNameOptionalHint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: strings.t('shopLocationLabel'),
                      hintText: strings.t('shopLocationHint'),
                      suffixIcon: _isResolvingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _fillCurrentLocation,
                              tooltip: strings.t('detectLocation'),
                              icon: const Icon(Icons.my_location_outlined),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ShopLocationCard(
                    latitude: _selectedLatitude,
                    longitude: _selectedLongitude,
                    onPickOnMap: _pickLocationOnMap,
                    onUseCurrentLocation: _isSubmitting
                        ? null
                        : _fillCurrentLocation,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: strings.t('extraDescriptionLabel'),
                      hintText: strings.t('extraDescriptionHint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ImagePickerCard(
                    title: strings.t('businessCardTitle'),
                    imagePath: _businessCardPath,
                    onGallery: _isSubmitting
                        ? null
                        : () => _pickBusinessCard(ImageSource.gallery),
                    onCamera: _isSubmitting
                        ? null
                        : () => _pickBusinessCard(ImageSource.camera),
                    onClear: _businessCardPath.isEmpty || _isSubmitting
                        ? null
                        : () => setState(() => _businessCardPath = ''),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF04120F),
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: _isSubmitting ? null : _createShop,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isSubmitting
                                ? strings.t('savingShop')
                                : strings.t('saveShop'),
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF04120F),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF04120F),
                                ),
                              )
                            : const Icon(Icons.storefront_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopLocationCard extends StatelessWidget {
  const _ShopLocationCard({
    required this.latitude,
    required this.longitude,
    required this.onPickOnMap,
    required this.onUseCurrentLocation,
  });

  final double? latitude;
  final double? longitude;
  final VoidCallback onPickOnMap;
  final VoidCallback? onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final hasPoint = latitude != null && longitude != null;

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
            strings.t('shopMapTitle'),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (hasPoint) ...[
            ShopMapPreview(
              latitude: latitude!,
              longitude: longitude!,
              height: 170,
            ),
            const SizedBox(height: 10),
            Text(
              '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
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
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.t('mapPickPointTitle'),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.t('mapPickPointDescription'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onPickOnMap,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    hasPoint
                        ? strings.t('changePoint')
                        : strings.t('pickOnMap'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onUseCurrentLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(strings.t('myPoint')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.totalShops, required this.hasPhoto});

  final int totalShops;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          colors: [Color(0x2E7C92FF), Color(0x1461E5BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strings.t('heroShopBadge'),
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            strings.t('newShop'),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.t('heroNewShopDescription'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: hasPhoto ? strings.t('yes') : strings.t('no'),
                  label: strings.t('photoReady'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: totalShops.toString(),
                  label: strings.t('totalShops'),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x73060A14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _StorefrontItemsCard extends StatelessWidget {
  const _StorefrontItemsCard({
    required this.title,
    required this.helperText,
    required this.items,
    required this.onGallery,
    required this.onCamera,
    required this.onEditAt,
    required this.onRemoveAt,
    this.onClearAll,
  });

  final String title;
  final String helperText;
  final List<StorefrontItem> items;
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;
  final ValueChanged<int>? onEditAt;
  final ValueChanged<int>? onRemoveAt;
  final VoidCallback? onClearAll;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                IconButton.filledTonal(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(strings.t('gallery')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(strings.t('camera')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              helperText,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            SizedBox(
              height: 238,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _StorefrontItemSummaryCard(
                  item: items[index],
                  onEdit: onEditAt == null ? null : () => onEditAt!(index),
                  onRemove: onRemoveAt == null
                      ? null
                      : () => onRemoveAt!(index),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StorefrontItemSummaryCard extends StatelessWidget {
  const _StorefrontItemSummaryCard({
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

class _StorefrontItemEditorSheet extends StatefulWidget {
  const _StorefrontItemEditorSheet({required this.item});

  final StorefrontItem item;

  @override
  State<_StorefrontItemEditorSheet> createState() =>
      _StorefrontItemEditorSheetState();
}

class _StorefrontItemEditorSheetState
    extends State<_StorefrontItemEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _colorController;
  late final TextEditingController _materialController;
  late final TextEditingController _sizeController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.item.amount);
    _colorController = TextEditingController(text: widget.item.color);
    _materialController = TextEditingController(text: widget.item.material);
    _sizeController = TextEditingController(text: widget.item.size);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      widget.item.copyWith(
        amount: _amountController.text.trim(),
        color: _colorController.text.trim(),
        material: _materialController.text.trim(),
        size: _sizeController.text.trim(),
      ),
    );
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
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: strings.t('purchasePriceLabel'),
                    hintText: strings.t('purchasePriceHint'),
                  ),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF04120F),
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

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.title,
    this.imagePath = '',
    required this.onGallery,
    required this.onCamera,
    this.onClear,
  });

  final String title;
  final String imagePath;
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final hasImage = imagePath.isNotEmpty;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasImage)
                IconButton.filledTonal(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(strings.t('gallery')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(strings.t('camera')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasImage)
            Text(
              strings.t('chooseOrTakePhoto'),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ProductImage(
                source: imagePath,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

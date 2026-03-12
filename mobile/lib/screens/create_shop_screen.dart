// ignore_for_file: unused_element, unused_element_parameter

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_strings.dart';
import '../models/map_selection_result.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../services/web_camera_capture.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../utils/image_source_utils.dart';
import '../utils/wechat_utils.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_map_preview.dart';
import '../widgets/storefront_item_widgets.dart';
import 'location_picker_page.dart';
import 'wechat_scanner_sheet.dart';

const double _pickedImageMaxDimension = 1440;
const int _pickedImageQuality = 70;
const Duration _webLocationDelay = Duration(milliseconds: 700);
const Duration _primaryLocationTimeout = Duration(seconds: 18);
const Duration _fallbackLocationTimeout = Duration(seconds: 10);

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
  final TextEditingController _sellerWechatController = TextEditingController();

  String _shopPhotoPath = '';
  final List<StorefrontItem> _storefrontItems = [];
  String _businessCardPath = '';
  String _sellerWechatLink = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _isResolvingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _sellerWechatController.dispose();
    super.dispose();
  }

  Future<void> _pickShopPhoto(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.camera) {
        final imageSource = await captureImageWithWebCamera(context);

        if (!mounted || imageSource == null || imageSource.isEmpty) {
          return;
        }

        setState(() {
          _shopPhotoPath = imageSource;
        });
        return;
      }

      final file = await _picker.pickImage(
        source: source,
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
        _shopPhotoPath = imageSource;
      });
    } catch (_) {
      _showMessage(AppStrings.of(context).t('cannotLoadShopPhoto'));
    }
  }

  Future<void> _pickBusinessCard(ImageSource source) async {
    try {
      if (kIsWeb && source == ImageSource.camera) {
        final imageSource = await captureImageWithWebCamera(context);

        if (!mounted || imageSource == null || imageSource.isEmpty) {
          return;
        }

        setState(() {
          _businessCardPath = imageSource;
        });
        return;
      }

      final file = await _picker.pickImage(
        source: source,
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
        _businessCardPath = imageSource;
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

      final imageSources = await Future.wait(
        files.map(normalizePickedImageSource),
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
      _showMessage(AppStrings.of(context).t('cannotLoadStorefront'));
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
      _showMessage(AppStrings.of(context).t('cannotOpenStorefrontCamera'));
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

  Future<void> _scanWechatSeller() async {
    final scannedValue = await openWechatScannerSheet(context);

    if (!mounted || scannedValue == null || scannedValue.trim().isEmpty) {
      return;
    }

    final normalizedValue = normalizeWechatValue(scannedValue);
    setState(() {
      _sellerWechatController.value = TextEditingValue(
        text: normalizedValue,
        selection: TextSelection.collapsed(offset: normalizedValue.length),
      );
      _sellerWechatLink = deriveWechatLink(normalizedValue);
    });
  }

  Future<void> _openWechatSeller() async {
    final strings = AppStrings.of(context);
    final launchTarget = _sellerWechatLink.trim();

    if (launchTarget.isNotEmpty) {
      final uri = Uri.tryParse(launchTarget);
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    }

    final rawValue = _sellerWechatController.text.trim();
    if (rawValue.isEmpty) {
      _showMessage(strings.t('sellerWechatEmpty'));
      return;
    }

    await Clipboard.setData(ClipboardData(text: rawValue));
    if (!mounted) {
      return;
    }

    _showMessage(strings.t('wechatCopied'));
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
        sellerWechat: _sellerWechatController.text,
        sellerWechatLink: _sellerWechatLink,
      );

      if (!mounted) {
        return;
      }

      _nameController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _sellerWechatController.clear();

      setState(() {
        _shopPhotoPath = '';
        _storefrontItems.clear();
        _businessCardPath = '';
        _sellerWechatLink = '';
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

  Future<Position?> _resolveCurrentPosition() async {
    Position? position = await Geolocator.getLastKnownPosition();

    final primarySettings = kIsWeb
        ? WebSettings(
            accuracy: LocationAccuracy.best,
            maximumAge: const Duration(minutes: 3),
            timeLimit: _primaryLocationTimeout,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: _primaryLocationTimeout,
          );

    final fallbackSettings = kIsWeb
        ? WebSettings(
            accuracy: LocationAccuracy.medium,
            maximumAge: const Duration(minutes: 10),
            timeLimit: _fallbackLocationTimeout,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: _fallbackLocationTimeout,
          );

    for (final settings in [primarySettings, fallbackSettings]) {
      try {
        return await Geolocator.getCurrentPosition(locationSettings: settings);
      } catch (_) {
        try {
          return await Geolocator.getPositionStream(locationSettings: settings)
              .first
              .timeout(
                settings.timeLimit ?? _fallbackLocationTimeout,
              );
        } catch (_) {
          // Try next strategy.
        }
      }
    }

    return position ?? await Geolocator.getLastKnownPosition();
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
      var permissionRequested = false;
      if (permission == LocationPermission.denied) {
        permissionRequested = true;
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(strings.t('allowLocationAccess'));
        return;
      }

      if (kIsWeb && permissionRequested) {
        await Future<void>.delayed(_webLocationDelay);
      }

      final position = await _resolveCurrentPosition();

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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
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
              Text(
                strings.t('createShopTitle'),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.t('createShopDescription'),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('shopPhoto'),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickShopPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(strings.t('gallery')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickShopPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(strings.t('camera')),
                    ),
                  ),
                ],
              ),
              if (_shopPhotoPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: ProductImage(
                    source: _shopPhotoPath,
                    width: double.infinity,
                    height: 210,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
                  suffixIcon: IconButton(
                    onPressed: _isSubmitting || _isResolvingLocation
                        ? null
                        : _fillCurrentLocation,
                    icon: _isResolvingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ShopLocationCard(
                latitude: _selectedLatitude,
                longitude: _selectedLongitude,
                onPickOnMap: _pickLocationOnMap,
                onUseCurrentLocation:
                    _isSubmitting || _isResolvingLocation
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
              _WechatSellerCard(
                controller: _sellerWechatController,
                onChanged: (value) {
                  setState(() {
                    _sellerWechatLink = deriveWechatLink(value);
                  });
                },
                onScan: _isSubmitting ? null : _scanWechatSeller,
                onOpen: (_sellerWechatController.text.trim().isEmpty &&
                        _sellerWechatLink.trim().isEmpty)
                    ? null
                    : _openWechatSeller,
              ),
              const SizedBox(height: 14),
              Text(
                strings.t('storefrontPhotos'),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : _pickStorefrontFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(strings.t('gallery')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : _pickStorefrontFromCamera,
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
                      onEdit: _isSubmitting
                          ? null
                          : () => _editStorefrontItem(index),
                      onRemove: _isSubmitting
                          ? null
                          : () =>
                                setState(() => _storefrontItems.removeAt(index)),
                    ),
                    growable: false,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                strings.t('businessCardTitle'),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickBusinessCard(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(strings.t('gallery')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickBusinessCard(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(strings.t('camera')),
                    ),
                  ),
                ],
              ),
              if (_businessCardPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: ProductImage(
                    source: _businessCardPath,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF04120F),
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: _isSubmitting ? null : _createShop,
                child: Text(
                  _isSubmitting ? strings.t('savingShop') : strings.t('saveShop'),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return AppBackground(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: content,
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

class _WechatSellerCard extends StatelessWidget {
  const _WechatSellerCard({
    required this.controller,
    required this.onChanged,
    required this.onScan,
    required this.onOpen,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScan;
  final VoidCallback? onOpen;

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
            strings.t('sellerWechatLabel'),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: strings.t('sellerWechatLabel'),
              hintText: strings.t('sellerWechatHint'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(strings.t('scanWechat')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(strings.t('openWechat')),
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
          else if (kIsWeb)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List<Widget>.generate(
                items.length,
                (index) => StorefrontItemSummaryCard(
                  item: items[index],
                  onEdit: onEditAt == null ? null : () => onEditAt!(index),
                  onRemove: onRemoveAt == null
                      ? null
                      : () => onRemoveAt!(index),
                ),
                growable: false,
              ),
            )
          else
            SizedBox(
              height: 238,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => StorefrontItemSummaryCard(
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

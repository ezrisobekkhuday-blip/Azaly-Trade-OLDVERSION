import 'package:flutter/material.dart';

import '../models/map_selection_result.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/shop_map_preview.dart';
import 'location_picker_page.dart';

class ShopEditorSheet extends StatefulWidget {
  const ShopEditorSheet({super.key, required this.shop});

  final Shop shop;

  @override
  State<ShopEditorSheet> createState() => _ShopEditorSheetState();
}

class _ShopEditorSheetState extends State<ShopEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
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

  void _save() {
    Navigator.of(context).pop(
      widget.shop.copyWith(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textTheme = Theme.of(context).textTheme;
    final hasCoordinates = _latitude != null && _longitude != null;

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
                            'Редактировать магазин',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Измени название, локацию или описание.',
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
                  decoration: const InputDecoration(
                    labelText: 'Название магазина',
                    hintText: 'Например: Azaly',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Локация магазина',
                    hintText: 'Адрес или район',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Доп. описание',
                    hintText: 'Коротко про магазин',
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
                        'Точка на карте',
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
                                'Точка пока не выбрана',
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
                                ? 'Изменить точку'
                                : 'Выбрать на карте',
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

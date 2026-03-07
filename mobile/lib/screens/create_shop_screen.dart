import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';

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
  String _businessCardPath = '';
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
      final file = await _picker.pickImage(source: source, imageQuality: 85);

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _shopPhotoPath = file.path;
      });
    } catch (_) {
      _showMessage('Не удалось загрузить фото магазина.');
    }
  }

  Future<void> _pickBusinessCard(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _businessCardPath = file.path;
      });
    } catch (_) {
      _showMessage('Не удалось загрузить визитку.');
    }
  }

  Future<void> _createShop() async {
    if (_shopPhotoPath.isEmpty) {
      _showMessage('Добавьте фото магазина.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.store.createShop(
        name: _nameController.text,
        photoPath: _shopPhotoPath,
        location: _locationController.text,
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
        _businessCardPath = '';
      });

      widget.onOpenShops();
      _showMessage('Магазин создан.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        describeError(
          error,
          fallbackMessage: 'Не удалось сохранить магазин на сервере.',
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
              totalShops: widget.store.shops.length,
              hasPhoto: _shopPhotoPath.isNotEmpty,
            ),
            const SizedBox(height: 18),
            _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Создать магазин',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Сначала создаётся магазин, а уже внутри него добавляются товары.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ImagePickerCard(
                    title: 'Фото магазина',
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
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название магазина',
                      hintText: 'Можно оставить пустым',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Локация магазина',
                      hintText: 'Необязательно',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Доп. описание',
                      hintText:
                          'Например: женская одежда, вечерние модели, доставка',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ImagePickerCard(
                    title: 'Визитка магазина',
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
                      minimumSize: const Size.fromHeight(62),
                    ),
                    onPressed: _isSubmitting ? null : _createShop,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSubmitting
                                    ? 'Сохраняем магазин...'
                                    : 'Создать магазин',
                                style: textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF04120F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Достаточно фото. Остальные поля можно заполнить позже.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xAA04120F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.totalShops, required this.hasPhoto});

  final int totalShops;
  final bool hasPhoto;

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
              'STORE FLOW',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Сначала магазин',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Сохрани магазин с фото, локацией и визиткой. Потом открой его и добавляй товары уже внутрь.',
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
                  value: hasPhoto ? 'Да' : 'Нет',
                  label: 'Фото готово',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: totalShops.toString(),
                  label: 'Всего магазинов',
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

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.title,
    required this.imagePath,
    required this.onGallery,
    required this.onCamera,
    required this.onClear,
  });

  final String title;
  final String imagePath;
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(28),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (imagePath.isNotEmpty)
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
                  label: const Text('Галерея'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Камера'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (imagePath.isEmpty)
            Text(
              'Можно выбрать из галереи или сфотографировать.',
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

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/section_cards.dart';
import 'photo_viewer_page.dart';
import 'product_editor_sheet.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key, required this.store});

  final AppStore store;

  Future<void> _openEditor(BuildContext context, Product product) async {
    final updated = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditorSheet(product: product),
    );

    if (updated == null || !context.mounted) {
      return;
    }

    try {
      await store.updateProduct(updated);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Товар обновлён.')));
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showError(context, error, 'Не удалось обновить товар.');
    }
  }

  Future<void> _delete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: const Text(
          'Карточка будет удалена без возможности восстановления.',
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await store.deleteProduct(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Товар удалён.')));
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showError(context, error, 'Не удалось удалить товар.');
    }
  }

  Future<void> _toggleFavorite(BuildContext context, Product product) async {
    try {
      await store.toggleFavorite(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар перенесён в избранные.')),
        );
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showError(context, error, 'Не удалось обновить избранное.');
    }
  }

  Future<void> _openViewer(
    BuildContext context,
    Product product,
    int index,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoViewerPage(product: product, initialIndex: index),
        fullscreenDialog: true,
      ),
    );
  }

  void _showError(BuildContext context, Object error, String fallback) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(describeError(error, fallbackMessage: fallback))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = store.products;

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
          children: [
            SectionHeroCard(
              badge: 'CATALOG',
              badgeColor: AppColors.primary,
              title: 'Товары',
              description:
                  'Здесь видны все созданные товары. Можно открыть фото, редактировать карточку или удалить товар.',
              count: products.length,
              countLabel: 'Всего в разделе',
              colors: const [Color(0x2E7C92FF), Color(0x1461E5BE)],
            ),
            const SizedBox(height: 18),
            if (products.isEmpty)
              const EmptyStateCard(
                icon: Icons.shopping_bag_outlined,
                iconColor: AppColors.accent,
                title: 'Пока нет товаров',
                description:
                    'Создай товар в первом разделе, и он сразу появится здесь.',
              )
            else
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ProductCard(
                    product: product,
                    onEdit: () => _openEditor(context, product),
                    onDelete: () => _delete(context, product),
                    onToggleFavorite: () => _toggleFavorite(context, product),
                    onOpenImage: (index) =>
                        _openViewer(context, product, index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
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
    final status = product.status.toLowerCase() == 'new'
        ? 'НОВЫЙ'
        : product.status.toUpperCase();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatProductDate(product.createdAt),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
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
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Сумма',
                  value: product.amount.isEmpty ? 'Не указано' : product.amount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Материал',
                  value: product.material.isEmpty
                      ? 'Не указано'
                      : product.material,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Размер',
                  value: product.size.isEmpty ? 'Не указано' : product.size,
                ),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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

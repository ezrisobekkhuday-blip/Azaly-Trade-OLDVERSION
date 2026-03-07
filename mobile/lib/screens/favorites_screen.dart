import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/section_cards.dart';
import 'photo_viewer_page.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.store});

  final AppStore store;

  Future<void> _toggleFavorite(BuildContext context, Product product) async {
    try {
      await store.toggleFavorite(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Товар убран из избранного.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: 'Не удалось обновить избранное.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openViewer(
    BuildContext context,
    Product product,
    int initialIndex,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PhotoViewerPage(product: product, initialIndex: initialIndex),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _shareProduct(BuildContext context, Product product) async {
    final files = product.imagePaths
        .where((path) => !isRemoteImageSource(path) && File(path).existsSync())
        .map(XFile.new)
        .toList();
    final remoteImages = product.imagePaths.where(isRemoteImageSource).toList();
    final summary = [
      'Избранный товар из Azaly Trade',
      'Сумма: ${product.amount.isEmpty ? 'Не указано' : product.amount}',
      'Материал: ${product.material.isEmpty ? 'Не указано' : product.material}',
      'Размер: ${product.size.isEmpty ? 'Не указано' : product.size}',
      'Статус: ${product.status}',
      if (remoteImages.isNotEmpty) ...['Фото:', ...remoteImages],
    ].join('\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Azaly Trade',
          subject: 'Избранный товар',
          text: summary,
          files: files.isEmpty ? null : files,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Открылось меню «Поделиться». Можно выбрать Telegram.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть меню «Поделиться».'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = store.favoriteProducts;

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
          children: [
            SectionHeroCard(
              badge: 'FAVORITES',
              badgeColor: AppColors.danger,
              title: 'Избранные',
              description:
                  'Сюда попадают любимые товары. Здесь можно открыть фото и отправить карточку через Telegram или другое приложение.',
              count: favorites.length,
              countLabel: 'Любимых товаров',
              colors: const [Color(0x24FF7D93), Color(0x147C92FF)],
            ),
            const SizedBox(height: 18),
            if (favorites.isEmpty)
              const EmptyStateCard(
                icon: Icons.favorite_border,
                iconColor: AppColors.danger,
                title: 'Пока нет избранного',
                description:
                    'Нажми на сердечко у товара во второй вкладке, и он появится здесь.',
              )
            else
              ...favorites.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FavoriteCard(
                    product: product,
                    onOpenImage: (index) =>
                        _openViewer(context, product, index),
                    onShare: () => _shareProduct(context, product),
                    onUnfavorite: () => _toggleFavorite(context, product),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.product,
    required this.onOpenImage,
    required this.onShare,
    required this.onUnfavorite,
  });

  final Product product;
  final ValueChanged<int> onOpenImage;
  final VoidCallback onShare;
  final VoidCallback onUnfavorite;

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
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ИЗБРАННЫЙ',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.danger,
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
              const Icon(Icons.favorite, color: AppColors.danger),
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
                child: FilledButton.icon(
                  onPressed: onShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF08110F),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Поделиться'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onUnfavorite,
                  icon: const Icon(Icons.heart_broken_outlined),
                  label: const Text('Убрать'),
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

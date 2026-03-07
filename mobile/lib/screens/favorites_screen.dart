import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/product_thumbnail_card.dart';
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
          SnackBar(content: Text(AppStrings.of(context).t('favoriteRemoved'))),
        );
      }
    } catch (error) {
      if (context.mounted) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: strings.t('cannotUpdateFavorite'),
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
    final strings = AppStrings.of(context);
    final language = strings.language;
    final grossTotal = product.grossTotalValue;
    final supplierShare = product.supplierShareValue;
    final files = product.imagePaths
        .where((path) => !isRemoteImageSource(path) && File(path).existsSync())
        .map(XFile.new)
        .toList();
    final remoteImages = product.imagePaths.where(isRemoteImageSource).toList();
    final summary = [
      strings.t('shareSummaryTitle'),
      '${strings.t('purchasePriceLabel')}: ${product.amount.isEmpty ? strings.t('notSpecified') : product.amount}',
      '${strings.t('quantityLabel')}: ${product.quantity}',
      '${strings.t('grossTotalLabel')}: ${grossTotal == null ? strings.t('notSpecified') : formatProductMoney(grossTotal)}',
      '${strings.t('supplierShareLabel')}: ${supplierShare == null ? strings.t('notSpecified') : '-${formatProductMoney(supplierShare)}'}',
      '${strings.t('totalLabel')}: ${product.totalValue == null ? strings.t('notSpecified') : formatProductMoney(product.totalValue!)}',
      '${strings.t('colorLabel')}: ${product.color.isEmpty ? strings.t('notSpecified') : localizeColorValue(language, product.color)}',
      '${strings.t('materialLabel')}: ${product.material.isEmpty ? strings.t('notSpecified') : localizeMaterialValue(language, product.material)}',
      '${strings.t('sizeLabel')}: ${product.size.isEmpty ? strings.t('notSpecified') : localizeSizeValue(language, product.size)}',
      '${strings.t('statusLabel')}: ${strings.localizeStatus(product.status)}',
      if (remoteImages.isNotEmpty) ...[
        '${strings.t('photosLabel')}:',
        ...remoteImages,
      ],
    ].join('\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: strings.t('shareTitle'),
          subject: strings.t('shareSubject'),
          text: summary,
          files: files.isEmpty ? null : files,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.t('shareMenuOpened'))));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.t('shareMenuFailed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = store.favoriteProducts;
    final strings = AppStrings.of(context);

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            SectionHeroCard(
              badge: strings.t('favoritesHeroBadge'),
              badgeColor: AppColors.danger,
              title: strings.t('favoritesHeroTitle'),
              description: strings.t('favoritesHeroDescription'),
              count: favorites.length,
              countLabel: strings.t('favoriteCountLabel'),
              colors: const [Color(0x24FF7D93), Color(0x147C92FF)],
            ),
            const SizedBox(height: 18),
            if (favorites.isEmpty)
              EmptyStateCard(
                icon: Icons.favorite_border,
                iconColor: AppColors.danger,
                title: strings.t('noFavoritesTitle'),
                description: strings.t('noFavoritesDescription'),
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
    final strings = AppStrings.of(context);
    final language = strings.language;

    return Container(
      padding: const EdgeInsets.all(16),
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
                  strings.t('favoriteBadge'),
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
              _InfoTile(
                label: strings.t('priceLabel'),
                value: product.amount.isEmpty
                    ? strings.t('notSpecified')
                    : product.amount,
              ),
              _InfoTile(
                label: strings.t('piecesLabel'),
                value: '${product.quantity}',
              ),
              _InfoTile(
                label: strings.t('totalLabel'),
                value: product.totalValue == null
                    ? strings.t('notSpecified')
                    : formatProductMoney(product.totalValue!),
              ),
              _InfoTile(
                label: strings.t('colorLabel'),
                value: product.color.isEmpty
                    ? strings.t('notSpecified')
                    : localizeColorValue(language, product.color),
              ),
              _InfoTile(
                label: strings.t('materialLabel'),
                value: product.material.isEmpty
                    ? strings.t('notSpecified')
                    : localizeMaterialValue(language, product.material),
              ),
              _InfoTile(
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
                child: FilledButton.icon(
                  onPressed: onShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF08110F),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(strings.t('share')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onUnfavorite,
                  icon: const Icon(Icons.heart_broken_outlined),
                  label: Text(strings.t('remove')),
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
      constraints: const BoxConstraints(minWidth: 104),
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

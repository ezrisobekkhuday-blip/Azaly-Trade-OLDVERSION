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
import 'shop_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.store});

  final AppStore store;

  String _purchaseActionLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.ru:
        return 'Закуп';
      case AppLanguage.en:
        return 'Purchase';
      case AppLanguage.zh:
        return '采购';
    }
  }

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

  Future<void> _toggleStorefrontFavorite(
    BuildContext context,
    FavoriteStorefrontEntry entry,
  ) async {
    try {
      await store.toggleStorefrontFavorite(entry.shopId, entry.storefrontIndex);

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

  Future<void> _openStorefrontViewer(
    BuildContext context,
    FavoriteStorefrontEntry entry,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SingleFavoriteImagePage(
          title: entry.shopName.trim().isEmpty
              ? AppStrings.of(context).t('newShop')
              : entry.shopName,
          imageSource: entry.item.imagePath,
        ),
      ),
    );
  }

  Future<void> _openPurchaseFromStorefront(
    BuildContext context,
    FavoriteStorefrontEntry entry,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopDetailsScreen(
          store: store,
          shopId: entry.shopId,
          initialStorefrontIndex: entry.storefrontIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = store.favoriteProducts;
    final storefrontFavorites = store.favoriteStorefrontItems;
    final totalFavorites = favorites.length + storefrontFavorites.length;
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

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
              count: totalFavorites,
              countLabel: strings.t('favoriteCountLabel'),
              colors: const [Color(0x24FF7D93), Color(0x147C92FF)],
            ),
            const SizedBox(height: 18),
            if (totalFavorites == 0)
              EmptyStateCard(
                icon: Icons.favorite_border,
                iconColor: AppColors.danger,
                title: strings.t('noFavoritesTitle'),
                description: strings.t('noFavoritesDescription'),
              )
            else ...[
              if (storefrontFavorites.isNotEmpty) ...[
                Text(
                  strings.t('storefrontPhotos'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 960
                        ? 4
                        : constraints.maxWidth >= 720
                        ? 3
                        : constraints.maxWidth >= 320
                        ? 2
                        : 1;
                    const spacing = 14.0;
                    final itemWidth =
                        (constraints.maxWidth -
                            (crossAxisCount - 1) * spacing) /
                        crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: storefrontFavorites
                          .map(
                            (entry) => SizedBox(
                              width: itemWidth,
                              child: _FavoriteStorefrontCard(
                                entry: entry,
                                purchaseLabel: _purchaseActionLabel(
                                  strings.language,
                                ),
                                onOpenImage: () =>
                                    _openStorefrontViewer(context, entry),
                                onPurchase: () =>
                                    _openPurchaseFromStorefront(context, entry),
                                onUnfavorite: () =>
                                    _toggleStorefrontFavorite(context, entry),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
              if (storefrontFavorites.isNotEmpty && favorites.isNotEmpty)
                const SizedBox(height: 6),
              if (favorites.isNotEmpty) ...[
                Text(
                  strings.t('shopPurchases'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
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
            ],
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

class _FavoriteStorefrontCard extends StatelessWidget {
  const _FavoriteStorefrontCard({
    required this.entry,
    required this.purchaseLabel,
    required this.onOpenImage,
    required this.onPurchase,
    required this.onUnfavorite,
  });

  final FavoriteStorefrontEntry entry;
  final String purchaseLabel;
  final VoidCallback onOpenImage;
  final VoidCallback onPurchase;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final language = strings.language;
    final item = entry.item;
    final title = entry.shopName.trim().isEmpty
        ? strings.t('newShop')
        : entry.shopName;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10182C), Color(0xFF0D1526)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onOpenImage,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: ProductImage(
                        source: item.imagePath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.background.withValues(alpha: 0.06),
                              AppColors.background.withValues(alpha: 0.68),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.56, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton.filledTonal(
                        onPressed: onUnfavorite,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceStrong.withValues(
                            alpha: 0.92,
                          ),
                          foregroundColor: AppColors.danger,
                        ),
                        icon: const Icon(Icons.favorite),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (item.amount.trim().isNotEmpty)
                            _FavoriteOverlayChip(
                              icon: Icons.sell_outlined,
                              label: item.amount,
                            ),
                          if (item.color.trim().isNotEmpty)
                            _FavoriteOverlayChip(
                              icon: Icons.palette_outlined,
                              label: localizeColorValue(language, item.color),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          if (entry.shopLocation.trim().isNotEmpty)
            Text(
              entry.shopLocation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            formatProductDate(entry.createdAt),
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FavoriteStorefrontInfoTile(
                  label: strings.t('materialLabel'),
                  value: item.material.isEmpty
                      ? strings.t('notSpecified')
                      : localizeMaterialValue(language, item.material),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FavoriteStorefrontInfoTile(
                  label: strings.t('sizeLabel'),
                  value: item.size.isEmpty
                      ? strings.t('notSpecified')
                      : localizeSizeValue(language, item.size),
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF08110F),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onPurchase,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(purchaseLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteStorefrontInfoTile extends StatelessWidget {
  const _FavoriteStorefrontInfoTile({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlighted
              ? [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.surfaceStrong,
                ]
              : [AppColors.surfaceStrong, AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteOverlayChip extends StatelessWidget {
  const _FavoriteOverlayChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xA611182B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _SingleFavoriteImagePage extends StatelessWidget {
  const _SingleFavoriteImagePage({
    required this.title,
    required this.imageSource,
  });

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

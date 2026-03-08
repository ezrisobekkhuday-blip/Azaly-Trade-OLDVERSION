import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/api_client.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/section_cards.dart';
import 'image_gallery_page.dart';
import 'shop_editor_sheet.dart';
import 'shop_details_screen.dart';

enum _ShopCardAction { pin, edit, delete }

class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key, required this.store});

  final AppStore store;

  Future<void> _openShop(BuildContext context, Shop shop) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopDetailsScreen(store: store, shopId: shop.id),
      ),
    );
  }

  Future<void> _openShopPhoto(BuildContext context, Shop shop) async {
    if (shop.photo.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageGalleryPage(
          title: AppStrings.of(context).t('shopPhotoTitle'),
          imageSources: [shop.photo],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, Shop shop) async {
    final updatedShop = await showModalBottomSheet<Shop>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopEditorSheet(shop: shop),
    );

    if (updatedShop == null || !context.mounted) {
      return;
    }

    try {
      await store.updateShop(updatedShop);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).t('shopUpdated'))),
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
                fallbackMessage: strings.t('cannotUpdateShop'),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteShop(BuildContext context, Shop shop) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('deleteShopTitle')),
        content: Text(strings.t('deleteShopMessage')),
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await store.deleteShop(shop.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.t('shopDeleted'))));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: strings.t('cannotDeleteShop'),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _togglePin(BuildContext context, Shop shop) async {
    final strings = AppStrings.of(context);
    final pinned = store.isShopPinned(shop.id);

    await store.setShopPinned(shop.id, !pinned);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.t(pinned ? 'shopUnpinned' : 'shopPinned')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = store.shops;
    final strings = AppStrings.of(context);

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            SectionHeroCard(
              badge: strings.t('shopsHeroBadge'),
              badgeColor: AppColors.primary,
              title: strings.t('shopsHeroTitle'),
              description: strings.t('shopsHeroDescription'),
              count: shops.length,
              countLabel: strings.t('totalShops'),
              colors: const [Color(0x2E7C92FF), Color(0x1461E5BE)],
            ),
            const SizedBox(height: 18),
            if (shops.isEmpty)
              EmptyStateCard(
                icon: Icons.storefront_outlined,
                iconColor: AppColors.accent,
                title: strings.t('noShopsTitle'),
                description: strings.t('noShopsDescription'),
              )
            else
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
                      (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                      crossAxisCount;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: shops
                        .map(
                          (shop) => SizedBox(
                            width: itemWidth,
                            child: _ShopCard(
                              store: store,
                              shop: shop,
                              isPinned: store.isShopPinned(shop.id),
                              onOpen: () => _openShop(context, shop),
                              onPhotoTap: () => _openShopPhoto(context, shop),
                              onTogglePin: () => _togglePin(context, shop),
                              onEdit: () => _openEditor(context, shop),
                              onDelete: () => _deleteShop(context, shop),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.store,
    required this.shop,
    required this.isPinned,
    required this.onOpen,
    required this.onPhotoTap,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
  });

  final AppStore store;
  final Shop shop;
  final bool isPinned;
  final VoidCallback onOpen;
  final VoidCallback onPhotoTap;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final summary = store.purchaseSummaryForShop(shop.id);
    final title = shop.name.isEmpty ? strings.t('newShop') : shop.name;
    final subtitle = shop.location.isNotEmpty
        ? shop.location
        : shop.description;
    final hasBusinessCard = shop.businessCardImage.isNotEmpty;

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
          GestureDetector(
            onTap: onPhotoTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: shop.photo.isEmpty
                        ? Container(
                            color: AppColors.surfaceStrong,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.textMuted,
                              size: 42,
                            ),
                          )
                        : ProductImage(
                            source: shop.photo,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.08),
                            AppColors.background.withValues(alpha: 0.68),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.52, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (isPinned) const _PinnedBadge(),
                        if (hasBusinessCard) const _BusinessCardBadge(),
                      ],
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
                        _OverlayChip(
                          icon: Icons.inventory_2_outlined,
                          label: strings.formatShopItemCount(
                            shop.productsCount,
                          ),
                        ),
                        _OverlayChip(
                          icon: Icons.layers_outlined,
                          label:
                              '${summary.totalQuantity} ${strings.t('piecesShort')}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_ShopCardAction>(
                tooltip: '',
                padding: EdgeInsets.zero,
                color: const Color(0xF411182B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: AppColors.border),
                ),
                icon: const _CardMenuButton(),
                onSelected: (action) {
                  switch (action) {
                    case _ShopCardAction.pin:
                      onTogglePin();
                      break;
                    case _ShopCardAction.edit:
                      onEdit();
                      break;
                    case _ShopCardAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_ShopCardAction>(
                    value: _ShopCardAction.pin,
                    child: Row(
                      children: [
                        Icon(
                          isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text(strings.t(isPinned ? 'unpinShop' : 'pinShop')),
                      ],
                    ),
                  ),
                  PopupMenuItem<_ShopCardAction>(
                    value: _ShopCardAction.edit,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text(strings.t('edit')),
                      ],
                    ),
                  ),
                  PopupMenuItem<_ShopCardAction>(
                    value: _ShopCardAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          strings.t('delete'),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShopSummaryTile(
                  label: strings.t('grossTotalWithRateLabel'),
                  value: _formatSummaryMoney(summary.grossTotal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ShopSummaryTile(
                  label: strings.t('netTotalWithRateLabel'),
                  value: _formatSummaryMoney(summary.netTotal),
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
              onPressed: onOpen,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(strings.t('openShop')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatSummaryMoney(double value) {
  if (value <= 0) {
    return '0';
  }

  return formatProductMoney(value);
}

class _ShopSummaryTile extends StatelessWidget {
  const _ShopSummaryTile({
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

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.icon, required this.label});

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

class _BusinessCardBadge extends StatelessWidget {
  const _BusinessCardBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xD611182B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.badge_outlined,
        size: 15,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.push_pin, size: 14, color: Color(0xFF08110F)),
    );
  }
}

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.more_vert,
        size: 16,
        color: AppColors.textPrimary,
      ),
    );
  }
}

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
import 'shop_editor_sheet.dart';
import 'shop_details_screen.dart';

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
              ...shops.map(
                (shop) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ShopCard(
                    store: store,
                    shop: shop,
                    onOpen: () => _openShop(context, shop),
                    onEdit: () => _openEditor(context, shop),
                    onDelete: () => _deleteShop(context, shop),
                  ),
                ),
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
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final AppStore store;
  final Shop shop;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final summary = store.purchaseSummaryForShop(shop.id);
    final title = shop.name.isEmpty ? strings.t('newShop') : shop.name;
    final hasBusinessCard = shop.businessCardImage.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10182C), Color(0xFF0D1526)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.34,
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
                          AppColors.background.withValues(alpha: 0.10),
                          AppColors.background.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.52, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasBusinessCard)
                        _OverlayChip(
                          icon: Icons.badge_outlined,
                          label: strings.t('businessCardShort'),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _OverlayChip(
                        icon: Icons.inventory_2_outlined,
                        label: strings.formatShopItemCount(shop.productsCount),
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
          const SizedBox(height: 14),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (shop.location.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              shop.location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (shop.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              shop.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ShopSummaryTile(
                  label: strings.t('grossTotalWithRateLabel'),
                  value: _formatSummaryMoney(summary.grossTotal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShopSummaryTile(
                  label: strings.t('netTotalWithRateLabel'),
                  value: _formatSummaryMoney(summary.netTotal),
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(strings.t('edit')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0x2D74A57D),
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.t('delete')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF08110F),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: onOpen,
              child: Text(strings.t('openShop')),
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
      padding: const EdgeInsets.all(14),
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
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xA611182B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

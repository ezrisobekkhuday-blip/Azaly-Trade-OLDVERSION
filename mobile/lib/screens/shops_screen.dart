import 'package:flutter/material.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Магазин обновлён.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: 'Не удалось обновить магазин.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteShop(BuildContext context, Shop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить магазин?'),
        content: const Text(
          'Магазин, товары и фото будут удалены без возможности восстановления.',
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
      await store.deleteShop(shop.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Магазин удалён.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              describeError(
                error,
                fallbackMessage: 'Не удалось удалить магазин.',
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

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            SectionHeroCard(
              badge: 'SHOPS',
              badgeColor: AppColors.primary,
              title: 'Магазины',
              description:
                  'Здесь собраны все магазины. Открой нужный магазин и уже внутри создавай товары.',
              count: shops.length,
              countLabel: 'Всего магазинов',
              colors: const [Color(0x2E7C92FF), Color(0x1461E5BE)],
            ),
            const SizedBox(height: 18),
            if (shops.isEmpty)
              const EmptyStateCard(
                icon: Icons.storefront_outlined,
                iconColor: AppColors.accent,
                title: 'Пока нет магазинов',
                description:
                    'Создай магазин в первой вкладке, и он сразу появится здесь.',
              )
            else
              ...shops.map(
                (shop) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ShopCard(
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
    required this.shop,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Shop shop;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: shop.photo.isEmpty
                ? Container(
                    height: 180,
                    color: AppColors.surfaceStrong,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.textMuted,
                      size: 36,
                    ),
                  )
                : ProductImage(
                    source: shop.photo,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            shop.name.isEmpty ? 'Новый магазин' : shop.name,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (shop.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              shop.location,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (shop.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shop.description,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(
                icon: Icons.inventory_2_outlined,
                label: '${shop.productsCount} товаров',
              ),
              const SizedBox(width: 10),
              if (shop.businessCardImage.isNotEmpty)
                const _StatPill(icon: Icons.badge_outlined, label: 'Визитка'),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
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
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: onOpen,
              child: const Text('Открыть магазин'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

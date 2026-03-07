import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../state/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/product_image.dart';
import '../widgets/section_cards.dart';
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

  @override
  Widget build(BuildContext context) {
    final shops = store.shops;

    return AppBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 132),
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
  const _ShopCard({required this.shop, required this.onOpen});

  final Shop shop;
  final VoidCallback onOpen;

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
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
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

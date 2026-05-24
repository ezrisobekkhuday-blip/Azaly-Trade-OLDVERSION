import 'package:flutter/material.dart';

import '../data/product_presets.dart';
import '../localization/app_strings.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';

class SearchMatchedProductCard extends StatelessWidget {
  const SearchMatchedProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final language = strings.language;
    final textTheme = Theme.of(context).textTheme;
    final imageSource =
        product.imagePaths.isEmpty ? '' : product.imagePaths.first;
    final total = product.totalValue;

    final metaParts = <String>[];
    final color = product.color.trim();
    final material = product.material.trim();
    final size = product.size.trim();

    if (color.isNotEmpty) {
      metaParts.add(localizeColorValue(language, color));
    }
    if (material.isNotEmpty) {
      metaParts.add(localizeMaterialValue(language, material));
    }
    if (size.isNotEmpty) {
      metaParts.add(size);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 68,
              height: 68,
              child: imageSource.isEmpty
                  ? const ColoredBox(
                      color: AppColors.surfaceMuted,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.textMuted,
                      ),
                    )
                  : ProductImage(
                      source: imageSource,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          children: [
                            _CompactStat(
                              label: strings.t('articleLabel'),
                              value: product.article.trim().isEmpty
                                  ? strings.t('notSpecified')
                                  : product.article.trim(),
                            ),
                            const _StatDivider(),
                            _CompactStat(
                              label: strings.t('priceLabel'),
                              value: product.amount.trim().isEmpty
                                  ? strings.t('notSpecified')
                                  : product.amount.trim(),
                            ),
                            const _StatDivider(),
                            _CompactStat(
                              label: strings.t('piecesLabel'),
                              value: '${product.quantity}',
                            ),
                            const _StatDivider(),
                            _CompactStat(
                              label: strings.t('totalLabel'),
                              value: total == null
                                  ? strings.t('notSpecified')
                                  : formatProductMoney(total),
                              highlighted: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    metaParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.border,
    );
  }
}

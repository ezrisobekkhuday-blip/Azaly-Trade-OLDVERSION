import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'product_image.dart';

class ProductThumbnailCard extends StatelessWidget {
  const ProductThumbnailCard({
    super.key,
    required this.source,
    this.width = 112,
    this.height = 148,
    this.onTap,
    this.onRemove,
  });

  final String source;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ProductImage(
          source: source,
          width: width - 16,
          height: height - 16,
          fit: BoxFit.contain,
        ),
      ),
    );

    return Stack(
      children: [
        if (onTap == null)
          content
        else
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: content,
          ),
        if (onRemove != null)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filledTonal(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

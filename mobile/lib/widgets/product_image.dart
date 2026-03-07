import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isRemoteImageSource(source)) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _ImageFallback(width: width, height: height),
      );
    }

    return Image.file(
      File(source),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => _ImageFallback(width: width, height: height),
    );
  }
}

bool isRemoteImageSource(String source) {
  return source.startsWith('http://') || source.startsWith('https://');
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: AppColors.surfaceStrong,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textMuted,
      ),
    );
  }
}

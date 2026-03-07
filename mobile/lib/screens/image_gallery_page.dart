import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/product_image.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({
    super.key,
    required this.title,
    required this.imageSources,
    this.initialIndex = 0,
  });

  final String title;
  final List<String> imageSources;
  final int initialIndex;

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _jumpToPage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageSources.length,
                onPageChanged: (value) => setState(() => _currentIndex = value),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.9,
                    maxScale: 3.5,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ProductImage(
                          source: widget.imageSources[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.imageSources.length > 1)
              SizedBox(
                height: 108,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imageSources.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final selected = index == _currentIndex;

                    return GestureDetector(
                      onTap: () => _jumpToPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: ProductImage(
                            source: widget.imageSources[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

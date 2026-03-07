import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

class ShopMapPreview extends StatefulWidget {
  const ShopMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 180,
    this.interactive = false,
  });

  final double latitude;
  final double longitude;
  final double height;
  final bool interactive;

  @override
  State<ShopMapPreview> createState() => _ShopMapPreviewState();
}

class _ShopMapPreviewState extends State<ShopMapPreview> {
  late bool _isMapVisible;

  @override
  void initState() {
    super.initState();
    _isMapVisible = widget.interactive;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapVisible) {
      return _MapPlaceholder(
        height: widget.height,
        latitude: widget.latitude,
        longitude: widget.longitude,
        onOpen: () => setState(() => _isMapVisible = true),
      );
    }

    final point = LatLng(widget.latitude, widget.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mobile',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 54,
                  height: 54,
                  child: const _MapPin(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.height,
    required this.latitude,
    required this.longitude,
    required this.onOpen,
  });

  final double height;
  final double latitude;
  final double longitude;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          gradient: const LinearGradient(
            colors: [Color(0x1400E5FF), Color(0x203A4E7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _MapPin(),
            const SizedBox(height: 10),
            Text(
              strings.t('tapToLoadMap'),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on_outlined,
          size: 18,
          color: Color(0xFF08110F),
        ),
      ),
    );
  }
}

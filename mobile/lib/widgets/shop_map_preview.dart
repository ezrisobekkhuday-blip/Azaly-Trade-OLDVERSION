import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class ShopMapPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
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

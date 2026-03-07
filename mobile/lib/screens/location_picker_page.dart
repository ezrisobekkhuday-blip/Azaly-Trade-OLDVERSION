import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/map_selection_result.dart';
import '../theme/app_theme.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const LatLng _fallbackCenter = LatLng(41.3111, 69.2797);

  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  bool _isSaving = false;
  bool _isResolvingCurrent = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint =
        widget.initialLatitude != null && widget.initialLongitude != null
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _fallbackCenter;
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() {
      _isResolvingCurrent = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Включите геолокацию на устройстве.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Разрешите доступ к геолокации.');
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } on TimeoutException {
        position ??= await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _showMessage('Не удалось получить текущую точку.');
        return;
      }

      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
      });
      _mapController.move(point, 16);
    } catch (_) {
      _showMessage('Не удалось определить текущую точку.');
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingCurrent = false;
        });
      }
    }
  }

  Future<void> _saveSelection() async {
    setState(() {
      _isSaving = true;
    });

    try {
      var label =
          '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          _selectedPoint.latitude,
          _selectedPoint.longitude,
        ).timeout(const Duration(seconds: 3));

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>{
            if (place.street?.trim().isNotEmpty ?? false) place.street!.trim(),
            if (place.subLocality?.trim().isNotEmpty ?? false)
              place.subLocality!.trim(),
            if (place.locality?.trim().isNotEmpty ?? false)
              place.locality!.trim(),
            if (place.administrativeArea?.trim().isNotEmpty ?? false)
              place.administrativeArea!.trim(),
            if (place.country?.trim().isNotEmpty ?? false)
              place.country!.trim(),
          }.toList();

          if (parts.isNotEmpty) {
            label = parts.join(', ');
          }
        }
      } catch (_) {
        // Keep coordinates if reverse geocoding is slow or unavailable.
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        MapSelectionResult(
          latitude: _selectedPoint.latitude,
          longitude: _selectedPoint.longitude,
          label: label,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Точка магазина')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 16,
                onTap: (_, point) {
                  setState(() {
                    _selectedPoint = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 54,
                      height: 54,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Поставь метку на карту',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Нажми на карту там, где находится магазин.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${_selectedPoint.latitude.toStringAsFixed(5)}, '
                    '${_selectedPoint.longitude.toStringAsFixed(5)}',
                    style: textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isResolvingCurrent
                            ? null
                            : _moveToCurrentLocation,
                        icon: _isResolvingCurrent
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_outlined),
                        label: const Text('Моя точка'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveSelection,
                        child: Text(_isSaving ? 'Сохраняем...' : 'Сохранить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_theme.dart';

int _cameraViewCounter = 0;
const int _captureMaxDimension = 1440;

Future<String?> captureImageWithWebCamera(
  BuildContext context, {
  bool preferRearCamera = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WebCameraCaptureSheet(preferRearCamera: preferRearCamera),
  );
}

class _WebCameraCaptureSheet extends StatefulWidget {
  const _WebCameraCaptureSheet({required this.preferRearCamera});

  final bool preferRearCamera;

  @override
  State<_WebCameraCaptureSheet> createState() => _WebCameraCaptureSheetState();
}

class _WebCameraCaptureSheetState extends State<_WebCameraCaptureSheet> {
  late final html.VideoElement _videoElement;
  late final String _viewType;
  html.MediaStream? _stream;
  bool _isStarting = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#0A1123';

    _viewType = 'azaly-web-camera-${_cameraViewCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      return _videoElement;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCamera();
    });
  }

  Future<void> _startCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw StateError('Media devices unavailable');
      }

      html.MediaStream? stream;
      final preferredFacingMode = widget.preferRearCamera ? 'environment' : 'user';

      try {
        stream = await mediaDevices.getUserMedia({
          'video': {
            'facingMode': preferredFacingMode,
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
          'audio': false,
        });
      } catch (_) {
        stream = await mediaDevices.getUserMedia({
          'video': true,
          'audio': false,
        });
      }

      _stream = stream;
      _videoElement.srcObject = stream;
      await _videoElement.play();

      if (!mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage = AppStrings.of(context).t('cannotOpenCamera');
      });
    }
  }

  Future<void> _capture() async {
    if (_isCapturing) {
      return;
    }

    final width = _videoElement.videoWidth;
    final height = _videoElement.videoHeight;

    if (width <= 0 || height <= 0) {
      setState(() {
        _errorMessage = AppStrings.of(context).t('cannotOpenCamera');
      });
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final longestSide = width > height ? width : height;
      final scale = longestSide > _captureMaxDimension
          ? _captureMaxDimension / longestSide
          : 1.0;
      final targetWidth = (width * scale).round();
      final targetHeight = (height * scale).round();
      final canvas = html.CanvasElement(
        width: targetWidth,
        height: targetHeight,
      );
      final context2d = canvas.context2D;
      context2d.drawImageScaled(
        _videoElement,
        0,
        0,
        targetWidth.toDouble(),
        targetHeight.toDouble(),
      );
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.88);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(dataUrl);
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _stopCamera() {
    final tracks = _stream?.getTracks() ?? const <html.MediaStreamTrack>[];
    for (final track in tracks) {
      track.stop();
    }
    _videoElement.pause();
    _videoElement.srcObject = null;
    _stream = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.background, AppColors.backgroundSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.t('camera'),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  height: 320,
                  color: AppColors.surfaceStrong,
                  child: _isStarting
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : HtmlElementView(viewType: _viewType),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF08110F),
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: _isStarting || _errorMessage != null || _isCapturing
                      ? null
                      : _capture,
                  icon: _isCapturing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(strings.t('camera')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

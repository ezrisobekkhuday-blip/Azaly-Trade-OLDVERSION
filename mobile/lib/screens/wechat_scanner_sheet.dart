import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../localization/app_strings.dart';
import '../services/web_camera_capture.dart';
import '../services/wechat_qr_decoder.dart';
import '../theme/app_theme.dart';

Future<String?> openWechatScannerSheet(BuildContext context) {
  if (kIsWeb) {
    return _openWechatScannerOnWeb(context);
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WechatScannerSheet(),
  );
}

Future<String?> _openWechatScannerOnWeb(BuildContext context) async {
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final imageSource = await captureImageWithWebCamera(
    context,
    maxDimension: 4096,
    preferPng: true,
    idealWidth: 2560,
    idealHeight: 1440,
  );

  if (imageSource == null || !context.mounted) {
    return null;
  }

  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(content: Text(strings.t('wechatQrProcessing'))),
  );

  try {
    final decodedValue = await decodeWechatQrImage(imageSource);
    messenger?.hideCurrentSnackBar();

    if (!context.mounted) {
      return null;
    }

    if (decodedValue == null || decodedValue.trim().isEmpty) {
      messenger?.showSnackBar(
        SnackBar(content: Text(strings.t('wechatQrNotFound'))),
      );
      return null;
    }

    return decodedValue.trim();
  } catch (_) {
    messenger?.hideCurrentSnackBar();
    if (context.mounted) {
      messenger?.showSnackBar(
        SnackBar(content: Text(strings.t('wechatQrDecodeFailed'))),
      );
    }
    return null;
  }
}

class _WechatScannerSheet extends StatefulWidget {
  const _WechatScannerSheet();

  @override
  State<_WechatScannerSheet> createState() => _WechatScannerSheetState();
}

class _WechatScannerSheetState extends State<_WechatScannerSheet>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _isHandlingResult = false;
  bool _isStarting = false;
  String? _errorMessage;
  Future<void>? _startFuture;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(
        '/zxing_library.js',
      );
    }
    WidgetsBinding.instance.addObserver(this);

    // On web, starting the camera must be triggered via a user gesture.
    // Otherwise the browser may block camera access and the scanner may hang.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startScanner();
      });
    }
  }

  Future<void> _startScanner() async {
    // Avoid calling start() multiple times while initialization is in progress.
    // MobileScannerController throws a controllerInitializing error when start()
    // is called again while a previous call is still running.
    if (_controller.value.isStarting) {
      setState(() {
        _isStarting = true;
        _errorMessage = null;
      });

      // Wait for the controller to stop initializing.
      final completer = Completer<void>();
      void listener() {
        if (!_controller.value.isStarting && !completer.isCompleted) {
          completer.complete();
        }
      }

      _controller.addListener(listener);
      try {
        await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            // If initialization hangs, allow retry.
          },
        );
      } finally {
        _controller.removeListener(listener);
      }

      if (_controller.value.isStarting) {
        setState(() {
          _isStarting = false;
          _errorMessage = AppStrings.of(context).t('cannotOpenCamera');
        });
      } else {
        setState(() {
          _isStarting = false;
        });
      }

      return;
    }

    final currentFuture = _startFuture;
    if (currentFuture != null) {
      return currentFuture;
    }

    final future = _performStartScanner();
    _startFuture = future;

    try {
      await future;
    } finally {
      if (identical(_startFuture, future)) {
        _startFuture = null;
      }
    }
  }

  Future<void> _performStartScanner() async {
    if (!mounted) {
      return;
    }

    if (_controller.value.isRunning) {
      setState(() {
        _isStarting = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      await _controller.start();

      if (!mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage = switch (error) {
          MobileScannerException scannerException =>
            scannerException.errorDetails?.message?.trim().isNotEmpty == true
                ? scannerException.errorDetails!.message!
                : AppStrings.of(context).t('cannotOpenCamera'),
          _ => AppStrings.of(context).t('cannotOpenCamera'),
        };
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (_controller.value.isStarting) {
          return;
        }
        _startScanner();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_isHandlingResult) {
      return;
    }

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) {
      return;
    }

    _isHandlingResult = true;
    Navigator.of(context).pop(rawValue);
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.t('scanWechat'),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.t('scanWechatDescription'),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 320,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MobileScanner(
                          controller: _controller,
                          onDetect: _handleCapture,
                          placeholderBuilder: (context) => Container(
                            color: AppColors.surfaceStrong,
                            alignment: Alignment.center,
                            child: _isStarting
                                ? const CircularProgressIndicator()
                                : Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 40,
                                    color: AppColors.textMuted,
                                  ),
                          ),
                          errorBuilder: (context, error) {
                            return Container(
                              color: AppColors.surfaceStrong,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                error.errorDetails?.message ??
                                    AppStrings.of(
                                      context,
                                    ).t('cannotOpenCamera'),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_errorMessage != null && !_isStarting)
                        Positioned.fill(
                          child: Container(
                            color: AppColors.surfaceStrong,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 36,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.tonalIcon(
                                  onPressed: _startScanner,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: Text(strings.t('enableCamera')),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _isStarting ? null : _startScanner,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(strings.t('enableCamera')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

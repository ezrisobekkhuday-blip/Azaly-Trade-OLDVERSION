import 'package:flutter/material.dart';

import 'web_camera_capture_stub.dart'
    if (dart.library.html) 'web_camera_capture_web.dart' as impl;

Future<String?> captureImageWithWebCamera(
  BuildContext context, {
  bool preferRearCamera = true,
  int? maxDimension,
  bool preferPng = false,
  int idealWidth = 1280,
  int idealHeight = 720,
}) {
  return impl.captureImageWithWebCamera(
    context,
    preferRearCamera: preferRearCamera,
    maxDimension: maxDimension,
    preferPng: preferPng,
    idealWidth: idealWidth,
    idealHeight: idealHeight,
  );
}

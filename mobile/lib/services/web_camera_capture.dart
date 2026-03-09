import 'package:flutter/material.dart';

import 'web_camera_capture_stub.dart'
    if (dart.library.html) 'web_camera_capture_web.dart' as impl;

Future<String?> captureImageWithWebCamera(
  BuildContext context, {
  bool preferRearCamera = true,
}) {
  return impl.captureImageWithWebCamera(
    context,
    preferRearCamera: preferRearCamera,
  );
}

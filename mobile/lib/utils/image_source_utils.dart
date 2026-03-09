import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

Future<String> normalizePickedImageSource(XFile file) async {
  if (!kIsWeb) {
    return file.path;
  }

  final bytes = await file.readAsBytes();
  final mimeType = _inferMimeType(file.name.isNotEmpty ? file.name : file.path);
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

bool isRemoteImageSource(String source) {
  return source.startsWith('http://') ||
      source.startsWith('https://') ||
      source.startsWith('/uploads/');
}

bool isBrowserObjectImageSource(String source) {
  return source.startsWith('blob:');
}

bool isInlineDataImageSource(String source) {
  return source.startsWith('data:image/');
}

bool isBrowserImageSource(String source) {
  return isRemoteImageSource(source) ||
      isBrowserObjectImageSource(source) ||
      isInlineDataImageSource(source);
}

Uint8List? decodeInlineDataImage(String source) {
  if (!isInlineDataImageSource(source)) {
    return null;
  }

  final commaIndex = source.indexOf(',');
  if (commaIndex == -1 || commaIndex == source.length - 1) {
    return null;
  }

  try {
    return base64Decode(source.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

String suggestedUploadFileName(String source, int index) {
  final extension = _inferExtension(source);
  return 'upload_$index.$extension';
}

String _inferMimeType(String source) {
  final extension = _inferExtension(source);

  switch (extension) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'bmp':
      return 'image/bmp';
    default:
      return 'image/jpeg';
  }
}

String _inferExtension(String source) {
  final normalized = source.toLowerCase();

  if (normalized.contains('.png') || normalized.startsWith('data:image/png')) {
    return 'png';
  }

  if (normalized.contains('.webp') ||
      normalized.startsWith('data:image/webp')) {
    return 'webp';
  }

  if (normalized.contains('.gif') || normalized.startsWith('data:image/gif')) {
    return 'gif';
  }

  if (normalized.contains('.bmp') || normalized.startsWith('data:image/bmp')) {
    return 'bmp';
  }

  return 'jpg';
}

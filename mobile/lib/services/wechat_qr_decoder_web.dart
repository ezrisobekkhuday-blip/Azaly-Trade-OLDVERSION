import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('azalyDecodeQrFromDataUrl')
external JSPromise<JSString?> _azalyDecodeQrFromDataUrl(JSString imageSource);

Future<String?> decodeWechatQrImage(String imageSource) async {
  final source = imageSource.trim();
  if (source.isEmpty) {
    return null;
  }

  if (!globalContext.has('azalyDecodeQrFromDataUrl')) {
    throw StateError('QR decoder helper is not loaded.');
  }

  final result = await _azalyDecodeQrFromDataUrl(source.toJS).toDart;
  final value = result?.toDart.trim() ?? '';
  return value.isEmpty ? null : value;
}

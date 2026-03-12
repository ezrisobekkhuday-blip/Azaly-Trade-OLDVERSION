import 'wechat_qr_decoder_stub.dart'
    if (dart.library.html) 'wechat_qr_decoder_web.dart' as impl;

Future<String?> decodeWechatQrImage(String imageSource) {
  return impl.decodeWechatQrImage(imageSource);
}

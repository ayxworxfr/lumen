import 'package:flutter/foundation.dart';

import 'android/android_avif_encoder.dart'
    if (dart.library.html) 'web/web_avif_encoder_stub.dart';
import 'avif_encoder.dart';
import 'ios/ios_avif_encoder.dart';

/// 根据当前平台返回对应的 AVIF 编码器实例
class EncoderFactory {
  const EncoderFactory._();

  static AvifEncoder create() {
    if (kIsWeb) throw UnsupportedError('AVIF encoding is not supported on web');
    if (defaultTargetPlatform == TargetPlatform.iOS)
      return const IosAvifEncoder();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidAvifEncoder();
    }
    throw UnsupportedError(
      'AVIF encoding is only supported on iOS and Android.',
    );
  }
}

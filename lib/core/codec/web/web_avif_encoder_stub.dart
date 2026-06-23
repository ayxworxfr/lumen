import 'dart:typed_data';

import '../avif_encoder.dart';

// Web 平台存根：AndroidAvifEncoder 在 web 上不可用
class AndroidAvifEncoder extends AvifEncoder {
  const AndroidAvifEncoder();

  @override
  bool get isSupported => false;

  @override
  Future<AvifEncodeResult> encode({
    required String sourcePath,
    required String outputPath,
    required int quality,
    required int speed,
    bool isLossless = false,
  }) {
    throw UnsupportedError('AVIF encoding is not supported on web');
  }

  static Future<Uint8List?> decode(String avifPath, {int maxSide = 0}) {
    throw UnsupportedError('AVIF decoding is not supported on web');
  }
}

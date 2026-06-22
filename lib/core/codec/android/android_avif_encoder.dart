import 'package:flutter/services.dart';

import '../avif_encoder.dart';

/// Android AVIF 编码器
///
/// 通过 MethodChannel 调用 Kotlin 侧 AvifEncoderChannel：
/// Kotlin 用 BitmapFactory 解码源图片，经 Bitmap.compress(AVIF) 编码（Android 12+）。
class AndroidAvifEncoder extends AvifEncoder {
  const AndroidAvifEncoder();

  static const _channel = MethodChannel('lumen/avif');

  @override
  bool get isSupported => true;

  @override
  Future<AvifEncodeResult> encode({
    required String sourcePath,
    required String outputPath,
    required int quality,
    required int speed,
    bool isLossless = false,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>('encode', {
      'sourcePath': sourcePath,
      'outputPath': outputPath,
      'quality': quality,
      'speed': speed,
      'lossless': isLossless,
    });

    if (result == null) {
      throw PlatformException(
        code: 'ENCODE_FAILED',
        message: 'Android encoder returned null result',
      );
    }

    return AvifEncodeResult(
      outputPath: result['outputPath'] as String,
      outputBytes: result['outputBytes'] as int,
    );
  }
}

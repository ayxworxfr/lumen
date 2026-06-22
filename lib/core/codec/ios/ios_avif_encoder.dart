import 'package:flutter/services.dart';

import '../avif_encoder.dart';

/// iOS AVIF 编码器
///
/// 通过 MethodChannel 调用 Swift 侧 AvifEncoderPlugin，
/// Swift 使用 ImageIO（CGImageDestination）完成编码。
/// iOS 16+ 系统原生支持 AVIF，无需额外依赖。
class IosAvifEncoder extends AvifEncoder {
  const IosAvifEncoder();

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
        message: 'iOS encoder returned null result',
      );
    }

    return AvifEncodeResult(
      outputPath: result['outputPath'] as String,
      outputBytes: result['outputBytes'] as int,
    );
  }
}

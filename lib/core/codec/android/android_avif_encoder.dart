import 'package:flutter/services.dart';

import '../avif_encoder.dart';

/// Android AVIF 编解码器
///
/// 通过 MethodChannel 调用 Kotlin 侧 AvifEncoderChannel：
/// - encode：BitmapFactory 解码源图片 → JNI libheif+libaom 编码为 AVIF
/// - decode：JNI libheif+dav1d 解码 AVIF → RGBA → Bitmap → JPEG 字节
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

  /// 解码 AVIF 文件，返回 JPEG 字节（可直接 Image.memory() 显示）。
  /// [maxSide] > 0 时缩小到 maxSide×maxSide 以内，0 表示原始尺寸。
  static Future<Uint8List?> decode(String avifPath, {int maxSide = 0}) async {
    final bytes = await _channel.invokeMethod<Uint8List>('decode', {
      'path': avifPath,
      'maxSide': maxSide,
    });
    return bytes;
  }
}

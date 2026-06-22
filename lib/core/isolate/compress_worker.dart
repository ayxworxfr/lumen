import '../codec/avif_encoder.dart';
import '../codec/encoder_factory.dart';

/// 压缩 Worker
///
/// 封装单次编码调用。编码器（MethodChannel/FFI）本身已在各平台异步执行，
/// 无需额外 isolate 包裹。后续若要引入 libavif FFI isolate 池，在此扩展。
class CompressWorker {
  CompressWorker({AvifEncoder? encoder}) : _encoder = encoder;

  AvifEncoder? _encoder;

  /// 执行单张图片编码
  Future<AvifEncodeResult> encode({
    required String sourcePath,
    required String outputPath,
    required int quality,
    required int speed,
    bool isLossless = false,
  }) {
    // 懒初始化：仅在首次编码时创建，web 上从不调用此方法
    _encoder ??= EncoderFactory.create();
    return _encoder!.encode(
      sourcePath: sourcePath,
      outputPath: outputPath,
      quality: quality,
      speed: speed,
      isLossless: isLossless,
    );
  }
}

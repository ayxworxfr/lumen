/// AVIF 编码结果
class AvifEncodeResult {
  const AvifEncodeResult({required this.outputPath, required this.outputBytes});

  final String outputPath;
  final int outputBytes;
}

/// AVIF 编码器抽象接口
///
/// iOS 实现通过 MethodChannel 调用 ImageIO；
/// Android 实现通过 FFI 调用 libavif；
/// FakeAvifEncoder 用于测试和 Android MVP 阶段。
abstract class AvifEncoder {
  const AvifEncoder();

  /// 将 [sourcePath] 编码为 AVIF，输出到 [outputPath]。
  ///
  /// [quality] AVIF 质量参数（0-100，100 为 lossless）
  /// [speed]   编码速度（0=最慢最好，10=最快）
  /// [isLossless] 是否使用无损模式（true 时忽略 quality）
  Future<AvifEncodeResult> encode({
    required String sourcePath,
    required String outputPath,
    required int quality,
    required int speed,
    bool isLossless = false,
  });

  /// 是否支持当前平台
  bool get isSupported;
}

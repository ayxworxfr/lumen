import '../../library/models/photo_asset.dart';

/// 节省空间估算器
///
/// 根据原图格式和 balanced 预设估算 AVIF 压缩后的节省字节数。
/// 这是粗略估算，实际结果取决于图片内容。
class SavingsEstimator {
  const SavingsEstimator._();

  /// 各格式在 balanced 预设下的预期压缩率（输出/输入）
  static const Map<ImageFormat, double> _compressionRatios = {
    ImageFormat.jpeg: 0.45,
    ImageFormat.png: 0.35,
    ImageFormat.heic: 0.60,
    ImageFormat.webp: 0.55,
    ImageFormat.avif: 1.0,
    ImageFormat.unknown: 0.60,
  };

  /// 估算单张图片可节省的字节数
  static int estimateSavingsForAsset(PhotoAsset asset) {
    if (!asset.format.isCompressible) return 0;
    final ratio = _compressionRatios[asset.format] ?? 0.60;
    final estimatedOutput = (asset.byteSize * ratio).round();
    final savings = asset.byteSize - estimatedOutput;
    return savings > 0 ? savings : 0;
  }

  /// 估算批量图片的总节省字节数
  static int estimateTotalSavings(List<PhotoAsset> assets) {
    return assets.fold(0, (sum, a) => sum + estimateSavingsForAsset(a));
  }

  /// 格式化显示（GB/MB/KB）
  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_asset.freezed.dart';
part 'photo_asset.g.dart';

/// 支持的图片格式
enum ImageFormat {
  jpeg,
  png,
  heic,
  webp,
  avif,
  unknown;

  /// 从 MIME type 推断格式
  static ImageFormat fromMimeType(String? mimeType) {
    switch (mimeType?.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return ImageFormat.jpeg;
      case 'image/png':
        return ImageFormat.png;
      case 'image/heic':
      case 'image/heif':
        return ImageFormat.heic;
      case 'image/webp':
        return ImageFormat.webp;
      case 'image/avif':
        return ImageFormat.avif;
      default:
        return ImageFormat.unknown;
    }
  }

  /// AVIF 压缩对该格式是否有收益（已是 AVIF 或 unknown 跳过）
  bool get isCompressible =>
      this != ImageFormat.avif && this != ImageFormat.unknown;
}

/// 相册中的单张图片资源
@freezed
class PhotoAsset with _$PhotoAsset {
  const factory PhotoAsset({
    /// photo_manager AssetEntity.id
    required String id,
    required int byteSize,
    required ImageFormat format,
    required int width,
    required int height,
    required DateTime createdAt,

    /// App 沙盒内的临时缓存路径（按需获取，可为 null）
    String? path,
    String? mimeType,
  }) = _PhotoAsset;
  const PhotoAsset._();

  factory PhotoAsset.fromJson(Map<String, dynamic> json) =>
      _$PhotoAssetFromJson(json);

  /// 估算 AVIF 压缩后节省的字节数（balanced 预设下约 50% 压缩率）
  int get estimatedSavings => (byteSize * 0.5).round();

  /// 以 MB 为单位显示
  String get displaySize {
    if (byteSize < 1024 * 1024) {
      return '${(byteSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

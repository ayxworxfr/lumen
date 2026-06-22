import '../platform/platform_file.dart' as pf;

/// 跨平台图片解码工具（复用系统能力）
///
/// 不负责实际解码逻辑——系统 codec 和 photo_manager 已经处理好了。
/// 此类提供格式检测与文件有效性校验。
class ImageDecoder {
  const ImageDecoder._();

  static const _supportedMimes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/heic',
    'image/heif',
    'image/webp',
    'image/avif',
  };

  /// 检查 MIME type 是否被支持（返回 false 时应拒绝入队）
  static bool isMimeTypeSupported(String? mimeType) {
    if (mimeType == null) return false;
    return _supportedMimes.contains(mimeType.toLowerCase());
  }

  /// 检查文件是否存在且可读
  static Future<bool> isFileReadable(String path) => pf.isFileReadable(path);
}

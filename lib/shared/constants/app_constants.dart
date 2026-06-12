/// 应用常量定义
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = 'Lumen';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 分页默认大小
  static const int defaultPageSize = 20;

  /// 默认动画时长
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// 防抖延迟（毫秒）
  static const int debounceDelay = 500;

  /// 节流间隔（毫秒）
  static const int throttleInterval = 1000;

  /// 图片最大上传大小（字节）
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  /// 支持的图片格式
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
}

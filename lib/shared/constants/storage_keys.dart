/// 存储 Key 常量定义
class StorageKeys {
  StorageKeys._();

  // ==================== SharedPreferences Keys ====================
  /// 主题模式
  static const String themeMode = 'theme_mode';

  /// 语言设置
  static const String language = 'language';

  /// 是否首次启动
  static const String isFirstLaunch = 'is_first_launch';

  /// 是否同意隐私政策
  static const String privacyAgreed = 'privacy_agreed';

  /// 是否有活跃会话（由 AuthService 在登录/登出时同步更新，用于路由守卫同步检查）
  static const String sessionActive = 'session_active';

  // ==================== SharedPreferences Keys ====================
  /// 默认压缩预设
  static const String defaultCompressPreset = 'default_compress_preset';

  // ==================== Hive Box Names ====================
  /// 用户信息 Box
  static const String userBox = 'user_box';

  /// 缓存数据 Box
  static const String cacheBox = 'cache_box';

  /// 设置 Box
  static const String settingsBox = 'settings_box';

  /// 压缩记录 Box
  static const String compressedRecordsBox = 'compressed_records';

  /// 待执行队列 Box（跨重启续跑）
  static const String pendingJobsBox = 'pending_jobs';

  // ==================== Hive Keys ====================
  /// 当前用户
  static const String currentUser = 'current_user';

  // ==================== Secure Storage Keys ====================
  /// Access Token（存平台安全区）
  static const String accessToken = 'access_token';

  /// Refresh Token（存平台安全区）
  static const String refreshToken = 'refresh_token';
}

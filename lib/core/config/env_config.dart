import 'package:flutter/foundation.dart';

/// 环境配置
///
/// 优先从编译时 `--dart-define` 或 `--dart-define-from-file` 注入的值读取，
/// 缺省时根据 Flutter 构建模式（debug / profile / release）推断。
///
/// 推荐用法（开发）：
///   flutter run --dart-define-from-file=config/dev.json
///
/// 推荐用法（CI/CD）：
///   flutter build apk \
///     --dart-define=APP_ENV=production \
///     --dart-define=API_BASE_URL=https://api.example.com/api
class EnvConfig {
  EnvConfig._();

  // ─── Compile-time dart-define values ────────────────────

  static const _envName = String.fromEnvironment('APP_ENV');
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _wsUrl = String.fromEnvironment('WS_URL');
  static const _staticUrl = String.fromEnvironment('STATIC_URL');

  // ─── Derived environment ─────────────────────────────────

  static Environment get current {
    if (_envName.isNotEmpty) {
      return switch (_envName) {
        'production' => Environment.production,
        'staging' => Environment.staging,
        _ => Environment.development,
      };
    }
    // 未注入时根据 Flutter 构建模式推断
    if (kReleaseMode) return Environment.production;
    if (kProfileMode) return Environment.staging;
    return Environment.development;
  }

  static String get appEnv => current.name;

  static bool get isDev => current == Environment.development;
  static bool get isStaging => current == Environment.staging;
  static bool get isProd => current == Environment.production;

  /// Mock 数据（仅开发环境启用）
  static bool get enableMock => isDev;

  /// 日志输出（非生产环境启用）
  static bool get enableLog => !isProd;

  static bool get showDebugInfo => isDev;

  // ─── URLs ────────────────────────────────────────────────

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    return switch (current) {
      Environment.development => 'http://localhost:3000/api',
      Environment.staging => 'https://staging-api.example.com/api',
      Environment.production => 'https://api.example.com/api',
    };
  }

  static String get wsUrl {
    if (_wsUrl.isNotEmpty) return _wsUrl;
    return switch (current) {
      Environment.development => 'ws://localhost:3000/ws',
      Environment.staging => 'wss://staging-api.example.com/ws',
      Environment.production => 'wss://api.example.com/ws',
    };
  }

  static String get staticUrl {
    if (_staticUrl.isNotEmpty) return _staticUrl;
    return switch (current) {
      Environment.development => 'http://localhost:3000/static',
      Environment.staging => 'https://staging-static.example.com',
      Environment.production => 'https://static.example.com',
    };
  }

  // ─── Timeouts & retries ──────────────────────────────────

  /// 请求超时（毫秒）
  static int get requestTimeout => switch (current) {
    Environment.development => 30000,
    Environment.staging => 15000,
    Environment.production => 10000,
  };

  static int get apiTimeout => requestTimeout;
  static const String apiVersion = 'v1';

  /// 最大重试次数（开发环境不重试，方便调试）
  static int get maxRetries => switch (current) {
    Environment.development => 0,
    Environment.staging => 2,
    Environment.production => 3,
  };
}

/// 环境枚举
enum Environment { development, staging, production }

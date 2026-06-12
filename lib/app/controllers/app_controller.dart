import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';
import '../../shared/constants/storage_keys.dart';

/// 全局应用控制器
///
/// 管理应用级别的响应式状态：主题模式、语言。
/// 由 main.dart 在 runApp 前注册为 permanent 单例。
class AppController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final themeMode = ThemeMode.system.obs;

  /// null 表示跟随系统语言
  final locale = Rxn<Locale>();

  @override
  void onInit() {
    super.onInit();
    _restoreTheme();
    _restoreLocale();
  }

  // ─── Theme ───────────────────────────────────────────────

  void changeTheme(ThemeMode mode) {
    themeMode.value = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    _storage.setString(StorageKeys.themeMode, value);
  }

  void _restoreTheme() {
    final stored = _storage.getString(StorageKeys.themeMode);
    themeMode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  // ─── Locale ──────────────────────────────────────────────

  void changeLocale(Locale newLocale) {
    locale.value = newLocale;
    _storage.setString(
      StorageKeys.language,
      '${newLocale.languageCode}_${newLocale.countryCode}',
    );
  }

  void resetToSystemLocale() {
    locale.value = null;
    _storage.remove(StorageKeys.language);
  }

  bool get isChinese => (locale.value ?? _deviceLocale)?.languageCode == 'zh';

  String get currentLanguageName => isChinese ? '中文' : 'English';

  void _restoreLocale() {
    final stored = _storage.getString(StorageKeys.language);
    if (stored == null) return;

    final parts = stored.split('_');
    if (parts.length >= 2) {
      locale.value = Locale(parts[0], parts[1]);
    }
  }

  Locale? get _deviceLocale {
    final deviceLocales = PlatformDispatcher.instance.locales;
    return deviceLocales.isNotEmpty ? deviceLocales.first : null;
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hive_boxes.dart';

/// 存储服务
///
/// 提供统一的本地存储接口，支持：
/// - SharedPreferences：简单的键值对存储（非敏感数据）
/// - flutter_secure_storage：平台安全区（Android Keystore / iOS Keychain）
///   注意：Web 端降级为 localStorage，与 SharedPreferences 安全级别等价。
/// - Hive：复杂对象存储
class StorageService extends GetxService {
  late SharedPreferences _prefs;

  // encryptedSharedPreferences: true 在 Android 上使用 EncryptedSharedPreferences
  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 初始化存储服务
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    await HiveBoxes.init();
    return this;
  }

  // ==================== SharedPreferences 操作 ====================

  /// 获取字符串
  String? getString(String key) => _prefs.getString(key);

  /// 设置字符串
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  /// 获取整数
  int? getInt(String key) => _prefs.getInt(key);

  /// 设置整数
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  /// 获取双精度浮点数
  double? getDouble(String key) => _prefs.getDouble(key);

  /// 设置双精度浮点数
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  /// 获取布尔值
  bool? getBool(String key) => _prefs.getBool(key);

  /// 设置布尔值
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  /// 获取字符串列表
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  /// 设置字符串列表
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  /// 是否包含 key
  bool containsKey(String key) => _prefs.containsKey(key);

  /// 移除指定 key
  Future<bool> remove(String key) => _prefs.remove(key);

  /// 清空所有数据
  Future<bool> clear() => _prefs.clear();

  // ==================== 安全存储操作 ====================

  /// 将字符串写入平台安全区
  Future<void> setSecureString(String key, String value) =>
      _secure.write(key: key, value: value);

  /// 从平台安全区读取字符串
  Future<String?> getSecureString(String key) => _secure.read(key: key);

  /// 删除平台安全区中的 key
  Future<void> removeSecure(String key) => _secure.delete(key: key);

  // ==================== Hive 操作 ====================

  /// 从 Hive 获取数据
  T? getFromHive<T>(HiveBox boxName, String key) {
    dynamic value;
    switch (boxName) {
      case HiveBox.user:
        value = HiveBoxes.userBox.get(key);
      case HiveBox.cache:
        value = HiveBoxes.cacheBox.get(key);
      case HiveBox.settings:
        value = HiveBoxes.settingsBox.get(key);
    }
    if (value == null) return null;
    // Hive on web returns LinkedMap<dynamic, dynamic> for stored Maps;
    // normalize to Map<String, dynamic> to avoid type cast failures.
    if (value is Map && value is! Map<String, dynamic>) {
      value = Map<String, dynamic>.from(value);
    }
    return value as T?;
  }

  /// 保存数据到 Hive
  Future<void> saveToHive<T>(HiveBox boxName, String key, T value) async {
    switch (boxName) {
      case HiveBox.user:
        await HiveBoxes.userBox.put(key, value);
      case HiveBox.cache:
        await HiveBoxes.cacheBox.put(key, value);
      case HiveBox.settings:
        await HiveBoxes.settingsBox.put(key, value);
    }
  }

  /// 从 Hive 删除数据
  Future<void> deleteFromHive(HiveBox boxName, String key) async {
    switch (boxName) {
      case HiveBox.user:
        await HiveBoxes.userBox.delete(key);
      case HiveBox.cache:
        await HiveBoxes.cacheBox.delete(key);
      case HiveBox.settings:
        await HiveBoxes.settingsBox.delete(key);
    }
  }

  /// 清空指定 Hive Box
  Future<void> clearHiveBox(HiveBox boxName) async {
    switch (boxName) {
      case HiveBox.user:
        await HiveBoxes.userBox.clear();
      case HiveBox.cache:
        await HiveBoxes.cacheBox.clear();
      case HiveBox.settings:
        await HiveBoxes.settingsBox.clear();
    }
  }

  // ==================== 便捷方法 ====================

  /// 获取用户数据
  T? getUserData<T>(String key) => getFromHive<T>(HiveBox.user, key);

  /// 保存用户数据
  Future<void> saveUserData<T>(String key, T value) =>
      saveToHive(HiveBox.user, key, value);

  /// 删除用户数据
  Future<void> deleteUserData(String key) => deleteFromHive(HiveBox.user, key);

  /// 获取缓存数据
  T? getCacheData<T>(String key) => getFromHive<T>(HiveBox.cache, key);

  /// 保存缓存数据
  Future<void> saveCacheData<T>(String key, T value) =>
      saveToHive(HiveBox.cache, key, value);

  /// 删除缓存数据
  Future<void> deleteCacheData(String key) =>
      deleteFromHive(HiveBox.cache, key);

  /// 清空所有缓存
  Future<void> clearCache() => clearHiveBox(HiveBox.cache);
}

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/constants/storage_keys.dart';

/// 枚举：代表各个 Hive Box 的身份，避免散落的字符串字面量
enum HiveBox { user, cache, settings, compressedRecords, pendingJobs }

/// Hive Box 管理类
///
/// 统一管理所有 Hive Box 的创建和访问
class HiveBoxes {
  HiveBoxes._();

  static Box<dynamic>? _userBox;
  static Box<dynamic>? _cacheBox;
  static Box<dynamic>? _settingsBox;
  static Box<dynamic>? _compressedRecordsBox;
  static Box<dynamic>? _pendingJobsBox;

  /// 用户信息 Box
  static Box<dynamic> get userBox => _userBox!;

  /// 缓存数据 Box
  static Box<dynamic> get cacheBox => _cacheBox!;

  /// 设置 Box
  static Box<dynamic> get settingsBox => _settingsBox!;

  /// 压缩记录 Box
  static Box<dynamic> get compressedRecordsBox => _compressedRecordsBox!;

  /// 待执行队列 Box
  static Box<dynamic> get pendingJobsBox => _pendingJobsBox!;

  /// 初始化所有 Box
  static Future<void> init() async {
    await Hive.initFlutter();

    // 注册自定义 TypeAdapter（如果有的话）
    // Hive.registerAdapter(UserModelAdapter());

    // 打开所有需要的 Box
    _userBox = await Hive.openBox(StorageKeys.userBox);
    _cacheBox = await Hive.openBox(StorageKeys.cacheBox);
    _settingsBox = await Hive.openBox(StorageKeys.settingsBox);
    _compressedRecordsBox = await Hive.openBox(
      StorageKeys.compressedRecordsBox,
    );
    _pendingJobsBox = await Hive.openBox(StorageKeys.pendingJobsBox);
  }

  /// 关闭所有 Box
  static Future<void> close() async {
    await _userBox?.close();
    await _cacheBox?.close();
    await _settingsBox?.close();
    await _compressedRecordsBox?.close();
    await _pendingJobsBox?.close();
  }

  /// 测试专用：用已打开的 Box 替换静态引用，跳过 initFlutter / path_provider
  @visibleForTesting
  static void initForTest({
    required Box<dynamic> pendingJobs,
    required Box<dynamic> compressedRecords,
  }) {
    _pendingJobsBox = pendingJobs;
    _compressedRecordsBox = compressedRecords;
  }

  /// 清除所有数据
  static Future<void> clearAll() async {
    await _userBox?.clear();
    await _cacheBox?.clear();
    await _settingsBox?.clear();
    await _compressedRecordsBox?.clear();
    await _pendingJobsBox?.clear();
  }
}

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// App 沙盒文件管理
///
/// 压缩输出路径格式：AppDocs/compressed/yyyyMM/id.avif
/// 排除 iCloud 备份（通过 URLResourceKey.isExcludedFromBackup 在 iOS 设置）。
class FileStore {
  FileStore._();

  static final FileStore instance = FileStore._();

  String? _baseDir;

  /// 初始化基础目录
  Future<void> init() async {
    final docDir = await getApplicationDocumentsDirectory();
    _baseDir = '${docDir.path}/compressed';
    await Directory(_baseDir!).create(recursive: true);
  }

  /// 为指定 ID 生成输出文件路径（格式：base/yyyyMM/id.avif）
  Future<String> outputPathForId(String id) async {
    final now = DateTime.now();
    final monthDir =
        '${_baseDir!}/${now.year}${now.month.toString().padLeft(2, '0')}';
    await Directory(monthDir).create(recursive: true);
    return '$monthDir/$id.avif';
  }

  /// 删除指定路径的文件（静默忽略不存在的文件）
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {
      // 文件不存在或已删除，忽略
    }
  }

  /// 获取 compressed 目录总大小（字节）
  Future<int> totalCompressedSize() async {
    if (_baseDir == null) return 0;
    final dir = Directory(_baseDir!);
    if (!dir.existsSync()) return 0;

    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // 忽略无法读取的文件
        }
      }
    }
    return total;
  }
}

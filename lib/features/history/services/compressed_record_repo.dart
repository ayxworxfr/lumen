import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import '../models/compressed_record.dart';

/// 压缩记录仓库
///
/// 使用 Hive compressed_records box 持久化，以 JSON Map 形式存储。
class CompressedRecordRepo extends GetxService {
  Box<dynamic> get _box => HiveBoxes.compressedRecordsBox;

  /// 保存记录
  Future<void> save(CompressedRecord record) async {
    await _box.put(record.id, record.toJson());
  }

  /// 加载全部记录，按压缩时间倒序
  List<CompressedRecord> loadAll() {
    final records = <CompressedRecord>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        records.add(CompressedRecord.fromJson(map));
      } catch (_) {
        // 忽略损坏的记录
      }
    }
    records.sort((a, b) => b.compressedAt.compareTo(a.compressedAt));
    return records;
  }

  /// 按 ID 查询单条记录
  CompressedRecord? findById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      return CompressedRecord.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// 更新记录（原地替换）
  Future<void> update(CompressedRecord record) => save(record);

  /// 删除记录
  Future<void> delete(String id) => _box.delete(id);

  /// 清空全部记录
  Future<void> clearAll() => _box.clear();
}

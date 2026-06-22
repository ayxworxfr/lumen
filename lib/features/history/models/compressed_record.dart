import 'package:freezed_annotation/freezed_annotation.dart';

import '../../compress/models/compress_job.dart';
import '../../library/models/photo_asset.dart';

part 'compressed_record.freezed.dart';
part 'compressed_record.g.dart';

/// 已完成的压缩记录（持久化到 Hive compressed_records box 中，以 JSON 形式存储）
@freezed
class CompressedRecord with _$CompressedRecord {
  const factory CompressedRecord({
    required String id,

    /// 原图 photo_manager 资源 ID
    required String sourceAssetId,

    /// App 沙盒内 .avif 文件路径
    required String outputPath,
    required int originalBytes,
    required int compressedBytes,
    required CompressPreset preset,
    required ImageFormat originalFormat,
    required DateTime compressedAt,

    /// 用户是否已删除原图（释放空间）
    @Default(false) bool originalDeleted,
  }) = _CompressedRecord;
  const CompressedRecord._();

  factory CompressedRecord.fromJson(Map<String, dynamic> json) =>
      _$CompressedRecordFromJson(json);

  /// 节省字节数
  int get savedBytes => originalBytes - compressedBytes;

  /// 压缩率（压缩后 / 压缩前）
  double get compressionRatio => compressedBytes / originalBytes;

  /// 节省百分比（0-100）
  double get savedPercent => (1 - compressionRatio) * 100;

  String get displaySavedPercent => '${savedPercent.toStringAsFixed(0)}%';

  String get displayOriginalSize => _formatBytes(originalBytes);
  String get displayCompressedSize => _formatBytes(compressedBytes);
  String get displaySavedSize => _formatBytes(savedBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

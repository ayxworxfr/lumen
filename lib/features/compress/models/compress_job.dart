import 'package:freezed_annotation/freezed_annotation.dart';

import '../../library/models/photo_asset.dart';

part 'compress_job.freezed.dart';
part 'compress_job.g.dart';

/// 压缩质量预设
enum CompressPreset {
  /// AVIF Q70 + speed 6，最小体积
  smaller,

  /// AVIF Q85 + speed 6，默认平衡
  balanced,

  /// AVIF Q92 + speed 4，更高质量
  higherQuality,

  /// AVIF lossless（高级模式）
  lossless;

  /// AVIF 质量参数（0-100）
  int get quality {
    switch (this) {
      case CompressPreset.smaller:
        return 70;
      case CompressPreset.balanced:
        return 85;
      case CompressPreset.higherQuality:
        return 92;
      case CompressPreset.lossless:
        return 100;
    }
  }

  /// 编码速度（0=最慢最好，10=最快最差）
  int get speed {
    switch (this) {
      case CompressPreset.smaller:
        return 6;
      case CompressPreset.balanced:
        return 6;
      case CompressPreset.higherQuality:
        return 4;
      case CompressPreset.lossless:
        return 6;
    }
  }

  bool get isLossless => this == CompressPreset.lossless;
}

/// 压缩任务状态
enum JobStatus { pending, running, done, failed, canceled }

/// 单张图片的压缩任务
@freezed
class CompressJob with _$CompressJob {
  const factory CompressJob({
    required String id,
    required PhotoAsset source,
    required CompressPreset preset,
    required JobStatus status,
    required DateTime queuedAt,
    @Default(0.0) double progress,
    int? outputBytes,
    String? outputPath,
    String? errorMessage,
    DateTime? finishedAt,
  }) = _CompressJob;
  const CompressJob._();

  factory CompressJob.fromJson(Map<String, dynamic> json) =>
      _$CompressJobFromJson(json);

  bool get isFinished =>
      status == JobStatus.done ||
      status == JobStatus.failed ||
      status == JobStatus.canceled;

  /// 节省字节数（仅 done 状态有效）
  int? get savedBytes {
    if (status != JobStatus.done || outputBytes == null) return null;
    return source.byteSize - outputBytes!;
  }

  /// 压缩率（仅 done 状态有效）
  double? get compressionRatio {
    if (status != JobStatus.done || outputBytes == null) return null;
    return outputBytes! / source.byteSize;
  }
}

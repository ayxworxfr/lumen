// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compress_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompressJobImpl _$$CompressJobImplFromJson(Map<String, dynamic> json) =>
    _$CompressJobImpl(
      id: json['id'] as String,
      source: PhotoAsset.fromJson(json['source'] as Map<String, dynamic>),
      preset: $enumDecode(_$CompressPresetEnumMap, json['preset']),
      status: $enumDecode(_$JobStatusEnumMap, json['status']),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      outputBytes: (json['outputBytes'] as num?)?.toInt(),
      outputPath: json['outputPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.parse(json['finishedAt'] as String),
    );

Map<String, dynamic> _$$CompressJobImplToJson(_$CompressJobImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'preset': _$CompressPresetEnumMap[instance.preset]!,
      'status': _$JobStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'outputBytes': instance.outputBytes,
      'outputPath': instance.outputPath,
      'errorMessage': instance.errorMessage,
      'queuedAt': instance.queuedAt.toIso8601String(),
      'finishedAt': instance.finishedAt?.toIso8601String(),
    };

const _$CompressPresetEnumMap = {
  CompressPreset.smaller: 'smaller',
  CompressPreset.balanced: 'balanced',
  CompressPreset.higherQuality: 'higherQuality',
  CompressPreset.lossless: 'lossless',
};

const _$JobStatusEnumMap = {
  JobStatus.pending: 'pending',
  JobStatus.running: 'running',
  JobStatus.done: 'done',
  JobStatus.failed: 'failed',
  JobStatus.canceled: 'canceled',
};

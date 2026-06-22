// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compressed_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompressedRecordImpl _$$CompressedRecordImplFromJson(
  Map<String, dynamic> json,
) => _$CompressedRecordImpl(
  id: json['id'] as String,
  sourceAssetId: json['sourceAssetId'] as String,
  outputPath: json['outputPath'] as String,
  originalBytes: (json['originalBytes'] as num).toInt(),
  compressedBytes: (json['compressedBytes'] as num).toInt(),
  preset: $enumDecode(_$CompressPresetEnumMap, json['preset']),
  originalFormat: $enumDecode(_$ImageFormatEnumMap, json['originalFormat']),
  compressedAt: DateTime.parse(json['compressedAt'] as String),
  originalDeleted: json['originalDeleted'] as bool? ?? false,
);

Map<String, dynamic> _$$CompressedRecordImplToJson(
  _$CompressedRecordImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'sourceAssetId': instance.sourceAssetId,
  'outputPath': instance.outputPath,
  'originalBytes': instance.originalBytes,
  'compressedBytes': instance.compressedBytes,
  'preset': _$CompressPresetEnumMap[instance.preset]!,
  'originalFormat': _$ImageFormatEnumMap[instance.originalFormat]!,
  'compressedAt': instance.compressedAt.toIso8601String(),
  'originalDeleted': instance.originalDeleted,
};

const _$CompressPresetEnumMap = {
  CompressPreset.smaller: 'smaller',
  CompressPreset.balanced: 'balanced',
  CompressPreset.higherQuality: 'higherQuality',
  CompressPreset.lossless: 'lossless',
};

const _$ImageFormatEnumMap = {
  ImageFormat.jpeg: 'jpeg',
  ImageFormat.png: 'png',
  ImageFormat.heic: 'heic',
  ImageFormat.webp: 'webp',
  ImageFormat.avif: 'avif',
  ImageFormat.unknown: 'unknown',
};

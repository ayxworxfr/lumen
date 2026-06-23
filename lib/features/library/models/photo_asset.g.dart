// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoAssetImpl _$$PhotoAssetImplFromJson(Map<String, dynamic> json) =>
    _$PhotoAssetImpl(
      id: json['id'] as String,
      byteSize: (json['byteSize'] as num).toInt(),
      format: $enumDecode(_$ImageFormatEnumMap, json['format']),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      path: json['path'] as String?,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$$PhotoAssetImplToJson(_$PhotoAssetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'byteSize': instance.byteSize,
      'format': _$ImageFormatEnumMap[instance.format]!,
      'width': instance.width,
      'height': instance.height,
      'createdAt': instance.createdAt.toIso8601String(),
      'path': instance.path,
      'mimeType': instance.mimeType,
    };

const _$ImageFormatEnumMap = {
  ImageFormat.jpeg: 'jpeg',
  ImageFormat.png: 'png',
  ImageFormat.heic: 'heic',
  ImageFormat.webp: 'webp',
  ImageFormat.avif: 'avif',
  ImageFormat.unknown: 'unknown',
};

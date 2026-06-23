// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'photo_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PhotoAsset _$PhotoAssetFromJson(Map<String, dynamic> json) {
  return _PhotoAsset.fromJson(json);
}

/// @nodoc
mixin _$PhotoAsset {
  /// photo_manager AssetEntity.id
  String get id => throw _privateConstructorUsedError;
  int get byteSize => throw _privateConstructorUsedError;
  ImageFormat get format => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// App 沙盒内的临时缓存路径（按需获取，可为 null）
  String? get path => throw _privateConstructorUsedError;
  String? get mimeType => throw _privateConstructorUsedError;

  /// Serializes this PhotoAsset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PhotoAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PhotoAssetCopyWith<PhotoAsset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PhotoAssetCopyWith<$Res> {
  factory $PhotoAssetCopyWith(
    PhotoAsset value,
    $Res Function(PhotoAsset) then,
  ) = _$PhotoAssetCopyWithImpl<$Res, PhotoAsset>;
  @useResult
  $Res call({
    String id,
    int byteSize,
    ImageFormat format,
    int width,
    int height,
    DateTime createdAt,
    String? path,
    String? mimeType,
  });
}

/// @nodoc
class _$PhotoAssetCopyWithImpl<$Res, $Val extends PhotoAsset>
    implements $PhotoAssetCopyWith<$Res> {
  _$PhotoAssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PhotoAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? byteSize = null,
    Object? format = null,
    Object? width = null,
    Object? height = null,
    Object? createdAt = null,
    Object? path = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            byteSize: null == byteSize
                ? _value.byteSize
                : byteSize // ignore: cast_nullable_to_non_nullable
                      as int,
            format: null == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as ImageFormat,
            width: null == width
                ? _value.width
                : width // ignore: cast_nullable_to_non_nullable
                      as int,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            path: freezed == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String?,
            mimeType: freezed == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PhotoAssetImplCopyWith<$Res>
    implements $PhotoAssetCopyWith<$Res> {
  factory _$$PhotoAssetImplCopyWith(
    _$PhotoAssetImpl value,
    $Res Function(_$PhotoAssetImpl) then,
  ) = __$$PhotoAssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int byteSize,
    ImageFormat format,
    int width,
    int height,
    DateTime createdAt,
    String? path,
    String? mimeType,
  });
}

/// @nodoc
class __$$PhotoAssetImplCopyWithImpl<$Res>
    extends _$PhotoAssetCopyWithImpl<$Res, _$PhotoAssetImpl>
    implements _$$PhotoAssetImplCopyWith<$Res> {
  __$$PhotoAssetImplCopyWithImpl(
    _$PhotoAssetImpl _value,
    $Res Function(_$PhotoAssetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PhotoAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? byteSize = null,
    Object? format = null,
    Object? width = null,
    Object? height = null,
    Object? createdAt = null,
    Object? path = freezed,
    Object? mimeType = freezed,
  }) {
    return _then(
      _$PhotoAssetImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        byteSize: null == byteSize
            ? _value.byteSize
            : byteSize // ignore: cast_nullable_to_non_nullable
                  as int,
        format: null == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as ImageFormat,
        width: null == width
            ? _value.width
            : width // ignore: cast_nullable_to_non_nullable
                  as int,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        path: freezed == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String?,
        mimeType: freezed == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PhotoAssetImpl extends _PhotoAsset {
  const _$PhotoAssetImpl({
    required this.id,
    required this.byteSize,
    required this.format,
    required this.width,
    required this.height,
    required this.createdAt,
    this.path,
    this.mimeType,
  }) : super._();

  factory _$PhotoAssetImpl.fromJson(Map<String, dynamic> json) =>
      _$$PhotoAssetImplFromJson(json);

  /// photo_manager AssetEntity.id
  @override
  final String id;
  @override
  final int byteSize;
  @override
  final ImageFormat format;
  @override
  final int width;
  @override
  final int height;
  @override
  final DateTime createdAt;

  /// App 沙盒内的临时缓存路径（按需获取，可为 null）
  @override
  final String? path;
  @override
  final String? mimeType;

  @override
  String toString() {
    return 'PhotoAsset(id: $id, byteSize: $byteSize, format: $format, width: $width, height: $height, createdAt: $createdAt, path: $path, mimeType: $mimeType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PhotoAssetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.byteSize, byteSize) ||
                other.byteSize == byteSize) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    byteSize,
    format,
    width,
    height,
    createdAt,
    path,
    mimeType,
  );

  /// Create a copy of PhotoAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PhotoAssetImplCopyWith<_$PhotoAssetImpl> get copyWith =>
      __$$PhotoAssetImplCopyWithImpl<_$PhotoAssetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PhotoAssetImplToJson(this);
  }
}

abstract class _PhotoAsset extends PhotoAsset {
  const factory _PhotoAsset({
    required final String id,
    required final int byteSize,
    required final ImageFormat format,
    required final int width,
    required final int height,
    required final DateTime createdAt,
    final String? path,
    final String? mimeType,
  }) = _$PhotoAssetImpl;
  const _PhotoAsset._() : super._();

  factory _PhotoAsset.fromJson(Map<String, dynamic> json) =
      _$PhotoAssetImpl.fromJson;

  /// photo_manager AssetEntity.id
  @override
  String get id;
  @override
  int get byteSize;
  @override
  ImageFormat get format;
  @override
  int get width;
  @override
  int get height;
  @override
  DateTime get createdAt;

  /// App 沙盒内的临时缓存路径（按需获取，可为 null）
  @override
  String? get path;
  @override
  String? get mimeType;

  /// Create a copy of PhotoAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PhotoAssetImplCopyWith<_$PhotoAssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

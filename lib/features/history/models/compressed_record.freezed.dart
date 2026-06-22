// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compressed_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CompressedRecord _$CompressedRecordFromJson(Map<String, dynamic> json) {
  return _CompressedRecord.fromJson(json);
}

/// @nodoc
mixin _$CompressedRecord {
  String get id => throw _privateConstructorUsedError;

  /// 原图 photo_manager 资源 ID
  String get sourceAssetId => throw _privateConstructorUsedError;

  /// App 沙盒内 .avif 文件路径
  String get outputPath => throw _privateConstructorUsedError;
  int get originalBytes => throw _privateConstructorUsedError;
  int get compressedBytes => throw _privateConstructorUsedError;
  CompressPreset get preset => throw _privateConstructorUsedError;
  ImageFormat get originalFormat => throw _privateConstructorUsedError;
  DateTime get compressedAt => throw _privateConstructorUsedError;

  /// 用户是否已删除原图（释放空间）
  bool get originalDeleted => throw _privateConstructorUsedError;

  /// Serializes this CompressedRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompressedRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompressedRecordCopyWith<CompressedRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompressedRecordCopyWith<$Res> {
  factory $CompressedRecordCopyWith(
    CompressedRecord value,
    $Res Function(CompressedRecord) then,
  ) = _$CompressedRecordCopyWithImpl<$Res, CompressedRecord>;
  @useResult
  $Res call({
    String id,
    String sourceAssetId,
    String outputPath,
    int originalBytes,
    int compressedBytes,
    CompressPreset preset,
    ImageFormat originalFormat,
    DateTime compressedAt,
    bool originalDeleted,
  });
}

/// @nodoc
class _$CompressedRecordCopyWithImpl<$Res, $Val extends CompressedRecord>
    implements $CompressedRecordCopyWith<$Res> {
  _$CompressedRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompressedRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceAssetId = null,
    Object? outputPath = null,
    Object? originalBytes = null,
    Object? compressedBytes = null,
    Object? preset = null,
    Object? originalFormat = null,
    Object? compressedAt = null,
    Object? originalDeleted = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceAssetId: null == sourceAssetId
                ? _value.sourceAssetId
                : sourceAssetId // ignore: cast_nullable_to_non_nullable
                      as String,
            outputPath: null == outputPath
                ? _value.outputPath
                : outputPath // ignore: cast_nullable_to_non_nullable
                      as String,
            originalBytes: null == originalBytes
                ? _value.originalBytes
                : originalBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            compressedBytes: null == compressedBytes
                ? _value.compressedBytes
                : compressedBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            preset: null == preset
                ? _value.preset
                : preset // ignore: cast_nullable_to_non_nullable
                      as CompressPreset,
            originalFormat: null == originalFormat
                ? _value.originalFormat
                : originalFormat // ignore: cast_nullable_to_non_nullable
                      as ImageFormat,
            compressedAt: null == compressedAt
                ? _value.compressedAt
                : compressedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            originalDeleted: null == originalDeleted
                ? _value.originalDeleted
                : originalDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompressedRecordImplCopyWith<$Res>
    implements $CompressedRecordCopyWith<$Res> {
  factory _$$CompressedRecordImplCopyWith(
    _$CompressedRecordImpl value,
    $Res Function(_$CompressedRecordImpl) then,
  ) = __$$CompressedRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sourceAssetId,
    String outputPath,
    int originalBytes,
    int compressedBytes,
    CompressPreset preset,
    ImageFormat originalFormat,
    DateTime compressedAt,
    bool originalDeleted,
  });
}

/// @nodoc
class __$$CompressedRecordImplCopyWithImpl<$Res>
    extends _$CompressedRecordCopyWithImpl<$Res, _$CompressedRecordImpl>
    implements _$$CompressedRecordImplCopyWith<$Res> {
  __$$CompressedRecordImplCopyWithImpl(
    _$CompressedRecordImpl _value,
    $Res Function(_$CompressedRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompressedRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceAssetId = null,
    Object? outputPath = null,
    Object? originalBytes = null,
    Object? compressedBytes = null,
    Object? preset = null,
    Object? originalFormat = null,
    Object? compressedAt = null,
    Object? originalDeleted = null,
  }) {
    return _then(
      _$CompressedRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceAssetId: null == sourceAssetId
            ? _value.sourceAssetId
            : sourceAssetId // ignore: cast_nullable_to_non_nullable
                  as String,
        outputPath: null == outputPath
            ? _value.outputPath
            : outputPath // ignore: cast_nullable_to_non_nullable
                  as String,
        originalBytes: null == originalBytes
            ? _value.originalBytes
            : originalBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        compressedBytes: null == compressedBytes
            ? _value.compressedBytes
            : compressedBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        preset: null == preset
            ? _value.preset
            : preset // ignore: cast_nullable_to_non_nullable
                  as CompressPreset,
        originalFormat: null == originalFormat
            ? _value.originalFormat
            : originalFormat // ignore: cast_nullable_to_non_nullable
                  as ImageFormat,
        compressedAt: null == compressedAt
            ? _value.compressedAt
            : compressedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        originalDeleted: null == originalDeleted
            ? _value.originalDeleted
            : originalDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompressedRecordImpl extends _CompressedRecord {
  const _$CompressedRecordImpl({
    required this.id,
    required this.sourceAssetId,
    required this.outputPath,
    required this.originalBytes,
    required this.compressedBytes,
    required this.preset,
    required this.originalFormat,
    required this.compressedAt,
    this.originalDeleted = false,
  }) : super._();

  factory _$CompressedRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompressedRecordImplFromJson(json);

  @override
  final String id;

  /// 原图 photo_manager 资源 ID
  @override
  final String sourceAssetId;

  /// App 沙盒内 .avif 文件路径
  @override
  final String outputPath;
  @override
  final int originalBytes;
  @override
  final int compressedBytes;
  @override
  final CompressPreset preset;
  @override
  final ImageFormat originalFormat;
  @override
  final DateTime compressedAt;

  /// 用户是否已删除原图（释放空间）
  @override
  @JsonKey()
  final bool originalDeleted;

  @override
  String toString() {
    return 'CompressedRecord(id: $id, sourceAssetId: $sourceAssetId, outputPath: $outputPath, originalBytes: $originalBytes, compressedBytes: $compressedBytes, preset: $preset, originalFormat: $originalFormat, compressedAt: $compressedAt, originalDeleted: $originalDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompressedRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceAssetId, sourceAssetId) ||
                other.sourceAssetId == sourceAssetId) &&
            (identical(other.outputPath, outputPath) ||
                other.outputPath == outputPath) &&
            (identical(other.originalBytes, originalBytes) ||
                other.originalBytes == originalBytes) &&
            (identical(other.compressedBytes, compressedBytes) ||
                other.compressedBytes == compressedBytes) &&
            (identical(other.preset, preset) || other.preset == preset) &&
            (identical(other.originalFormat, originalFormat) ||
                other.originalFormat == originalFormat) &&
            (identical(other.compressedAt, compressedAt) ||
                other.compressedAt == compressedAt) &&
            (identical(other.originalDeleted, originalDeleted) ||
                other.originalDeleted == originalDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sourceAssetId,
    outputPath,
    originalBytes,
    compressedBytes,
    preset,
    originalFormat,
    compressedAt,
    originalDeleted,
  );

  /// Create a copy of CompressedRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompressedRecordImplCopyWith<_$CompressedRecordImpl> get copyWith =>
      __$$CompressedRecordImplCopyWithImpl<_$CompressedRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompressedRecordImplToJson(this);
  }
}

abstract class _CompressedRecord extends CompressedRecord {
  const factory _CompressedRecord({
    required final String id,
    required final String sourceAssetId,
    required final String outputPath,
    required final int originalBytes,
    required final int compressedBytes,
    required final CompressPreset preset,
    required final ImageFormat originalFormat,
    required final DateTime compressedAt,
    final bool originalDeleted,
  }) = _$CompressedRecordImpl;
  const _CompressedRecord._() : super._();

  factory _CompressedRecord.fromJson(Map<String, dynamic> json) =
      _$CompressedRecordImpl.fromJson;

  @override
  String get id;

  /// 原图 photo_manager 资源 ID
  @override
  String get sourceAssetId;

  /// App 沙盒内 .avif 文件路径
  @override
  String get outputPath;
  @override
  int get originalBytes;
  @override
  int get compressedBytes;
  @override
  CompressPreset get preset;
  @override
  ImageFormat get originalFormat;
  @override
  DateTime get compressedAt;

  /// 用户是否已删除原图（释放空间）
  @override
  bool get originalDeleted;

  /// Create a copy of CompressedRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompressedRecordImplCopyWith<_$CompressedRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

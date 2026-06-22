// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compress_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CompressJob _$CompressJobFromJson(Map<String, dynamic> json) {
  return _CompressJob.fromJson(json);
}

/// @nodoc
mixin _$CompressJob {
  String get id => throw _privateConstructorUsedError;
  PhotoAsset get source => throw _privateConstructorUsedError;
  CompressPreset get preset => throw _privateConstructorUsedError;
  JobStatus get status => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  int? get outputBytes => throw _privateConstructorUsedError;
  String? get outputPath => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  DateTime get queuedAt => throw _privateConstructorUsedError;
  DateTime? get finishedAt => throw _privateConstructorUsedError;

  /// Serializes this CompressJob to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompressJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompressJobCopyWith<CompressJob> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompressJobCopyWith<$Res> {
  factory $CompressJobCopyWith(
    CompressJob value,
    $Res Function(CompressJob) then,
  ) = _$CompressJobCopyWithImpl<$Res, CompressJob>;
  @useResult
  $Res call({
    String id,
    PhotoAsset source,
    CompressPreset preset,
    JobStatus status,
    double progress,
    int? outputBytes,
    String? outputPath,
    String? errorMessage,
    DateTime queuedAt,
    DateTime? finishedAt,
  });

  $PhotoAssetCopyWith<$Res> get source;
}

/// @nodoc
class _$CompressJobCopyWithImpl<$Res, $Val extends CompressJob>
    implements $CompressJobCopyWith<$Res> {
  _$CompressJobCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompressJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? preset = null,
    Object? status = null,
    Object? progress = null,
    Object? outputBytes = freezed,
    Object? outputPath = freezed,
    Object? errorMessage = freezed,
    Object? queuedAt = null,
    Object? finishedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as PhotoAsset,
            preset: null == preset
                ? _value.preset
                : preset // ignore: cast_nullable_to_non_nullable
                      as CompressPreset,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as JobStatus,
            progress: null == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double,
            outputBytes: freezed == outputBytes
                ? _value.outputBytes
                : outputBytes // ignore: cast_nullable_to_non_nullable
                      as int?,
            outputPath: freezed == outputPath
                ? _value.outputPath
                : outputPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            queuedAt: null == queuedAt
                ? _value.queuedAt
                : queuedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            finishedAt: freezed == finishedAt
                ? _value.finishedAt
                : finishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of CompressJob
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PhotoAssetCopyWith<$Res> get source {
    return $PhotoAssetCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CompressJobImplCopyWith<$Res>
    implements $CompressJobCopyWith<$Res> {
  factory _$$CompressJobImplCopyWith(
    _$CompressJobImpl value,
    $Res Function(_$CompressJobImpl) then,
  ) = __$$CompressJobImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    PhotoAsset source,
    CompressPreset preset,
    JobStatus status,
    double progress,
    int? outputBytes,
    String? outputPath,
    String? errorMessage,
    DateTime queuedAt,
    DateTime? finishedAt,
  });

  @override
  $PhotoAssetCopyWith<$Res> get source;
}

/// @nodoc
class __$$CompressJobImplCopyWithImpl<$Res>
    extends _$CompressJobCopyWithImpl<$Res, _$CompressJobImpl>
    implements _$$CompressJobImplCopyWith<$Res> {
  __$$CompressJobImplCopyWithImpl(
    _$CompressJobImpl _value,
    $Res Function(_$CompressJobImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompressJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? preset = null,
    Object? status = null,
    Object? progress = null,
    Object? outputBytes = freezed,
    Object? outputPath = freezed,
    Object? errorMessage = freezed,
    Object? queuedAt = null,
    Object? finishedAt = freezed,
  }) {
    return _then(
      _$CompressJobImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as PhotoAsset,
        preset: null == preset
            ? _value.preset
            : preset // ignore: cast_nullable_to_non_nullable
                  as CompressPreset,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as JobStatus,
        progress: null == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double,
        outputBytes: freezed == outputBytes
            ? _value.outputBytes
            : outputBytes // ignore: cast_nullable_to_non_nullable
                  as int?,
        outputPath: freezed == outputPath
            ? _value.outputPath
            : outputPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        queuedAt: null == queuedAt
            ? _value.queuedAt
            : queuedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        finishedAt: freezed == finishedAt
            ? _value.finishedAt
            : finishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompressJobImpl extends _CompressJob {
  const _$CompressJobImpl({
    required this.id,
    required this.source,
    required this.preset,
    required this.status,
    this.progress = 0.0,
    this.outputBytes,
    this.outputPath,
    this.errorMessage,
    required this.queuedAt,
    this.finishedAt,
  }) : super._();

  factory _$CompressJobImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompressJobImplFromJson(json);

  @override
  final String id;
  @override
  final PhotoAsset source;
  @override
  final CompressPreset preset;
  @override
  final JobStatus status;
  @override
  @JsonKey()
  final double progress;
  @override
  final int? outputBytes;
  @override
  final String? outputPath;
  @override
  final String? errorMessage;
  @override
  final DateTime queuedAt;
  @override
  final DateTime? finishedAt;

  @override
  String toString() {
    return 'CompressJob(id: $id, source: $source, preset: $preset, status: $status, progress: $progress, outputBytes: $outputBytes, outputPath: $outputPath, errorMessage: $errorMessage, queuedAt: $queuedAt, finishedAt: $finishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompressJobImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.preset, preset) || other.preset == preset) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.outputBytes, outputBytes) ||
                other.outputBytes == outputBytes) &&
            (identical(other.outputPath, outputPath) ||
                other.outputPath == outputPath) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.queuedAt, queuedAt) ||
                other.queuedAt == queuedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    source,
    preset,
    status,
    progress,
    outputBytes,
    outputPath,
    errorMessage,
    queuedAt,
    finishedAt,
  );

  /// Create a copy of CompressJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompressJobImplCopyWith<_$CompressJobImpl> get copyWith =>
      __$$CompressJobImplCopyWithImpl<_$CompressJobImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompressJobImplToJson(this);
  }
}

abstract class _CompressJob extends CompressJob {
  const factory _CompressJob({
    required final String id,
    required final PhotoAsset source,
    required final CompressPreset preset,
    required final JobStatus status,
    final double progress,
    final int? outputBytes,
    final String? outputPath,
    final String? errorMessage,
    required final DateTime queuedAt,
    final DateTime? finishedAt,
  }) = _$CompressJobImpl;
  const _CompressJob._() : super._();

  factory _CompressJob.fromJson(Map<String, dynamic> json) =
      _$CompressJobImpl.fromJson;

  @override
  String get id;
  @override
  PhotoAsset get source;
  @override
  CompressPreset get preset;
  @override
  JobStatus get status;
  @override
  double get progress;
  @override
  int? get outputBytes;
  @override
  String? get outputPath;
  @override
  String? get errorMessage;
  @override
  DateTime get queuedAt;
  @override
  DateTime? get finishedAt;

  /// Create a copy of CompressJob
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompressJobImplCopyWith<_$CompressJobImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

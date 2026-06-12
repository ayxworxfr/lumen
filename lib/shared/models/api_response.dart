import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// API 统一响应模型
@Freezed(genericArgumentFactories: true)
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required int code,
    required String message,
    T? data,
    int? timestamp,
  }) = _ApiResponse<T>;
  const ApiResponse._();

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  bool get isSuccess => code == 0 || code == 200;
}

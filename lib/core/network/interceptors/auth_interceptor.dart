import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../../../features/auth/services/auth_service.dart';

/// Token 认证拦截器
///
/// 功能：
/// - 自动注入 Token 到请求头（从 AuthService 内存缓存同步读取）
/// - 处理 401 未授权（刷新 Token → 重放请求，失败则导航至登录页）
/// - 并发 401 安全：[QueuedInterceptor] 串行化 onError；Token 比对跳过重复刷新
///
/// 由 [HttpClient._initDio] 创建并注入 [dio] 字段，用于重放失败请求。
const _kRetryHeader = 'X-Retry';

class AuthInterceptor extends QueuedInterceptor {
  /// 由 HttpClient 注入，不直接 import HttpClient 以避免循环依赖
  late final Dio dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = Get.find<AuthService>().cachedAccessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 只处理 401；跳过已标记的重试请求，防止无限循环
    if (err.response?.statusCode != 401 ||
        err.requestOptions.headers.containsKey(_kRetryHeader)) {
      handler.next(err);
      return;
    }

    final authService = Get.find<AuthService>();
    final currentToken = authService.cachedAccessToken;
    final requestToken =
        (err.requestOptions.headers['Authorization'] as String?)?.replaceFirst(
          'Bearer ',
          '',
        );

    // QueuedInterceptor 串行化 onError：前一个 401 刷新完成后，当前存储的 Token
    // 已更新。若与请求时的 Token 不同，说明已刷新，直接重放即可。
    final alreadyRefreshed =
        currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != requestToken;

    final bool refreshed;
    if (alreadyRefreshed) {
      refreshed = true;
    } else {
      refreshed = await authService.refreshToken();
    }

    if (!refreshed) {
      // refreshToken() 内部失败时已清除本地认证数据
      AppRouter.go(AppRoutes.login);
      handler.next(err);
      return;
    }

    // 用新 Token 重放原请求
    final newToken = authService.cachedAccessToken;
    try {
      final response = await dio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: Options(
          method: err.requestOptions.method,
          headers: {
            ...err.requestOptions.headers,
            'Authorization': 'Bearer $newToken',
            _kRetryHeader: 'true',
          },
          sendTimeout: err.requestOptions.sendTimeout,
          receiveTimeout: err.requestOptions.receiveTimeout,
        ),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

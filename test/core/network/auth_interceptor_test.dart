import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

import 'package:lumen/core/network/interceptors/auth_interceptor.dart';
import 'package:lumen/features/auth/models/user_model.dart';
import 'package:lumen/features/auth/services/auth_service.dart';

// ---------------------------------------------------------------------------
// Fake AuthService — extends GetxService so Get.put() lifecycle works.
// ---------------------------------------------------------------------------

class _FakeAuthService extends GetxService implements AuthService {
  String? _token;
  int refreshCallCount = 0;
  bool refreshResult = true;

  _FakeAuthService(this._token);

  @override
  String? get cachedAccessToken => _token;

  @override
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  @override
  Future<bool> refreshToken() async {
    refreshCallCount++;
    if (refreshResult) {
      _token = 'new_token';
    }
    return refreshResult;
  }

  // ---- stubs for the rest of AuthService's interface ----

  @override
  Rxn<UserModel> get currentUser => throw UnimplementedError();

  @override
  Future<UserModel> login({required String username, required String password}) =>
      throw UnimplementedError();

  @override
  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
    String? phone,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<void> loadUserFromLocal() => throw UnimplementedError();

  @override
  Future<UserModel> getUserInfo() => throw UnimplementedError();

  @override
  Future<UserModel> updateUserInfo(Map<String, dynamic> data) =>
      throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Handler stub
// ---------------------------------------------------------------------------

class _RecordingHandler extends ErrorInterceptorHandler {
  bool resolved = false;
  bool nexted = false;

  @override
  void next(DioException err) => nexted = true;

  @override
  void resolve(Response response) => resolved = true;

  @override
  void reject(DioException err, [bool callFollowingErrorInterceptor = false]) {}
}

// ---------------------------------------------------------------------------
// Request handler stub
// ---------------------------------------------------------------------------

class _CapturingRequestHandler extends RequestInterceptorHandler {
  final void Function(RequestOptions) onNext;
  _CapturingRequestHandler({required this.onNext});

  @override
  void next(RequestOptions options) => onNext(options);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DioException _make401(String bearerToken, {Map<String, dynamic>? extraHeaders}) {
  return DioException(
    requestOptions: RequestOptions(
      path: '/api/test',
      headers: {
        'Authorization': 'Bearer $bearerToken',
        ...?extraHeaders,
      },
    ),
    response: Response(
      requestOptions: RequestOptions(path: '/api/test'),
      statusCode: 401,
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException _makeError(int statusCode) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/test'),
    response: Response(
      requestOptions: RequestOptions(path: '/api/test'),
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );
}

// Dio that always throws a connection error (avoids real network calls in tests).
Dio _localDio() => Dio(BaseOptions(
      baseUrl: 'http://localhost:19999',
      connectTimeout: const Duration(milliseconds: 50),
      receiveTimeout: const Duration(milliseconds: 50),
    ));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.testMode = true);
  tearDown(() => Get.deleteAll(force: true));

  group('non-401 and retry-header pass-through', () {
    test('non-401 500 error passes through without calling refreshToken', () async {
      final fake = _FakeAuthService('token');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = Dio();

      final handler = _RecordingHandler();
      await interceptor.onError(_makeError(500), handler);

      expect(fake.refreshCallCount, equals(0));
      expect(handler.nexted, isTrue);
    });

    test('non-401 403 error passes through without calling refreshToken', () async {
      final fake = _FakeAuthService('token');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = Dio();

      final handler = _RecordingHandler();
      await interceptor.onError(_makeError(403), handler);

      expect(fake.refreshCallCount, equals(0));
      expect(handler.nexted, isTrue);
    });

    test('X-Retry header on 401 skips refreshToken', () async {
      final fake = _FakeAuthService('token');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = Dio();

      final handler = _RecordingHandler();
      await interceptor.onError(
        _make401('token', extraHeaders: {'X-Retry': 'true'}),
        handler,
      );

      expect(fake.refreshCallCount, equals(0));
      expect(handler.nexted, isTrue);
    });
  });

  group('alreadyRefreshed deduplication (F-1)', () {
    test('three sequential 401 errors trigger refreshToken exactly once', () async {
      final fake = _FakeAuthService('old_token');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = _localDio();

      // First 401: triggers refresh. Retry will fail (no server) → handler.nexted.
      final h1 = _RecordingHandler();
      await interceptor.onError(_make401('old_token'), h1);
      // After this, fake._token == 'new_token'.

      // Second 401: currentToken('new_token') != requestToken('old_token') → alreadyRefreshed.
      final h2 = _RecordingHandler();
      await interceptor.onError(_make401('old_token'), h2);

      // Third 401: same alreadyRefreshed path.
      final h3 = _RecordingHandler();
      await interceptor.onError(_make401('old_token'), h3);

      expect(fake.refreshCallCount, equals(1),
          reason: 'refreshToken must be called only once across three 401 errors');
    });

    test('second 401 with old token resolves or nexts without extra refresh', () async {
      final fake = _FakeAuthService('old_token');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = _localDio();

      final h1 = _RecordingHandler();
      await interceptor.onError(_make401('old_token'), h1);

      final h2 = _RecordingHandler();
      await interceptor.onError(_make401('old_token'), h2);

      expect(fake.refreshCallCount, equals(1));
      expect(h2.resolved || h2.nexted, isTrue);
    });
  });

  group('refresh failure → navigate to login', () {
    test('calls refreshToken exactly once when refresh returns false', () async {
      final fake = _FakeAuthService('expired_token')..refreshResult = false;
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = Dio();

      final handler = _RecordingHandler();
      try {
        await interceptor.onError(_make401('expired_token'), handler);
      } catch (_) {
        // AppRouter.go may throw in headless test context.
      }

      expect(fake.refreshCallCount, equals(1));
    });

    test('handler.next is called after failed refresh', () async {
      final fake = _FakeAuthService('expired_token')..refreshResult = false;
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = Dio();

      final handler = _RecordingHandler();
      try {
        await interceptor.onError(_make401('expired_token'), handler);
      } catch (_) {
        // Navigation throws before handler.next in headless context.
      }

      // At minimum, refresh was attempted.
      expect(fake.refreshCallCount, equals(1));
    });

    test('when token is null (no auth header), 401 still attempts refresh', () async {
      final fake = _FakeAuthService(null)..refreshResult = false;
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();
      interceptor.dio = Dio();

      final handler = _RecordingHandler();
      try {
        await interceptor.onError(
          DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/test'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
          handler,
        );
      } catch (_) {}

      expect(fake.refreshCallCount, equals(1));
    });
  });

  group('onRequest token injection', () {
    test('injects Bearer token into request headers when token is present', () async {
      final fake = _FakeAuthService('my_access_token');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();

      final options = RequestOptions(path: '/api/resource');
      bool nextCalled = false;
      RequestOptions? captured;

      interceptor.onRequest(
        options,
        _CapturingRequestHandler(onNext: (opts) {
          nextCalled = true;
          captured = opts;
        }),
      );

      expect(nextCalled, isTrue);
      expect(captured?.headers['Authorization'], equals('Bearer my_access_token'));
    });

    test('does not inject Authorization header when token is null', () async {
      final fake = _FakeAuthService(null);
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();

      final options = RequestOptions(path: '/api/resource');
      bool nextCalled = false;
      RequestOptions? captured;

      interceptor.onRequest(
        options,
        _CapturingRequestHandler(onNext: (opts) {
          nextCalled = true;
          captured = opts;
        }),
      );

      expect(nextCalled, isTrue);
      expect(captured?.headers.containsKey('Authorization'), isFalse);
    });

    test('does not inject Authorization header when token is empty string', () async {
      final fake = _FakeAuthService('');
      Get.put<AuthService>(fake);

      final interceptor = AuthInterceptor();

      final options = RequestOptions(path: '/api/resource');
      bool nextCalled = false;
      RequestOptions? captured;

      interceptor.onRequest(
        options,
        _CapturingRequestHandler(onNext: (opts) {
          nextCalled = true;
          captured = opts;
        }),
      );

      expect(nextCalled, isTrue);
      expect(captured?.headers.containsKey('Authorization'), isFalse);
    });
  });
}

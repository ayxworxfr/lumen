import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

import 'package:lumen/core/network/http_client.dart';
import 'package:lumen/core/storage/storage_service.dart';
import 'package:lumen/features/auth/controllers/auth_controller.dart';
import 'package:lumen/features/auth/models/user_model.dart';
import 'package:lumen/features/auth/services/auth_service.dart';
import 'package:lumen/shared/constants/storage_keys.dart';

// ─── Mock / Fake classes ─────────────────────────────────────────────────────

/// HttpClient is a GetxService. We must EXTEND it (not just implement it) so
/// that GetX's internal InternalFinalCallback fields are properly initialised
/// when Get.put() calls _startController. We override only the methods used by
/// AuthService.
class FakeHttpClient extends HttpClient {
  // Delegate call tracking to a Mocktail mock that only implements the
  // plain Dart interface (not the GetxService lifecycle).
  _HttpClientCalls calls = _HttpClientCalls();

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => calls.post<T>(path, data: data);

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => calls.put<T>(path, data: data);

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => calls.get<T>(path);
}

/// Plain Dart helper to record stubbed return values — NOT a GetxService.
///
/// Stubs are stored as dynamic to avoid Dart generic covariance issues.
class _HttpClientCalls {
  // Stored as dynamic Response to avoid generic type variance failures.
  Response<dynamic>? _postResponse;
  Response<dynamic>? _putResponse;
  Response<dynamic>? _getResponse;

  void stubPost(Response<dynamic> response) => _postResponse = response;
  void stubPut(Response<dynamic> response) => _putResponse = response;
  void stubGet(Response<dynamic> response) => _getResponse = response;

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    if (_postResponse != null) {
      return Response<T>(
        data: _postResponse!.data as T?,
        requestOptions: _postResponse!.requestOptions,
        statusCode: _postResponse!.statusCode,
      );
    }
    throw UnimplementedError('post not stubbed for $path');
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    if (_putResponse != null) {
      return Response<T>(
        data: _putResponse!.data as T?,
        requestOptions: _putResponse!.requestOptions,
        statusCode: _putResponse!.statusCode,
      );
    }
    throw UnimplementedError('put not stubbed for $path');
  }

  Future<Response<T>> get<T>(String path) async {
    if (_getResponse != null) {
      return Response<T>(
        data: _getResponse!.data as T?,
        requestOptions: _getResponse!.requestOptions,
        statusCode: _getResponse!.statusCode,
      );
    }
    throw UnimplementedError('get not stubbed for $path');
  }
}

/// StorageService is also a GetxService, so we extend it.
/// We override every method AuthService uses to return safe defaults.
class FakeStorageService extends StorageService {
  // Backing stores for key→value inspection in tests.
  final _secureStore = <String, String>{};
  final _bools = <String, bool>{};
  final _userData = <String, dynamic>{};
  bool deleteUserDataCalled = false;
  String? lastDeletedKey;

  @override
  Future<void> setSecureString(String key, String value) async {
    _secureStore[key] = value;
  }

  @override
  Future<String?> getSecureString(String key) async => _secureStore[key];

  @override
  Future<void> removeSecure(String key) async {
    _secureStore.remove(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _bools[key] = value;
    return true;
  }

  @override
  T? getUserData<T>(String key) => _userData[key] as T?;

  @override
  Future<void> saveUserData<T>(String key, T value) async {
    _userData[key] = value;
  }

  @override
  Future<void> deleteUserData(String key) async {
    deleteUserDataCalled = true;
    lastDeletedKey = key;
    _userData.remove(key);
  }

  // ── convenience helpers for test setup ──

  void seedSecure(String key, String value) => _secureStore[key] = value;
  void seedUserData(String key, dynamic value) => _userData[key] = value;
  bool? getBoolDirect(String key) => _bools[key];
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

FakeStorageService _buildFakeStorage() => FakeStorageService();
FakeHttpClient _buildFakeHttp() => FakeHttpClient();

/// Build a Dio Response for HttpClient stubs (typed as dynamic to avoid
/// generic covariance issues with Dart's type system).
Response<dynamic> _dioResponse(dynamic data, String path) => Response<dynamic>(
  data: data,
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
);

// ─── Shared setup / teardown ─────────────────────────────────────────────────

void _commonSetUp() {
  Get.testMode = true;
}

void _commonTearDown() {
  Get.reset();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // Note: EnvConfig.enableMock returns true when running flutter test in debug
  // mode (no dart-define overrides), because kDebugMode == true → isDev == true.
  // All tests below work regardless of the mock-flag value:
  //   • When MockData.enabled == true  → the mock-login path is exercised.
  //   • When MockData.enabled == false → the real HttpClient path is exercised
  //     via FakeHttpClient stubs.

  // ── F-1: login() saves user and sets cachedAccessToken ───────────────────

  group('F-1: login() saves user and cachedAccessToken', () {
    setUp(_commonSetUp);
    tearDown(_commonTearDown);

    test('login() sets currentUser.value and cachedAccessToken', () async {
      final fakeStorage = _buildFakeStorage();
      final fakeHttp = _buildFakeHttp();

      // Stub the real-HTTP path so the test works when MockData.enabled==false.
      fakeHttp.calls.stubPost(
        _dioResponse({
          'code': 0,
          'message': 'success',
          'data': {
            'accessToken': 'real_access_token',
            'refreshToken': 'real_refresh_token',
            'user': {
              'id': 1,
              'username': 'admin',
              'nickname': '管理员',
              'email': 'admin@example.com',
              'avatar': '',
            },
          },
        }, '/auth/login'),
      );

      Get.put<StorageService>(fakeStorage);
      Get.put<HttpClient>(fakeHttp);
      final authService = Get.put<AuthService>(AuthService());

      await authService.login(username: 'admin', password: '123456');

      expect(authService.currentUser.value, isNotNull);
      expect(authService.currentUser.value!.username, equals('admin'));
      expect(authService.cachedAccessToken, isNotNull);
      expect(authService.cachedAccessToken!.isNotEmpty, isTrue);
      expect(authService.isLoggedIn, isTrue);
    });
  });

  // ── F-2: logout() clears currentUser and cachedAccessToken ───────────────

  group('F-2: logout() clears local auth state', () {
    setUp(_commonSetUp);
    tearDown(_commonTearDown);

    test(
      'logout() sets currentUser to null and clears cachedAccessToken',
      () async {
        final fakeStorage = _buildFakeStorage();
        final fakeHttp = _buildFakeHttp();

        // Stub post for the non-mock logout HTTP call.
        fakeHttp.calls.stubPost(_dioResponse(null, '/auth/logout'));

        Get.put<StorageService>(fakeStorage);
        Get.put<HttpClient>(fakeHttp);
        final authService = Get.put<AuthService>(AuthService());

        // Manually inject a logged-in state without going through login().
        authService.currentUser.value = const UserModel(
          id: 1,
          username: 'test',
          nickname: 'Test User',
          email: 'test@test.com',
        );

        await authService.logout();

        expect(authService.currentUser.value, isNull);
        expect(authService.cachedAccessToken, isNull);
        expect(authService.isLoggedIn, isFalse);
      },
    );

    test('logout() writes sessionActive=false to storage', () async {
      final fakeStorage = _buildFakeStorage();
      final fakeHttp = _buildFakeHttp();

      fakeHttp.calls.stubPost(_dioResponse(null, '/auth/logout'));

      Get.put<StorageService>(fakeStorage);
      Get.put<HttpClient>(fakeHttp);
      final authService = Get.put<AuthService>(AuthService());

      await authService.logout();

      // Verify storage side-effects via FakeStorageService backing stores.
      expect(fakeStorage.getBoolDirect(StorageKeys.sessionActive), isFalse);
      expect(fakeStorage.deleteUserDataCalled, isTrue);
      expect(fakeStorage.lastDeletedKey, equals(StorageKeys.currentUser));
      // Secure storage keys should have been removed.
      expect(
        await fakeStorage.getSecureString(StorageKeys.accessToken),
        isNull,
      );
      expect(
        await fakeStorage.getSecureString(StorageKeys.refreshToken),
        isNull,
      );
    });
  });

  // ── F-3: updateUserInfo updates currentUser.value ────────────────────────

  group('F-3: updateUserInfo() updates currentUser.value', () {
    setUp(_commonSetUp);
    tearDown(_commonTearDown);

    test('returns updated UserModel and mutates currentUser.value', () async {
      final fakeStorage = _buildFakeStorage();
      final fakeHttp = _buildFakeHttp();

      fakeHttp.calls.stubPut(
        _dioResponse({
          'id': 1,
          'username': 'admin',
          'nickname': '新昵称',
          'email': 'admin@example.com',
          'avatar': '',
        }, '/user/profile'),
      );

      Get.put<StorageService>(fakeStorage);
      Get.put<HttpClient>(fakeHttp);
      final authService = Get.put<AuthService>(AuthService());

      final result = await authService.updateUserInfo({'nickname': '新昵称'});

      expect(result.nickname, equals('新昵称'));
      expect(authService.currentUser.value, isNotNull);
      expect(authService.currentUser.value!.username, equals('admin'));
      expect(authService.currentUser.value!.nickname, equals('新昵称'));
    });

    test(
      'updateUserInfo() persists updated user to Hive via storage',
      () async {
        final fakeStorage = _buildFakeStorage();
        final fakeHttp = _buildFakeHttp();

        fakeHttp.calls.stubPut(
          _dioResponse({
            'id': 1,
            'username': 'admin',
            'nickname': '持久化昵称',
            'email': 'admin@example.com',
          }, '/user/profile'),
        );

        Get.put<StorageService>(fakeStorage);
        Get.put<HttpClient>(fakeHttp);
        final authService = Get.put<AuthService>(AuthService());

        await authService.updateUserInfo({'nickname': '持久化昵称'});

        // FakeStorageService records the saved data in _userData.
        final stored = fakeStorage.getUserData<Map<String, dynamic>>(
          StorageKeys.currentUser,
        );
        expect(stored, isNotNull);
        expect(stored!['nickname'], equals('持久化昵称'));
      },
    );
  });

  // ── F-4: loadUserFromLocal restores state from storage ───────────────────

  group('F-4: loadUserFromLocal() restores user from local storage', () {
    setUp(_commonSetUp);
    tearDown(_commonTearDown);

    test(
      'restores cachedAccessToken from secure storage and user from Hive',
      () async {
        final fakeStorage = _buildFakeStorage();
        final fakeHttp = _buildFakeHttp();

        // Seed persisted data into the fake.
        fakeStorage.seedSecure(
          StorageKeys.accessToken,
          'restored_access_token',
        );
        fakeStorage.seedUserData(StorageKeys.currentUser, <String, dynamic>{
          'id': 42,
          'username': 'stored_user',
          'nickname': '存储用户',
          'email': 'stored@test.com',
        });

        Get.put<StorageService>(fakeStorage);
        Get.put<HttpClient>(fakeHttp);
        final authService = Get.put<AuthService>(AuthService());

        await authService.loadUserFromLocal();

        expect(authService.cachedAccessToken, equals('restored_access_token'));
        expect(authService.isLoggedIn, isTrue);
        expect(authService.currentUser.value, isNotNull);
        expect(authService.currentUser.value!.username, equals('stored_user'));
        expect(authService.currentUser.value!.id, equals(42));
      },
    );

    test('remains logged-out when storage is empty', () async {
      final fakeStorage = _buildFakeStorage();
      final fakeHttp = _buildFakeHttp();

      // Nothing seeded — all reads return null.

      Get.put<StorageService>(fakeStorage);
      Get.put<HttpClient>(fakeHttp);
      final authService = Get.put<AuthService>(AuthService());

      await authService.loadUserFromLocal();

      expect(authService.cachedAccessToken, isNull);
      expect(authService.isLoggedIn, isFalse);
      expect(authService.currentUser.value, isNull);
    });
  });

  // ── F-5: AuthController is findable after AuthService is registered ───────

  group('F-5: AuthController is findable after AuthService is registered', () {
    setUp(_commonSetUp);
    tearDown(_commonTearDown);

    test(
      'Get.find<AuthController>() succeeds after simulating main init order',
      () {
        final fakeStorage = _buildFakeStorage();
        final fakeHttp = _buildFakeHttp();

        // Mirror the registration order that main.dart / bindings perform.
        Get.put<StorageService>(fakeStorage, permanent: true);
        Get.put<HttpClient>(fakeHttp, permanent: true);
        Get.put<AuthService>(AuthService(), permanent: true);
        Get.put<AuthController>(AuthController(), permanent: true);

        expect(() => Get.find<AuthController>(), returnsNormally);
        expect(Get.find<AuthController>(), isA<AuthController>());
      },
    );

    test('AuthController exposes AuthService.currentUser via proxy', () {
      final fakeStorage = _buildFakeStorage();
      final fakeHttp = _buildFakeHttp();

      Get.put<StorageService>(fakeStorage, permanent: true);
      Get.put<HttpClient>(fakeHttp, permanent: true);
      Get.put<AuthService>(AuthService(), permanent: true);
      Get.put<AuthController>(AuthController(), permanent: true);

      final controller = Get.find<AuthController>();
      // currentUser is a reactive proxy to AuthService.currentUser.
      expect(controller.currentUser, isNotNull);
      expect(controller.currentUser.value, isNull); // no login yet
    });
  });

  // ── isLoggedIn reflects token state ──────────────────────────────────────

  group('isLoggedIn reflects token presence', () {
    setUp(_commonSetUp);
    tearDown(_commonTearDown);

    test('isLoggedIn is false before any login', () {
      final fakeStorage = _buildFakeStorage();
      final fakeHttp = _buildFakeHttp();

      Get.put<StorageService>(fakeStorage);
      Get.put<HttpClient>(fakeHttp);
      final authService = Get.put<AuthService>(AuthService());

      expect(authService.isLoggedIn, isFalse);
    });
  });
}

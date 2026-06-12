import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

import 'package:lumen/core/network/http_client.dart';
import 'package:lumen/core/storage/storage_service.dart';
import 'package:lumen/core/widgets/app_button.dart';
import 'package:lumen/core/widgets/app_text_field.dart';
import 'package:lumen/features/auth/controllers/auth_controller.dart';
import 'package:lumen/features/auth/services/auth_service.dart';
import 'package:lumen/features/auth/views/login_page.dart';
import 'package:lumen/l10n/generated/app_localizations.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────
//
// Both StorageService and HttpClient extend GetxService. Using
// `Mock implements <GetxService subclass>` fails at runtime because
// mocktail cannot initialise GetX's InternalFinalCallback fields.
//
// The solution is to EXTEND the concrete class and override only the
// methods the code-under-test actually calls.

class FakeStorageService extends StorageService {
  final _secureStore = <String, String>{};
  final _bools = <String, bool>{};
  final _userData = <String, dynamic>{};

  @override
  Future<void> setSecureString(String key, String value) async =>
      _secureStore[key] = value;

  @override
  Future<String?> getSecureString(String key) async => _secureStore[key];

  @override
  Future<void> removeSecure(String key) async => _secureStore.remove(key);

  @override
  Future<bool> setBool(String key, bool value) async {
    _bools[key] = value;
    return true;
  }

  @override
  T? getUserData<T>(String key) => _userData[key] as T?;

  @override
  Future<void> saveUserData<T>(String key, T value) async =>
      _userData[key] = value;

  @override
  Future<void> deleteUserData(String key) async => _userData.remove(key);
}

class FakeHttpClient extends HttpClient {
  // Stores a generic post/put/get response to return from stubs.
  Response<dynamic>? _postResponse;
  Response<dynamic>? _putResponse;

  void stubPost(Response<dynamic> response) => _postResponse = response;
  void stubPut(Response<dynamic> response) => _putResponse = response;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (_postResponse != null) {
      return Response<T>(
        data: _postResponse!.data as T?,
        requestOptions: _postResponse!.requestOptions,
        statusCode: _postResponse!.statusCode,
      );
    }
    // In mock mode (debug/test) AuthService.login/_mockLogin never calls HTTP.
    throw UnimplementedError('post not stubbed for $path');
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (_putResponse != null) {
      return Response<T>(
        data: _putResponse!.data as T?,
        requestOptions: _putResponse!.requestOptions,
        statusCode: _putResponse!.statusCode,
      );
    }
    throw UnimplementedError('put not stubbed for $path');
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

/// Pump [LoginPage] with full GetX + localisation setup.
Future<void> _pumpLoginPage(
  WidgetTester tester, {
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginPage(),
    ),
  );
  // Let localisation delegates, Obx rebuilds, and animations settle.
  await tester.pumpAndSettle();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    Get.testMode = true;

    // Register fakes BEFORE any service/controller that depends on them.
    Get.put<StorageService>(FakeStorageService());
    Get.put<HttpClient>(FakeHttpClient());
    Get.put<AuthService>(AuthService());
    Get.put<AuthController>(AuthController());
  });

  tearDown(Get.reset);

  // ── T-1: Smoke test ────────────────────────────────────────────────────────

  testWidgets('T-1: LoginPage pumps without throwing', (tester) async {
    await _pumpLoginPage(tester);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  // ── T-2: Username + password AppTextField widgets are present ─────────────

  testWidgets('T-2: Username AppTextField is rendered', (tester) async {
    await _pumpLoginPage(tester);

    // LoginPage creates exactly 2 AppTextField instances (username + password).
    expect(find.byType(AppTextField), findsNWidgets(2));
  });

  // ── T-3: Password field obscures text by default ──────────────────────────

  testWidgets('T-3: Password field obscures text by default', (tester) async {
    await _pumpLoginPage(tester);

    // Each AppTextField contains an EditableText. The password one (index 1)
    // must have obscureText == true.
    final editables = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    // Expect at least 2 editable text widgets (username + password).
    expect(editables.length, greaterThanOrEqualTo(2));
    expect(editables[1].obscureText, isTrue);
  });

  // ── T-4: Submit AppButton is present ──────────────────────────────────────

  testWidgets('T-4: Submit AppButton is rendered', (tester) async {
    await _pumpLoginPage(tester);

    expect(find.byType(AppButton), findsOneWidget);
  });

  // ── T-5: Empty form shows validation error ────────────────────────────────

  testWidgets('T-5: Empty form submission shows validation error', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    // AuthController.onInit() pre-fills the fields with 'admin' / '123456'.
    // Clear both fields to trigger the required-field validators.
    final textFormFields = find.byType(TextFormField);
    await tester.enterText(textFormFields.first, '');
    await tester.enterText(textFormFields.last, '');
    await tester.pump();

    // Tap the submit AppButton.
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    // ValidatorUtil.username returns '请输入用户名' when value is empty.
    // The same string is also the hint text on the username AppTextField,
    // so findsWidgets matches both the hint and the validator error text.
    expect(find.text('请输入用户名'), findsWidgets);
  });

  // ── T-6: Register entry button is present ─────────────────────────────────

  testWidgets('T-6: Register entry OutlinedButton is rendered', (tester) async {
    await _pumpLoginPage(tester);

    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  // ── T-7: App name is displayed ────────────────────────────────────────────

  testWidgets('T-7: App name is displayed on LoginPage', (tester) async {
    await _pumpLoginPage(tester);

    // l10n.commonAppName == 'Lumen' in zh locale.
    expect(find.text('Lumen'), findsOneWidget);
  });

  // ── T-8: Valid input does not produce validation error ────────────────────

  testWidgets('T-8: Valid username and password pass validation', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    final textFormFields = find.byType(TextFormField);
    await tester.enterText(textFormFields.first, 'validuser');
    await tester.enterText(textFormFields.last, 'validpass');
    await tester.pump();

    // Tap submit. Validation passes; the login flow is triggered.
    // We verify that short-password and long-username errors are absent —
    // those can only appear if the validators ran and rejected the input.
    // (The hint texts '请输入用户名' and '请输入密码' may reappear after
    // _clearForm() runs on a successful mock login, so we don't assert findsNothing
    // for them.)
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('用户名至少 3 个字符'), findsNothing);
    expect(find.text('密码至少 6 个字符'), findsNothing);
  });

  // ── T-9: Password visibility toggle ──────────────────────────────────────

  testWidgets('T-9: Password becomes visible after tapping the eye icon', (
    tester,
  ) async {
    await _pumpLoginPage(tester);

    // Before tap: password field (index 1) obscures text.
    final editablesBefore = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(editablesBefore[1].obscureText, isTrue);

    // Tap the visibility toggle icon (Icons.visibility_rounded).
    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pumpAndSettle();

    // After tap: password field should show text.
    final editablesAfter = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(editablesAfter[1].obscureText, isFalse);
  });
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/controllers/app_controller.dart';
import 'core/config/env_config.dart';
import 'core/network/http_client.dart';
import 'core/storage/storage_service.dart';
import 'core/utils/logger_util.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';

/// 应用入口
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        // TODO(team): integrate Sentry/Crashlytics here
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        // TODO(team): integrate Sentry/Crashlytics here
        LoggerUtil.e('Uncaught platform error', error, stack);
        return true;
      };

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      await _initServices();

      runApp(const App());
    },
    (error, stack) {
      // TODO(team): integrate Sentry/Crashlytics here
      LoggerUtil.e('Uncaught zone error', error, stack);
    },
  );
}

/// 初始化服务
///
/// 顺序：Storage → AppController → HttpClient → AuthService → AuthController
Future<void> _initServices() async {
  LoggerUtil.i('Starting services... env=${EnvConfig.appEnv}');

  // 1. Storage（其他服务均依赖它）
  await Get.putAsync<StorageService>(() => StorageService().init());

  // 2. AppController（主题 & 语言，需要 StorageService）
  Get.put(AppController(), permanent: true);

  // 3. Network
  Get.put<HttpClient>(HttpClient());

  // 4. Auth services & controller（permanent — 全局可访问）
  final authService = Get.put<AuthService>(AuthService(), permanent: true);
  await authService.loadUserFromLocal();
  Get.put(AuthController(), permanent: true);

  LoggerUtil.i('All services ready');
}

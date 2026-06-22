import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/controllers/app_controller.dart';
import 'core/config/env_config.dart';
import 'core/network/http_client.dart';
import 'core/storage/file_store.dart';
import 'core/storage/storage_service.dart';
import 'core/utils/logger_util.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_service.dart';
import 'features/compress/bindings/compress_binding.dart';

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
/// 顺序：Storage → FileStore → AppController → HttpClient → AuthService → AuthController → CompressService
Future<void> _initServices() async {
  LoggerUtil.i('Starting services... env=${EnvConfig.appEnv}');

  // 1. Storage（其他服务均依赖它）
  await Get.putAsync<StorageService>(() => StorageService().init());

  // 2. FileStore（压缩输出目录）
  await FileStore.instance.init();

  // 3. AppController（主题 & 语言，需要 StorageService）
  Get.put(AppController(), permanent: true);

  // 4. Network
  Get.put<HttpClient>(HttpClient());

  // 5. Auth services & controller（permanent — 全局可访问）
  final authService = Get.put<AuthService>(AuthService(), permanent: true);
  await authService.loadUserFromLocal();
  Get.put(AuthController(), permanent: true);

  // 6. 压缩核心服务（permanent — 队列必须比页面活得久）
  //    通过 CompressBinding 统一注册所有依赖
  CompressBinding().dependencies();

  LoggerUtil.i('All services ready');
}

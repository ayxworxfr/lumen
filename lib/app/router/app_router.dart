import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_service.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/register_page.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/views/home_page.dart';
import '../../features/splash/views/splash_page.dart';
import '../../shared/constants/storage_keys.dart';

/// 路由路径常量
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
}

/// 应用路由配置
///
/// 使用 go_router。[navigatorKey] 暴露给需要在 BuildContext 之外导航的场景
/// （如 Controller 中调用 AppRouter.go('/home')）。
class AppRouter {
  AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: _guard,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, __) {
          AuthBinding().dependencies();
          return const NoTransitionPage(child: LoginPage());
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, __) {
          AuthBinding().dependencies();
          return const CustomTransitionPage(
            child: RegisterPage(),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, __) {
          HomeBinding().dependencies();
          return const NoTransitionPage(child: HomePage());
        },
      ),
    ],
  );

  /// Guards: protect /home when not authenticated.
  /// 使用 sessionActive 布尔标志同步判断登录状态，避免直接读取异步安全存储。
  static String? _guard(BuildContext context, GoRouterState state) {
    final unprotected = {AppRoutes.splash, AppRoutes.login, AppRoutes.register};
    if (unprotected.contains(state.matchedLocation)) return null;

    final storage = Get.find<StorageService>();
    final isLoggedIn = storage.getBool(StorageKeys.sessionActive) ?? false;

    return isLoggedIn ? null : AppRoutes.login;
  }

  // ─── Navigation helpers ──────────────────────────────────

  /// Navigate to [location], replacing the entire stack.
  static void go(String location) => router.go(location);

  /// Push [location] onto the stack.
  static void push(String location) => router.push(location);

  /// Pop the top route if possible.
  static void pop() {
    if (router.canPop()) router.pop();
  }

  // ─── Transitions ─────────────────────────────────────────

  static Widget _slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }
}

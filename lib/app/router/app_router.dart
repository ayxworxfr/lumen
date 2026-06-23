import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_service.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/register_page.dart';
import '../../features/compress/bindings/compress_binding.dart';
import '../../features/compress/views/preset_sheet.dart';
import '../../features/compress/views/progress_page.dart';
import '../../features/gallery/bindings/gallery_binding.dart';
import '../../features/gallery/views/album_page.dart';
import '../../features/gallery/views/edit_page.dart';
import '../../features/gallery/views/gallery_viewer_page.dart';
import '../../features/history/bindings/history_binding.dart';
import '../../features/history/views/compare_page.dart';
import '../../features/history/views/history_page.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/views/main_shell.dart';
import '../../features/home/views/settings_page.dart';
import '../../features/library/bindings/library_binding.dart';
import '../../features/library/controllers/library_controller.dart';
import '../../features/library/models/album_info.dart';
import '../../features/library/models/photo_asset.dart';
import '../../features/library/views/library_page.dart';
import '../../features/splash/views/splash_page.dart';
import '../../shared/constants/storage_keys.dart';

/// 路由路径常量
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const mainLibrary = '/main/library';
  static const mainHistory = '/main/history';
  static const mainSettings = '/main/settings';
  static const compressPreset = '/compress/preset';
  static const compressProgress = '/compress/progress';
  static const galleryViewer = '/gallery/viewer';
  static const galleryAlbum = '/gallery/album';
  static const galleryEdit = '/gallery/edit';

  static String historyDetail(String recordId) => '/history/$recordId';
}

/// 应用路由配置
///
/// 使用 go_router。[navigatorKey] 暴露给需要在 BuildContext 之外导航的场景
/// （如 Controller 中调用 AppRouter.go('/main')）。
class AppRouter {
  AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (_, __, child) {
          HomeBinding().dependencies();
          LibraryBinding().dependencies();
          HistoryBinding().dependencies();
          return NoTransitionPage(child: MainShell(child: child));
        },
        routes: [
          GoRoute(
            path: AppRoutes.mainLibrary,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: LibraryPage()),
          ),
          GoRoute(
            path: AppRoutes.mainHistory,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.mainSettings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.main, redirect: (_, __) => AppRoutes.mainLibrary),
      GoRoute(
        path: AppRoutes.compressPreset,
        pageBuilder: (_, __) {
          CompressBinding().dependencies();
          return const CustomTransitionPage(
            child: PresetSheet(),
            transitionsBuilder: _slideFromBottom,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.compressProgress,
        pageBuilder: (_, __) {
          CompressBinding().dependencies();
          return const CustomTransitionPage(
            child: ProgressPage(),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: '/history/:recordId',
        pageBuilder: (_, state) {
          HistoryBinding().dependencies();
          final recordId = state.pathParameters['recordId']!;
          return CustomTransitionPage(
            child: ComparePage(recordId: recordId),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryViewer,
        pageBuilder: (_, state) {
          GalleryBinding().dependencies();
          final args = state.extra! as GalleryViewerArgs;
          return CustomTransitionPage(
            child: GalleryViewerPage(
              photos: args.photos,
              initialIndex: args.initialIndex,
            ),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryAlbum,
        pageBuilder: (_, state) {
          GalleryBinding().dependencies();
          final album = state.extra! as AlbumInfo;
          return CustomTransitionPage(
            child: AlbumPage(album: album),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryEdit,
        pageBuilder: (_, state) {
          GalleryBinding().dependencies();
          final asset = state.extra! as PhotoAsset;
          return CustomTransitionPage(
            child: EditPage(asset: asset),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
    ],
  );

  /// Guards: protect /main/* when not authenticated.
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

  /// Push [location] onto the stack, optionally passing [extra] data.
  static void push(String location, {Object? extra}) =>
      router.push(location, extra: extra);

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

  static Widget _slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }
}

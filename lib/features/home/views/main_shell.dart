import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../controllers/home_controller.dart';

/// 主 Shell：包含底部 Tab 导航（相册 / 已压缩 / 设置）
class MainShell extends GetView<HomeController> {
  const MainShell({required this.child, super.key});

  final Widget child;

  static int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.mainHistory)) return 1;
    if (location.startsWith(AppRoutes.mainSettings)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(currentLocation);

    // 同步 controller 索引（避免 controller 和路由状态不一致）
    if (controller.currentIndex.value != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.currentIndex.value = currentIndex;
      });
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final l10n = context.l10n;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        controller.currentIndex.value = index;
        switch (index) {
          case 0:
            context.go(AppRoutes.mainLibrary);
          case 1:
            context.go(AppRoutes.mainHistory);
          case 2:
            context.go(AppRoutes.mainSettings);
        }
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.photo_library_outlined),
          selectedIcon: const Icon(Icons.photo_library),
          label: l10n.pagesLibraryTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.compress_outlined),
          selectedIcon: const Icon(Icons.compress),
          label: l10n.pagesHistoryTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.pagesSettingsTitle,
        ),
      ],
    );
  }
}

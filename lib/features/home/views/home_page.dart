import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_tab.dart';
import '../widgets/profile_tab.dart';
import '../widgets/settings_tab.dart';

/// 首页（含底部导航：Home / Profile / Settings）
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = context.l10n;
    return AppBar(
      title: Text(l10n.commonAppName),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      return switch (controller.currentIndex.value) {
        0 => const HomeTab(),
        1 => const ProfileTab(),
        2 => const SettingsTab(),
        _ => const HomeTab(),
      };
    });
  }

  Widget _buildBottomNav(BuildContext context) {
    final l10n = context.l10n;
    return Obx(
      () => NavigationBar(
        selectedIndex: controller.currentIndex.value,
        onDestinationSelected: controller.changeTab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.pagesHomeTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.pagesProfileTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.pagesSettingsTitle,
          ),
        ],
      ),
    );
  }
}

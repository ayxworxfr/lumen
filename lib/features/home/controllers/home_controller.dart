import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../../../core/utils/logger_util.dart';
import '../../auth/services/auth_service.dart';

/// 主 Shell 控制器
///
/// 管理底部 Tab 索引及 Tab 间导航。
class HomeController extends GetxController {
  /// 当前选中的底部导航索引
  final currentIndex = 0.obs;

  AuthService get _authService => Get.find<AuthService>();

  /// 是否已登录
  bool get isLoggedIn => _authService.isLoggedIn;

  /// 当前用户名
  String get displayName =>
      _authService.currentUser.value?.displayName ?? 'Guest';

  @override
  void onInit() {
    super.onInit();
    LoggerUtil.i('MainShell 初始化');
  }

  /// 切换底部导航，并跳转对应路由
  void changeTab(int index) {
    currentIndex.value = index;
    switch (index) {
      case 0:
        AppRouter.go(AppRoutes.mainLibrary);
      case 1:
        AppRouter.go(AppRoutes.mainSettings);
    }
  }
}

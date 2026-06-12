import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

/// 认证模块依赖绑定
///
/// AuthService 已在 main.dart 中以 permanent: true 注册，此处不重复注册。
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // 注入认证控制器（守卫避免重复注册）
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(AuthController.new);
    }
  }
}

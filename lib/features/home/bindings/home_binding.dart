import 'package:get/get.dart';

import '../controllers/home_controller.dart';

/// 主 Shell 依赖绑定
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(HomeController.new);
  }
}

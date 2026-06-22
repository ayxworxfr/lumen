import 'package:get/get.dart';

import '../controllers/library_controller.dart';
import '../services/photo_library_service.dart';

/// 相册模块依赖绑定
class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhotoLibraryService>(PhotoLibraryService.new);
    Get.lazyPut<LibraryController>(
      () => LibraryController(libraryService: Get.find<PhotoLibraryService>()),
    );
  }
}

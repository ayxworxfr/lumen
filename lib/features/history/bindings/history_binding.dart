import 'package:get/get.dart';

import '../../library/services/photo_library_service.dart';
import '../controllers/compare_controller.dart';
import '../controllers/history_controller.dart';
import '../services/compressed_record_repo.dart';
import '../services/history_service.dart';

/// 历史记录模块依赖绑定
class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CompressedRecordRepo>()) {
      Get.lazyPut<CompressedRecordRepo>(CompressedRecordRepo.new);
    }
    if (!Get.isRegistered<PhotoLibraryService>()) {
      Get.lazyPut<PhotoLibraryService>(PhotoLibraryService.new);
    }
    if (!Get.isRegistered<HistoryService>()) {
      Get.lazyPut<HistoryService>(
        () => HistoryService(
          repo: Get.find<CompressedRecordRepo>(),
          libraryService: Get.find<PhotoLibraryService>(),
        ),
      );
    }

    Get.lazyPut<HistoryController>(
      () => HistoryController(historyService: Get.find<HistoryService>()),
    );
    Get.lazyPut<CompareController>(
      () => CompareController(historyService: Get.find<HistoryService>()),
    );
  }
}

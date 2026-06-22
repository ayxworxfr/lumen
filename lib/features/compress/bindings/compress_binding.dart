import 'package:get/get.dart';

import '../../history/services/compressed_record_repo.dart';
import '../../history/services/history_service.dart';
import '../../library/services/photo_library_service.dart';
import '../controllers/compress_controller.dart';
import '../services/compress_service.dart';

/// 压缩模块依赖绑定
class CompressBinding extends Bindings {
  @override
  void dependencies() {
    // CompressedRecordRepo 和 HistoryService 可能已由 HistoryBinding 注册
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

    // CompressService 注册为 permanent，保活跨页面
    if (!Get.isRegistered<CompressService>()) {
      Get.put<CompressService>(
        CompressService(historyService: Get.find<HistoryService>()),
        permanent: true,
      );
    }

    Get.lazyPut<CompressController>(
      () => CompressController(compressService: Get.find<CompressService>()),
    );
  }
}

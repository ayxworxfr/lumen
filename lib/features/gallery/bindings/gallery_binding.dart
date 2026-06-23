import 'package:get/get.dart';

import '../../history/services/compressed_record_repo.dart';

/// Gallery 模块依赖绑定
///
/// GalleryViewerController 和 AlbumController、EditController
/// 由各自 Page 按需 Get.put/delete 管理，此 Binding 仅确保共享依赖可用。
class GalleryBinding extends Bindings {
  @override
  void dependencies() {
    // CompressedRecordRepo 已在 HistoryBinding 注册，此处确保可用即可
    if (!Get.isRegistered<CompressedRecordRepo>()) {
      Get.lazyPut<CompressedRecordRepo>(CompressedRecordRepo.new);
    }
  }
}

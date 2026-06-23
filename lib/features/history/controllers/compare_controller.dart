import 'package:get/get.dart';

import '../../library/services/photo_library_service.dart';
import '../models/compressed_record.dart';
import '../services/history_service.dart';

/// 前后对比控制器（内存级，不持久化）
class CompareController extends GetxController {
  CompareController({
    required HistoryService historyService,
    required PhotoLibraryService photoLibraryService,
  }) : _historyService = historyService,
       _photoLibraryService = photoLibraryService;

  final HistoryService _historyService;
  final PhotoLibraryService _photoLibraryService;

  final record = Rxn<CompressedRecord>();
  final originalPath = Rxn<String>();
  final sliderPosition = 0.5.obs;

  Future<void> loadRecord(String recordId) async {
    final r = _historyService.findById(recordId);
    record.value = r;
    originalPath.value = null;
    if (r != null && !r.originalDeleted) {
      try {
        originalPath.value = await _photoLibraryService.getFilePath(
          r.sourceAssetId,
        );
      } catch (_) {
        // 原图已被外部删除（不经过应用），静默处理，显示占位
      }
    }
  }

  void updateSlider(double position) {
    sliderPosition.value = position.clamp(0.0, 1.0);
  }
}

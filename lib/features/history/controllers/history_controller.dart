import 'package:get/get.dart';

import '../../../core/utils/logger_util.dart';
import '../../compress/models/compress_job.dart';
import '../../compress/services/compress_service.dart';
import '../models/compressed_record.dart';
import '../services/history_service.dart';

/// 已压缩画廊控制器
class HistoryController extends GetxController {
  HistoryController({required HistoryService historyService})
    : _historyService = historyService;

  final HistoryService _historyService;

  final records = <CompressedRecord>[].obs;
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  // ─── 统计 ─────────────────────────────────────────────────

  int get totalSavedBytes => records.fold(0, (sum, r) => sum + r.savedBytes);

  int get totalOriginalBytes =>
      records.fold(0, (sum, r) => sum + r.originalBytes);

  @override
  void onInit() {
    super.onInit();
    loadRecords();
    _subscribeToCompressEvents();
  }

  void _subscribeToCompressEvents() {
    try {
      Get.find<CompressService>().jobStream.listen((job) {
        if (job.status == JobStatus.done) loadRecords();
      });
    } catch (_) {
      // CompressService 未注册时（测试环境）静默忽略
    }
  }

  void loadRecords() {
    isLoading.value = true;
    try {
      records.value = _historyService.loadAll();
    } catch (e) {
      errorMessage.value = e.toString();
      LoggerUtil.e('Load history failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除压缩记录及其 .avif 文件
  Future<void> deleteRecord(String id) async {
    try {
      await _historyService.deleteRecord(id);
      records.removeWhere((r) => r.id == id);
    } catch (e) {
      LoggerUtil.e('Delete record failed', e);
    }
  }

  /// 删除原图（需在 UI 层二次确认后调用）
  Future<bool> deleteOriginal(String recordId) async {
    final success = await _historyService.deleteOriginal(recordId);
    if (success) {
      final idx = records.indexWhere((r) => r.id == recordId);
      if (idx != -1) {
        records[idx] = records[idx].copyWith(originalDeleted: true);
      }
    }
    return success;
  }
}

import 'package:get/get.dart';

import '../models/compressed_record.dart';
import '../services/history_service.dart';

/// 前后对比控制器（内存级，不持久化）
class CompareController extends GetxController {
  CompareController({required HistoryService historyService})
    : _historyService = historyService;

  final HistoryService _historyService;

  final record = Rxn<CompressedRecord>();
  final sliderPosition = 0.5.obs;

  void loadRecord(String recordId) {
    record.value = _historyService.findById(recordId);
  }

  void updateSlider(double position) {
    sliderPosition.value = position.clamp(0.0, 1.0);
  }
}

import 'package:get/get.dart';

import '../../../core/utils/logger_util.dart';
import '../models/compress_job.dart';
import '../services/compress_service.dart';

/// 压缩流程控制器
class CompressController extends GetxController {
  CompressController({required CompressService compressService})
    : _compressService = compressService;

  final CompressService _compressService;

  // ─── 代理 CompressService 数据 ────────────────────────────

  List<CompressJob> get jobs => _compressService.jobs;
  bool get isRunning => _compressService.isRunning.value;

  // ─── 统计 ─────────────────────────────────────────────────

  int get totalJobs => jobs.length;
  int get doneCount => jobs.where((j) => j.status == JobStatus.done).length;
  int get failedCount => jobs.where((j) => j.status == JobStatus.failed).length;
  int get canceledCount =>
      jobs.where((j) => j.status == JobStatus.canceled).length;
  int get pendingCount =>
      jobs.where((j) => j.status == JobStatus.pending).length;
  int get runningCount =>
      jobs.where((j) => j.status == JobStatus.running).length;

  int get totalSavedBytes => _compressService.totalSavedBytes;

  // ─── 操作 ─────────────────────────────────────────────────

  void cancelJob(String jobId) => _compressService.cancel(jobId);

  void cancelAll() => _compressService.cancelAll();

  void retryFailed() => _compressService.retryFailed();

  @override
  void onInit() {
    super.onInit();
    LoggerUtil.i('CompressController 初始化');
  }
}

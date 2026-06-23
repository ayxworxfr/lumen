import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/isolate/compress_worker.dart';
import '../../../core/storage/file_store.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../core/utils/logger_util.dart';
import '../../history/services/history_service.dart';
import '../../library/models/photo_asset.dart';
import '../../library/services/photo_library_service.dart';
import '../models/compress_job.dart';

/// 压缩队列服务
///
/// 维护 CompressJob 队列，调度编码，向 UI 层暴露 jobStream。
/// 注册为 permanent: true，生命周期比页面长。
class CompressService extends GetxService {
  CompressService({
    required HistoryService historyService,
    CompressWorker? worker,
    Future<String> Function(String jobId)? outputPathResolver,
    Future<void> Function(String path)? fileDeleter,
  }) : _historyService = historyService,
       _worker = worker ?? CompressWorker(),
       _outputPathResolver =
           outputPathResolver ?? FileStore.instance.outputPathForId,
       _fileDeleter = fileDeleter ?? FileStore.instance.deleteFile;

  final HistoryService _historyService;
  final CompressWorker _worker;
  final Future<String> Function(String) _outputPathResolver;
  final Future<void> Function(String) _fileDeleter;
  final _uuid = const Uuid();

  /// 当前所有 job（响应式）
  final jobs = <CompressJob>[].obs;

  /// 是否正在运行
  final isRunning = false.obs;

  final _pendingQueue = Queue<CompressJob>();
  final _streamController = StreamController<CompressJob>.broadcast();

  /// job 状态变更流，供外部监听进度
  Stream<CompressJob> get jobStream => _streamController.stream;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _restorePendingJobs();
  }

  @override
  void onClose() {
    _streamController.close();
    super.onClose();
  }

  /// 批量入队
  ///
  /// 不可压缩格式（已是 AVIF 或 unknown）拒绝入队；已在队列中的资源跳过。
  List<String> enqueue(List<PhotoAsset> assets, CompressPreset preset) {
    final ids = <String>[];
    for (final asset in assets) {
      if (!asset.format.isCompressible) {
        LoggerUtil.w('Skipping non-compressible asset: ${asset.id}');
        continue;
      }
      if (_isAlreadyQueued(asset.id)) {
        LoggerUtil.w('Asset already in queue: ${asset.id}');
        continue;
      }

      final job = CompressJob(
        id: _uuid.v4(),
        source: asset,
        preset: preset,
        status: JobStatus.pending,
        queuedAt: DateTime.now(),
      );

      jobs.add(job);
      _pendingQueue.add(job);
      _persistPendingJob(job);
      ids.add(job.id);
    }

    _startProcessingIfIdle();
    return ids;
  }

  /// 取消指定 job
  void cancel(String jobId) {
    _updateJob(jobId, (j) => j.copyWith(status: JobStatus.canceled));
    _pendingQueue.removeWhere((j) => j.id == jobId);
    try {
      HiveBoxes.pendingJobsBox.delete(jobId);
    } catch (_) {}
  }

  /// 取消全部未完成 job
  void cancelAll() {
    for (final job in jobs) {
      if (!job.isFinished) {
        _updateJob(job.id, (j) => j.copyWith(status: JobStatus.canceled));
      }
    }
    _pendingQueue.clear();
    try {
      HiveBoxes.pendingJobsBox.clear();
    } catch (_) {}
  }

  /// 重试失败的 job
  void retryFailed() {
    final failed = jobs.where((j) => j.status == JobStatus.failed).toList();
    for (final job in failed) {
      final retried = job.copyWith(
        status: JobStatus.pending,
        progress: 0,
        errorMessage: null,
        finishedAt: null,
      );
      _updateJobDirect(retried);
      _pendingQueue.add(retried);
      _persistPendingJob(retried);
    }
    _startProcessingIfIdle();
  }

  /// 统计已完成 job 的总节省字节数
  int get totalSavedBytes {
    return jobs
        .where((j) => j.status == JobStatus.done && j.savedBytes != null)
        .fold(0, (sum, j) => sum + j.savedBytes!);
  }

  bool _isAlreadyQueued(String assetId) {
    return jobs.any((j) => j.source.id == assetId && !j.isFinished);
  }

  void _startProcessingIfIdle() {
    if (!isRunning.value) {
      _processNext();
    }
  }

  Future<void> _processNext() async {
    if (_pendingQueue.isEmpty) {
      isRunning.value = false;
      return;
    }

    isRunning.value = true;
    final job = _pendingQueue.removeFirst();

    // 已被取消则跳过
    final current = _findJob(job.id);
    if (current == null || current.status == JobStatus.canceled) {
      return _processNext();
    }

    _updateJob(job.id, (j) => j.copyWith(status: JobStatus.running));

    try {
      final outputPath = await _outputPathResolver(job.id);
      final sourcePath = await _getSourcePath(job);

      if (sourcePath == null) {
        throw Exception(
          'Cannot access source file for asset: ${job.source.id}',
        );
      }

      final result = await _worker.encode(
        sourcePath: sourcePath,
        outputPath: outputPath,
        quality: job.preset.quality,
        speed: job.preset.speed,
        isLossless: job.preset.isLossless,
      );

      // 压缩后体积 >= 原图：删除输出文件，标记无收益
      if (result.outputBytes >= job.source.byteSize) {
        await _fileDeleter(result.outputPath);
        _updateJob(
          job.id,
          (j) => j.copyWith(
            status: JobStatus.failed,
            errorMessage: 'no_savings',
            finishedAt: DateTime.now(),
          ),
        );
      } else {
        final done = _updateJob(
          job.id,
          (j) => j.copyWith(
            status: JobStatus.done,
            outputPath: result.outputPath,
            outputBytes: result.outputBytes,
            progress: 1,
            finishedAt: DateTime.now(),
          ),
        );

        if (done != null) {
          await _historyService.createFromJob(done);
        }
      }
    } catch (e, stack) {
      LoggerUtil.e('Compress job ${job.id} failed', e, stack);
      _updateJob(
        job.id,
        (j) => j.copyWith(
          status: JobStatus.failed,
          errorMessage: e.toString(),
          finishedAt: DateTime.now(),
        ),
      );
    } finally {
      try {
        await HiveBoxes.pendingJobsBox.delete(job.id);
      } catch (_) {}
    }

    return _processNext();
  }

  Future<String?> _getSourcePath(CompressJob job) async {
    if (job.source.path != null) return job.source.path;
    try {
      return Get.find<PhotoLibraryService>().getFilePath(job.source.id);
    } catch (_) {
      return null;
    }
  }

  CompressJob? _updateJob(
    String id,
    CompressJob Function(CompressJob) updater,
  ) {
    final idx = jobs.indexWhere((j) => j.id == id);
    if (idx == -1) return null;
    final updated = updater(jobs[idx]);
    jobs[idx] = updated;
    _streamController.add(updated);
    return updated;
  }

  void _updateJobDirect(CompressJob updated) {
    final idx = jobs.indexWhere((j) => j.id == updated.id);
    if (idx != -1) {
      jobs[idx] = updated;
      _streamController.add(updated);
    }
  }

  CompressJob? _findJob(String id) {
    try {
      return jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistPendingJob(CompressJob job) async {
    try {
      await HiveBoxes.pendingJobsBox.put(job.id, job.toJson());
    } catch (e) {
      // 持久化失败不应中断队列（仅影响跨重启恢复）
      LoggerUtil.w('Failed to persist pending job ${job.id}: $e');
    }
  }

  /// 恢复跨重启未完成的队列
  Future<void> _restorePendingJobs() async {
    Iterable<dynamic> keys;
    try {
      keys = HiveBoxes.pendingJobsBox.keys;
    } catch (_) {
      return; // Hive 未初始化（测试环境）
    }
    final pending = <CompressJob>[];
    for (final key in keys) {
      try {
        final raw = HiveBoxes.pendingJobsBox.get(key);
        if (raw == null) continue;
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        final job = CompressJob.fromJson(map);
        // running 状态在上次进程崩溃时未完成，重置为 pending
        pending.add(
          job.status == JobStatus.running
              ? job.copyWith(status: JobStatus.pending, progress: 0)
              : job,
        );
      } catch (e) {
        LoggerUtil.w('Failed to restore pending job: $e');
      }
    }

    if (pending.isNotEmpty) {
      jobs.addAll(pending);
      _pendingQueue.addAll(pending.where((j) => j.status == JobStatus.pending));
      _startProcessingIfIdle();
      LoggerUtil.i('Restored ${pending.length} pending jobs');
    }
  }
}

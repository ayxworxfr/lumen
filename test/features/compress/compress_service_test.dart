import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lumen/core/codec/avif_encoder.dart';
import 'package:lumen/core/isolate/compress_worker.dart';
import 'package:lumen/features/compress/models/compress_job.dart';
import 'package:lumen/features/compress/services/compress_service.dart';
import 'package:lumen/features/history/models/compressed_record.dart';
import 'package:lumen/features/history/services/compressed_record_repo.dart';
import 'package:lumen/features/history/services/history_service.dart';
import 'package:lumen/features/library/models/photo_asset.dart';
import 'package:lumen/features/library/services/photo_library_service.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

/// 可控编码器：设 errorToThrow 让 encode 抛异常，否则返回 successResult
class FakeEncoder implements AvifEncoder {
  AvifEncodeResult? successResult;
  Exception? errorToThrow;

  @override
  bool get isSupported => true;

  @override
  Future<AvifEncodeResult> encode({
    required String sourcePath,
    required String outputPath,
    required int quality,
    required int speed,
    bool isLossless = false,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return successResult!;
  }
}

/// 永远挂起的编码器，让任务卡在 running 状态（用于测试 cancel）
class HangingEncoder implements AvifEncoder {
  @override
  bool get isSupported => true;

  @override
  Future<AvifEncodeResult> encode({
    required String sourcePath,
    required String outputPath,
    required int quality,
    required int speed,
    bool isLossless = false,
  }) => Completer<AvifEncodeResult>().future;
}

class FakeCompressedRecordRepo extends CompressedRecordRepo {
  @override
  Future<void> save(CompressedRecord record) async {}
  @override
  List<CompressedRecord> loadAll() => [];
  @override
  CompressedRecord? findById(String id) => null;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> update(CompressedRecord record) async {}
}

class FakePhotoLibraryService extends PhotoLibraryService {
  @override
  Future<String?> getFilePath(String assetId) async => null;
}

/// 记录 createFromJob 调用，不访问 Hive
class FakeHistoryService extends HistoryService {
  FakeHistoryService()
    : super(
        repo: FakeCompressedRecordRepo(),
        libraryService: FakePhotoLibraryService(),
      );

  final List<CompressJob> created = [];

  @override
  Future<CompressedRecord> createFromJob(CompressJob job) async {
    created.add(job);
    return CompressedRecord(
      id: job.id,
      sourceAssetId: job.source.id,
      outputPath: job.outputPath!,
      originalBytes: job.source.byteSize,
      compressedBytes: job.outputBytes!,
      preset: job.preset,
      originalFormat: job.source.format,
      compressedAt: job.finishedAt!,
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

PhotoAsset _asset({
  String id = 'asset_1',
  int byteSize = 1024 * 1024,
  String? path = '/source/photo.jpg',
  ImageFormat format = ImageFormat.jpeg,
}) => PhotoAsset(
  id: id,
  byteSize: byteSize,
  format: format,
  width: 1920,
  height: 1080,
  createdAt: DateTime(2026),
  path: path,
);

CompressService _buildService({
  required FakeHistoryService history,
  required FakeEncoder encoder,
}) {
  final worker = CompressWorker(encoder: encoder);
  return CompressService(
    historyService: history,
    worker: worker,
    outputPathResolver: (_) async => '/output/test.avif',
    fileDeleter: (_) async {},
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  // ── enqueue 过滤逻辑 ─────────────────────────────────────────────────────

  group('enqueue() — 过滤逻辑', () {
    test('AVIF 格式不可压缩，跳过入队', () async {
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..successResult =
            const AvifEncodeResult(outputPath: '/out.avif', outputBytes: 500);
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      final ids = service.enqueue(
        [_asset(format: ImageFormat.avif)],
        CompressPreset.balanced,
      );

      expect(ids, isEmpty);
      expect(service.jobs, isEmpty);
    });

    test('unknown 格式跳过入队', () async {
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..successResult =
            const AvifEncodeResult(outputPath: '/out.avif', outputBytes: 500);
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      final ids = service.enqueue(
        [_asset(format: ImageFormat.unknown)],
        CompressPreset.balanced,
      );

      expect(ids, isEmpty);
    });

    test('同一资源二次入队被跳过', () async {
      final history = FakeHistoryService();
      // 用 HangingEncoder 让第一个 job 卡在 running，避免处理完成后与 tearDown 竞争
      final worker = CompressWorker(encoder: HangingEncoder());
      final service = Get.put(CompressService(
        historyService: history,
        worker: worker,
        outputPathResolver: (_) async => '/output/test.avif',
        fileDeleter: (_) async {},
      ));
      await service.onInit();

      final asset = _asset();
      service.enqueue([asset], CompressPreset.balanced);
      final ids2 = service.enqueue([asset], CompressPreset.balanced);

      expect(ids2, isEmpty);
    });
  });

  // ── 压缩失败路径（定位 Android 失败原因） ─────────────────────────────────

  group('压缩失败路径', () {
    test('F-1: 源文件路径为 null → job.status = failed，errorMessage 含提示', () async {
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..successResult =
            const AvifEncodeResult(outputPath: '/out.avif', outputBytes: 500);
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      // path: null 且未注册 PhotoLibraryService → _getSourcePath 返回 null
      final ids = service.enqueue(
        [_asset(path: null)],
        CompressPreset.balanced,
      );
      expect(ids, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final job = service.jobs.first;
      expect(job.status, equals(JobStatus.failed));
      expect(
        job.errorMessage,
        contains('Cannot access source file'),
        reason: '源文件路径为 null 时应透传 Cannot access source file',
      );
      expect(history.created, isEmpty);
    });

    test('F-2: 编码器抛出异常 → job.status = failed，errorMessage 含异常信息', () async {
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..errorToThrow =
            Exception('MethodChannel: encode failed — channel not available');
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      service.enqueue([_asset()], CompressPreset.balanced);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final job = service.jobs.first;
      expect(job.status, equals(JobStatus.failed));
      expect(
        job.errorMessage,
        contains('encode failed'),
        reason: '编码器异常信息应透传到 errorMessage',
      );
      expect(history.created, isEmpty);
    });

    test('F-3: 压缩无收益（输出 >= 原图）→ job.status = failed，errorMessage = no_savings',
        () async {
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..successResult = const AvifEncodeResult(
          outputPath: '/out.avif',
          outputBytes: 1024 * 1024 + 1,
        );
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      service.enqueue([_asset()], CompressPreset.balanced);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final job = service.jobs.first;
      expect(job.status, equals(JobStatus.failed));
      expect(job.errorMessage, equals('no_savings'));
      expect(history.created, isEmpty);
    });
  });

  // ── 压缩成功路径 ─────────────────────────────────────────────────────────

  group('压缩成功路径', () {
    test('F-4: 编码成功 → job.status = done，调用 historyService.createFromJob',
        () async {
      const sourceBytes = 1024 * 1024;
      const compressedBytes = 400 * 1024;
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..successResult = const AvifEncodeResult(
          outputPath: '/output/test.avif',
          outputBytes: compressedBytes,
        );
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      service.enqueue([_asset()], CompressPreset.balanced);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final job = service.jobs.first;
      expect(job.status, equals(JobStatus.done));
      expect(job.outputBytes, equals(compressedBytes));
      expect(job.savedBytes, equals(sourceBytes - compressedBytes));
      expect(history.created, hasLength(1));
      expect(history.created.first.id, equals(job.id));
    });

    test('totalSavedBytes 汇总所有 done 任务的节省量', () async {
      const bytes1 = 1024 * 1024;
      const bytes2 = 2 * 1024 * 1024;
      const compressed = 400 * 1024;
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..successResult =
            const AvifEncodeResult(outputPath: '/out.avif', outputBytes: compressed);
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      service.enqueue([
        _asset(id: 'a1'),
        _asset(id: 'a2', byteSize: bytes2),
      ], CompressPreset.balanced);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        service.totalSavedBytes,
        equals((bytes1 - compressed) + (bytes2 - compressed)),
      );
    });
  });

  // ── cancel / retryFailed ──────────────────────────────────────────────────

  group('cancel() 与 retryFailed()', () {
    test('cancel() 将 pending job 标记为 canceled', () async {
      final history = FakeHistoryService();
      // 第一个 job 会卡在 running（HangingEncoder），第二个保持 pending
      final worker = CompressWorker(encoder: HangingEncoder());
      final service = Get.put(CompressService(
        historyService: history,
        worker: worker,
        outputPathResolver: (_) async => '/output/test.avif',
        fileDeleter: (_) async {},
      ));
      await service.onInit();

      final ids = service.enqueue([
        _asset(id: 'a1'),
        _asset(id: 'a2'),
      ], CompressPreset.balanced);

      // 取消第二个（仍在 pending queue）
      service.cancel(ids[1]);

      final job2 = service.jobs.firstWhere((j) => j.id == ids[1]);
      expect(job2.status, equals(JobStatus.canceled));
    });

    test('retryFailed() 将失败任务重新处理为 done', () async {
      final history = FakeHistoryService();
      final encoder = FakeEncoder()
        ..errorToThrow = Exception('encode error');
      final service = Get.put(_buildService(history: history, encoder: encoder));
      await service.onInit();

      service.enqueue([_asset()], CompressPreset.balanced);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(service.jobs.first.status, equals(JobStatus.failed));

      // 切换为成功，然后重试
      encoder
        ..errorToThrow = null
        ..successResult = const AvifEncodeResult(
          outputPath: '/out.avif',
          outputBytes: 400 * 1024,
        );

      service.retryFailed();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(service.jobs.first.status, equals(JobStatus.done));
    });
  });
}

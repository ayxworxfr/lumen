import 'package:get/get.dart';

import '../../../core/storage/file_store.dart';
import '../../../core/utils/logger_util.dart';
import '../../compress/models/compress_job.dart';
import '../../library/services/photo_library_service.dart';
import 'compressed_record_repo.dart';
import '../models/compressed_record.dart';

/// 历史记录服务
///
/// 负责从 CompressedRecordRepo 读写记录，并协调删除原图和压缩文件操作。
class HistoryService extends GetxService {
  HistoryService({
    required CompressedRecordRepo repo,
    required PhotoLibraryService libraryService,
  }) : _repo = repo,
       _libraryService = libraryService;

  final CompressedRecordRepo _repo;
  final PhotoLibraryService _libraryService;

  /// 从完成的 CompressJob 创建并保存记录
  Future<CompressedRecord> createFromJob(CompressJob job) async {
    final record = CompressedRecord(
      id: job.id,
      sourceAssetId: job.source.id,
      outputPath: job.outputPath!,
      originalBytes: job.source.byteSize,
      compressedBytes: job.outputBytes!,
      preset: job.preset,
      originalFormat: job.source.format,
      compressedAt: job.finishedAt ?? DateTime.now(),
    );
    await _repo.save(record);
    return record;
  }

  /// 加载全部记录
  List<CompressedRecord> loadAll() => _repo.loadAll();

  /// 按 ID 查询
  CompressedRecord? findById(String id) => _repo.findById(id);

  /// 删除压缩记录及对应的 .avif 文件
  Future<void> deleteRecord(String id) async {
    final record = _repo.findById(id);
    if (record == null) return;

    await FileStore.instance.deleteFile(record.outputPath);
    await _repo.delete(id);
    LoggerUtil.i('Deleted compressed record: $id');
  }

  /// 删除原图（二次操作，需 UI 强提示后调用）
  Future<bool> deleteOriginal(String recordId) async {
    final record = _repo.findById(recordId);
    if (record == null) return false;

    try {
      final deleted = await _libraryService.deleteAssets([
        record.sourceAssetId,
      ]);
      if (deleted.contains(record.sourceAssetId)) {
        await _repo.update(record.copyWith(originalDeleted: true));
        LoggerUtil.i('Original asset deleted: ${record.sourceAssetId}');
        return true;
      }
      return false;
    } catch (e) {
      LoggerUtil.e('Failed to delete original asset', e);
      return false;
    }
  }
}

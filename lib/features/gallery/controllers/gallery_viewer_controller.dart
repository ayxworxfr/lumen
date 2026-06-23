import 'package:get/get.dart';

import '../../history/models/compressed_record.dart';
import '../../history/services/compressed_record_repo.dart';
import '../../library/controllers/library_controller.dart';
import '../../library/models/photo_asset.dart';

/// 全屏查看器控制器
///
/// 生命周期跟随 GalleryViewerPage，由 GalleryBinding 以 fenix: false 注册。
class GalleryViewerController extends GetxController {
  GalleryViewerController({
    required List<PhotoAsset> initialPhotos,
    required int initialIndex,
  }) : _initialPhotos = initialPhotos,
       _initialIndex = initialIndex;

  final List<PhotoAsset> _initialPhotos;
  final int _initialIndex;

  final photos = <PhotoAsset>[].obs;
  final currentIndex = 0.obs;

  /// 已压缩图片的 sourceAssetId 集合
  final compressedAssetIds = <String>{}.obs;

  /// 当前图片是否已压缩
  bool get isCurrentCompressed {
    if (photos.isEmpty) return false;
    return compressedAssetIds.contains(photos[currentIndex.value].id);
  }

  PhotoAsset get currentPhoto => photos[currentIndex.value];

  @override
  void onInit() {
    super.onInit();
    photos.assignAll(_initialPhotos);
    currentIndex.value = _initialIndex;
    _loadCompressedIds();
  }

  void _loadCompressedIds() {
    try {
      final repo = Get.find<CompressedRecordRepo>();
      final records = repo.loadAll();
      compressedAssetIds.assignAll(records.map((r) => r.sourceAssetId).toSet());
    } catch (_) {}
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    // 临近末尾时触发分页加载
    if (index >= photos.length - 5) {
      _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    try {
      final libraryCtrl = Get.find<LibraryController>();
      libraryCtrl.loadMore().then((_) {
        // 追加新图片到查看器的 photos 列表
        final current = photos.map((p) => p.id).toSet();
        final newPhotos = libraryCtrl.photos
            .where((p) => !current.contains(p.id))
            .toList();
        if (newPhotos.isNotEmpty) {
          photos.addAll(newPhotos);
        }
      });
    } catch (_) {}
  }

  /// 查找当前图片对应的压缩记录（用于"对比"按钮）
  CompressedRecord? findRecordForCurrent() {
    return findRecordForAsset(currentPhoto.id);
  }

  CompressedRecord? findRecordForAsset(String assetId) {
    try {
      final repo = Get.find<CompressedRecordRepo>();
      final records = repo.loadAll();
      return records.firstWhere((r) => r.sourceAssetId == assetId);
    } catch (_) {
      return null;
    }
  }

  /// 压缩后刷新压缩 ID 集合（用于 action bar 状态更新）
  void refreshCompressedIds() => _loadCompressedIds();
}

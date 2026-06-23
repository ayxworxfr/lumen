import 'package:get/get.dart';

import '../../../core/utils/logger_util.dart';
import '../../library/models/album_info.dart';
import '../../library/models/photo_asset.dart';
import '../../library/services/photo_library_service.dart';

/// 相册详情控制器（查看单个系统相册内的图片）
class AlbumController extends GetxController {
  AlbumController({
    required AlbumInfo album,
    required PhotoLibraryService libraryService,
  }) : _album = album,
       _libraryService = libraryService;

  final AlbumInfo _album;
  final PhotoLibraryService _libraryService;

  AlbumInfo get album => _album;

  final photos = <PhotoAsset>[].obs;
  final isLoading = false.obs;

  int _page = 0;
  static const _pageSize = 80;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    isLoading.value = true;
    _page = 0;
    hasMore.value = true;
    try {
      final list = await _libraryService.getAlbumPhotos(
        albumId: _album.albumId,
        page: _page,
      );
      photos.value = list;
      hasMore.value = list.length == _pageSize;
      _page++;
    } catch (e) {
      LoggerUtil.e('Load album photos failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final list = await _libraryService.getAlbumPhotos(
        albumId: _album.albumId,
        page: _page,
      );
      photos.addAll(list);
      hasMore.value = list.length == _pageSize;
      _page++;
    } finally {
      isLoadingMore.value = false;
    }
  }
}

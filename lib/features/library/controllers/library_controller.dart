import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../app/router/app_router.dart';
import '../../../core/utils/logger_util.dart';
import '../../compress/models/compress_job.dart';
import '../../compress/services/compress_service.dart';
import '../../history/services/compressed_record_repo.dart';
import '../models/album_info.dart';
import '../models/photo_asset.dart';
import '../services/photo_library_service.dart';

/// 相册排序方式
enum LibrarySortOrder { bySize, byDate }

/// 相册浏览模式（Tab 切换）
enum LibraryTabMode { byTime, byAlbum }

/// 相册浏览控制器
class LibraryController extends GetxController {
  LibraryController({required PhotoLibraryService libraryService})
    : _libraryService = libraryService;

  final PhotoLibraryService _libraryService;

  // ─── 状态 ─────────────────────────────────────────────────

  final photos = <PhotoAsset>[].obs;
  final isLoading = false.obs;
  final hasPermission = false.obs;
  final isLimitedAccess = false.obs;
  final selectedIds = <String>{}.obs;
  final isSelectionMode = false.obs;
  final sortOrder = LibrarySortOrder.bySize.obs;
  final errorMessage = Rxn<String>();

  // 相册模式
  final tabMode = LibraryTabMode.byTime.obs;
  final albums = <AlbumInfo>[].obs;
  final isLoadingAlbums = false.obs;

  // 已压缩资源 ID 集合（用于网格 AVIF 徽章）
  final compressedAssetIds = <String>{}.obs;

  // 分页
  int _page = 0;
  static const _pageSize = 80;
  final hasMore = true.obs;
  final isLoadingMore = false.obs;

  // ─── 派生数据 ─────────────────────────────────────────────

  /// 潜在可节省字节数（基于当前已加载图片估算，balanced 预设约 50%）
  int get estimatedSavings {
    return photos.fold(0, (sum, p) => sum + p.estimatedSavings);
  }

  List<PhotoAsset> get selectedAssets =>
      photos.where((p) => selectedIds.contains(p.id)).toList();

  bool isSelected(String id) => selectedIds.contains(id);

  bool isCompressed(String id) => compressedAssetIds.contains(id);

  @override
  void onInit() {
    super.onInit();
    _initLibrary();
  }

  Future<void> _initLibrary() async {
    isLoading.value = true;
    try {
      final state = await _libraryService.getPermissionState();
      if (state == PermissionState.limited) {
        isLimitedAccess.value = true;
        hasPermission.value = true;
      } else if (state.isAuth) {
        hasPermission.value = true;
      } else {
        final granted = await _libraryService.requestPermission();
        hasPermission.value = granted;
        if (!granted) {
          isLoading.value = false;
          return;
        }
      }
      await Future.wait([loadPhotos(), loadCompressedIds()]);
    } on MissingPluginException {
      // photo_manager has no web implementation — treat as no permission
    } catch (e) {
      errorMessage.value = e.toString();
      LoggerUtil.e('Library init failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载第一页（刷新）
  Future<void> loadPhotos() async {
    _page = 0;
    hasMore.value = true;
    final list = await _libraryService.getPhotos(page: _page);
    photos.value = _sortedPhotos(list);
    hasMore.value = list.length == _pageSize;
    _page++;
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final list = await _libraryService.getPhotos(page: _page);
      photos.addAll(_sortedPhotos(list));
      hasMore.value = list.length == _pageSize;
      _page++;
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 加载系统相册列表
  Future<void> loadAlbums() async {
    if (isLoadingAlbums.value) return;
    isLoadingAlbums.value = true;
    try {
      albums.value = await _libraryService.getAlbums();
    } catch (e) {
      LoggerUtil.e('Load albums failed', e);
    } finally {
      isLoadingAlbums.value = false;
    }
  }

  /// 刷新已压缩资源 ID 集合
  Future<void> loadCompressedIds() async {
    try {
      final repo = Get.find<CompressedRecordRepo>();
      final records = repo.loadAll();
      compressedAssetIds.assignAll(records.map((r) => r.sourceAssetId).toSet());
    } catch (_) {
      // CompressedRecordRepo 未注册时（如 web 或测试），静默忽略
    }
  }

  void switchTabMode(LibraryTabMode mode) {
    tabMode.value = mode;
    if (mode == LibraryTabMode.byAlbum && albums.isEmpty) {
      loadAlbums();
    }
  }

  List<PhotoAsset> _sortedPhotos(List<PhotoAsset> list) {
    final sorted = List<PhotoAsset>.from(list);
    if (sortOrder.value == LibrarySortOrder.bySize) {
      sorted.sort((a, b) => b.byteSize.compareTo(a.byteSize));
    } else {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  void changeSortOrder(LibrarySortOrder order) {
    sortOrder.value = order;
    photos.value = _sortedPhotos(photos);
  }

  // ─── 选择模式 ─────────────────────────────────────────────

  void enterSelectionMode([String? firstSelectedId]) {
    isSelectionMode.value = true;
    if (firstSelectedId != null) selectedIds.add(firstSelectedId);
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedIds.clear();
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void selectAll() {
    selectedIds.addAll(photos.map((p) => p.id));
  }

  void clearSelection() {
    selectedIds.clear();
  }

  // ─── 查看器 ───────────────────────────────────────────────

  /// 打开全屏查看器，[index] 为图片在 photos 列表中的下标
  void openViewer(int index) {
    AppRouter.push(
      AppRoutes.galleryViewer,
      extra: GalleryViewerArgs(photos: photos.toList(), initialIndex: index),
    );
  }

  // ─── 压缩 ─────────────────────────────────────────────────

  /// 使用指定预设入队，并跳转进度页
  void enqueueWithPreset(CompressPreset preset) {
    final compressService = Get.find<CompressService>();
    compressService.enqueue(selectedAssets, preset);
    exitSelectionMode();
    AppRouter.go(AppRoutes.compressProgress);
  }
}

/// 查看器路由参数
class GalleryViewerArgs {
  const GalleryViewerArgs({required this.photos, required this.initialIndex});

  final List<PhotoAsset> photos;
  final int initialIndex;
}

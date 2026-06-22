import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/utils/logger_util.dart';
import '../models/photo_asset.dart';

/// 系统相册访问服务
///
/// 封装 photo_manager 包，提供统一的相册浏览接口。
/// 权限拒绝时抛出异常，由控制器处理 UX。
class PhotoLibraryService extends GetxService {
  /// 请求相册权限
  ///
  /// 返回 true 表示有足够权限（full 或 limited）。
  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    LoggerUtil.i('Photo permission state: $state');
    return state.isAuth || state == PermissionState.limited;
  }

  /// 获取相册权限状态（不弹权限请求框）
  Future<PermissionState> getPermissionState() async {
    return PhotoManager.requestPermissionExtend();
  }

  /// 获取所有图片（分页）
  ///
  /// [page] 从 0 开始，[pageSize] 每页数量
  /// [filterMinBytes] 过滤小于该字节数的图片（默认 0，不过滤）
  Future<List<PhotoAsset>> getPhotos({
    int page = 0,
    int pageSize = 80,
    int filterMinBytes = 0,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    if (albums.isEmpty) return [];

    // 取"全部图片"相册（通常是第一个 hasAll 专辑）
    final allAlbum = albums.first;
    final entities = await allAlbum.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    final assets = <PhotoAsset>[];
    for (final entity in entities) {
      final byteSize = entity.width * entity.height * 3; // 估算，不精确

      // 精确文件大小
      int fileSize = 0;
      try {
        final file = await entity.file;
        if (file != null) {
          fileSize = await file.length();
        }
      } catch (e) {
        LoggerUtil.w('Cannot get file size for ${entity.id}: $e');
      }

      if (fileSize == 0) fileSize = byteSize;
      if (fileSize < filterMinBytes) continue;

      final mimeType = entity.mimeType;
      final format = ImageFormat.fromMimeType(mimeType);

      assets.add(
        PhotoAsset(
          id: entity.id,
          byteSize: fileSize,
          format: format,
          width: entity.width,
          height: entity.height,
          createdAt: entity.createDateTime,
          mimeType: mimeType,
        ),
      );
    }

    return assets;
  }

  /// 获取相册总图片数量
  Future<int> getTotalPhotoCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    if (albums.isEmpty) return 0;
    return albums.first.assetCountAsync;
  }

  /// 通过 AssetEntity ID 获取文件路径（用于传给编码器）
  Future<String?> getFilePath(String assetId) async {
    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) return null;
    final file = await entity.file;
    return file?.path;
  }

  /// 删除原图（需要系统弹窗确认）
  ///
  /// 返回成功删除的 ID 列表。
  Future<List<String>> deleteAssets(List<String> assetIds) async {
    final result = await PhotoManager.editor.deleteWithIds(assetIds);
    return result;
  }
}

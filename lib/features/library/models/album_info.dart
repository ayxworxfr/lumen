/// 系统相册信息（内存对象，不需要序列化）
class AlbumInfo {
  const AlbumInfo({
    required this.albumId,
    required this.name,
    required this.count,
    this.coverAssetId,
  });

  final String albumId;
  final String name;
  final int count;

  /// 封面图片的 photo_manager asset ID，可为 null（相册为空时）
  final String? coverAssetId;
}

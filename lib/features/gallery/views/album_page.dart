import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../app/router/app_router.dart';
import '../../../core/widgets/app_loading.dart';
import '../../library/controllers/library_controller.dart';
import '../../library/models/album_info.dart';
import '../../library/models/photo_asset.dart';
import '../../library/services/photo_library_service.dart';
import '../controllers/album_controller.dart';

/// 系统相册详情页（展示单个相册内所有图片）
class AlbumPage extends StatefulWidget {
  const AlbumPage({required this.album, super.key});

  final AlbumInfo album;

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  late final AlbumController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      AlbumController(
        album: widget.album,
        libraryService: Get.find<PhotoLibraryService>(),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<AlbumController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        centerTitle: true,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_ctrl.photos.length} 张',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) return AppLoading.page();
        if (_ctrl.photos.isEmpty) {
          return const Center(
            child: Text('相册为空', style: TextStyle(color: Colors.grey)),
          );
        }
        return _buildGrid(context);
      }),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 400) {
          _ctrl.loadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _ctrl.photos.length,
        itemBuilder: (context, index) {
          final asset = _ctrl.photos[index];
          return _AlbumPhotoCell(asset: asset, onTap: () => _openViewer(index));
        },
      ),
    );
  }

  void _openViewer(int index) {
    // 从 LibraryController 获取压缩 ID 状态，传入查看器
    AppRouter.push(
      AppRoutes.galleryViewer,
      extra: GalleryViewerArgs(
        photos: _ctrl.photos.toList(),
        initialIndex: index,
      ),
    );
  }
}

class _AlbumPhotoCell extends StatelessWidget {
  const _AlbumPhotoCell({required this.asset, required this.onTap});

  final PhotoAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: FutureBuilder<Uint8List?>(
          future: _loadThumbnail(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            );
          },
        ),
      ),
    );
  }

  Future<Uint8List?> _loadThumbnail() async {
    final entity = await AssetEntity.fromId(asset.id);
    return entity?.thumbnailDataWithSize(const ThumbnailSize(200, 200));
  }
}

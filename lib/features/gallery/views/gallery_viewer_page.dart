import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../compress/models/compress_job.dart';
import '../../compress/services/compress_service.dart';
import '../../library/models/photo_asset.dart';
import '../controllers/gallery_viewer_controller.dart';

/// 全屏图片查看器
///
/// 支持左右滑动翻页、捏放缩放，底部操作栏根据压缩状态动态切换。
class GalleryViewerPage extends StatefulWidget {
  const GalleryViewerPage({
    required this.photos,
    required this.initialIndex,
    super.key,
  });

  final List<PhotoAsset> photos;
  final int initialIndex;

  @override
  State<GalleryViewerPage> createState() => _GalleryViewerPageState();
}

class _GalleryViewerPageState extends State<GalleryViewerPage> {
  late final GalleryViewerController _ctrl;
  late final PageController _pageController;

  // 每页各自的 TransformationController，用于检测缩放状态
  final _transformControllers = <int, TransformationController>{};
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      GalleryViewerController(
        initialPhotos: widget.photos,
        initialIndex: widget.initialIndex,
      ),
    );
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    for (final c in _transformControllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    Get.delete<GalleryViewerController>();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  TransformationController _transformFor(int index) {
    return _transformControllers.putIfAbsent(
      index,
      TransformationController.new,
    );
  }

  void _onZoomChanged(bool zoomed) {
    if (_isZoomed != zoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(l10n),
      body: Obx(
        () => PageView.builder(
          controller: _pageController,
          itemCount: _ctrl.photos.length,
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: (index) {
            _ctrl.onPageChanged(index);
            // 翻页时重置缩放状态
            if (_isZoomed) setState(() => _isZoomed = false);
          },
          itemBuilder: (context, index) {
            final asset = _ctrl.photos[index];
            return _ZoomablePhoto(
              assetId: asset.id,
              byteSize: asset.byteSize,
              transformController: _transformFor(index),
              onZoomChanged: _onZoomChanged,
            );
          },
        ),
      ),
      bottomNavigationBar: Obx(() => _buildActionBar(l10n)),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: const BackButton(),
      title: Obx(() {
        return Text(
          l10n.pagesGalleryPhotoIndex(
            _ctrl.currentIndex.value + 1,
            _ctrl.photos.length,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showMoreMenu(context),
        ),
      ],
    );
  }

  Widget _buildActionBar(AppLocalizations l10n) {
    final isCompressed = _ctrl.isCurrentCompressed;

    return Container(
      color: Colors.black87,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isCompressed
            ? _buildCompressedActions(l10n)
            : _buildUncompressedActions(l10n),
      ),
    );
  }

  Widget _buildUncompressedActions(AppLocalizations l10n) {
    return Row(
      key: const ValueKey('uncompressed'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.share_outlined,
          label: l10n.pagesGalleryShare,
          onTap: _shareCurrentPhoto,
        ),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: l10n.pagesGalleryEdit,
          onTap: _openEdit,
        ),
        _ActionButton(
          icon: Icons.compress,
          label: l10n.pagesGalleryCompress,
          onTap: () => _showCompressSheet(context, l10n),
          highlighted: true,
        ),
      ],
    );
  }

  Widget _buildCompressedActions(AppLocalizations l10n) {
    return Row(
      key: const ValueKey('compressed'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.share_outlined,
          label: l10n.pagesGalleryShare,
          onTap: _shareCurrentPhoto,
        ),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: l10n.pagesGalleryEdit,
          onTap: _openEdit,
        ),
        _ActionButton(
          icon: Icons.compare,
          label: l10n.pagesGalleryCompare,
          onTap: _openCompare,
          highlighted: true,
        ),
      ],
    );
  }

  Future<void> _shareCurrentPhoto() async {
    final photo = _ctrl.currentPhoto;
    final entity = await AssetEntity.fromId(photo.id);
    final file = await entity?.file;
    if (file == null) return;
    await Share.shareXFiles([
      XFile(file.path, mimeType: photo.mimeType ?? 'image/jpeg'),
    ]);
  }

  void _openEdit() {
    AppRouter.push(AppRoutes.galleryEdit, extra: _ctrl.currentPhoto);
  }

  void _openCompare() {
    final record = _ctrl.findRecordForCurrent();
    if (record == null) return;
    AppRouter.push(AppRoutes.historyDetail(record.id));
  }

  void _showCompressSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CompressPresetSheet(
        l10n: l10n,
        onSelected: (preset) {
          final compressService = Get.find<CompressService>();
          compressService.enqueue([_ctrl.currentPhoto], preset);
          AppRouter.push(AppRoutes.compressProgress);
          _ctrl.refreshCompressedIds();
        },
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    // 预留扩展菜单（例如：删除、信息等）
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(_ctrl.currentPhoto.displaySize),
              subtitle: Text(
                '${_ctrl.currentPhoto.width} × ${_ctrl.currentPhoto.height}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 可缩放单张图片 ────────────────────────────────────────────

// 超过此大小才做两段式加载（先缩略图，再全图）
const _kLargeFileThreshold = 2 * 1024 * 1024; // 2 MB

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    required this.assetId,
    required this.byteSize,
    required this.transformController,
    required this.onZoomChanged,
  });

  final String assetId;
  final int byteSize;
  final TransformationController transformController;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  Uint8List? _thumbnail;
  File? _fullFile;

  @override
  void initState() {
    super.initState();
    widget.transformController.addListener(_onTransformChanged);
    _loadProgressive();
  }

  @override
  void dispose() {
    widget.transformController.removeListener(_onTransformChanged);
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = widget.transformController.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05);
  }

  Future<void> _loadProgressive() async {
    final entity = await AssetEntity.fromId(widget.assetId);
    if (entity == null || !mounted) return;

    // Stage 1: OS-cached thumbnail — typically < 100 ms
    if (widget.byteSize >= _kLargeFileThreshold) {
      // 大文件才先显示缩略图，避免用户等待全图加载
      final thumb = await entity.thumbnailDataWithSize(
        const ThumbnailSize(800, 800),
      );
      if (!mounted) return;
      if (thumb != null) setState(() => _thumbnail = thumb);
    }

    // Stage 2: full-resolution file
    final file = await entity.file;
    if (!mounted) return;
    setState(() => _fullFile = file);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: widget.transformController,
      minScale: 1,
      maxScale: 5,
      child: Center(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    if (_fullFile != null) {
      return Image.file(
        _fullFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.grey, size: 64),
      );
    }
    if (_thumbnail != null) {
      return Image.memory(_thumbnail!, fit: BoxFit.contain);
    }
    return const AppLoading();
  }
}

// ─── Action button ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primary : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── 压缩预设选择底部弹层 ──────────────────────────────────────

class _CompressPresetSheet extends StatelessWidget {
  const _CompressPresetSheet({required this.l10n, required this.onSelected});

  final AppLocalizations l10n;
  final void Function(CompressPreset) onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.pagesCompressSelectPreset,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            Icons.compress,
            Colors.green,
            l10n.pagesCompressPresetSmaller,
            l10n.pagesCompressPresetSmallerDesc,
            CompressPreset.smaller,
          ),
          _buildTile(
            context,
            Icons.balance,
            AppColors.primary,
            l10n.pagesCompressPresetBalanced,
            l10n.pagesCompressPresetBalancedDesc,
            CompressPreset.balanced,
            isDefault: true,
          ),
          _buildTile(
            context,
            Icons.high_quality,
            Colors.purple,
            l10n.pagesCompressPresetHigherQuality,
            l10n.pagesCompressPresetHigherQualityDesc,
            CompressPreset.higherQuality,
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    CompressPreset preset, {
    bool isDefault = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Default',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.of(context).pop();
        onSelected(preset);
      },
    );
  }
}

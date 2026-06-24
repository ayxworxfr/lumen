import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../compress/services/savings_estimator.dart';
import '../controllers/history_controller.dart';
import '../models/compressed_record.dart';
import 'compressed_viewer_page.dart';

/// 已压缩 AVIF 画廊（嵌入 PhotosPage 第二段落，非独立路由页）
///
/// 网格单元格使用原图缩略图展示，避免在网格中解码 AVIF 带来的性能开销。
class CompressedGalleryPage extends GetView<HistoryController> {
  const CompressedGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return AppLoading.page();
      if (controller.records.isEmpty) return _buildEmpty(context);

      return RefreshIndicator(
        onRefresh: () async => controller.loadRecords(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildStatsHeader(context)),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildCell(i),
                childCount: controller.records.length,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsHeader(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = controller.records.length;
    final savedStr = SavingsEstimator.formatBytes(controller.totalSavedBytes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.success.withValues(alpha: 0.1),
      child: Text(
        l10n.pagesCompressedGalleryStats(count, savedStr),
        style: TextStyle(
          color: isDark ? AppColors.success : AppColors.success,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final record = controller.records[index];
    return GestureDetector(
      onTap: () => AppRouter.push(
        AppRoutes.compressedViewer,
        extra: CompressedViewerArgs(
          records: controller.records.toList(),
          initialIndex: index,
        ),
      ),
      child: _RecordCell(record: record),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pagesCompressedGalleryEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 网格单元格（原图缩略图 + 节省百分比角标）─────────────────────

class _RecordCell extends StatefulWidget {
  const _RecordCell({required this.record});

  final CompressedRecord record;

  @override
  State<_RecordCell> createState() => _RecordCellState();
}

class _RecordCellState extends State<_RecordCell> {
  late final Future<Uint8List?> _future = _loadThumbnail();

  Future<Uint8List?> _loadThumbnail() async {
    final entity = await AssetEntity.fromId(widget.record.sourceAssetId);
    return entity?.thumbnailDataWithSize(const ThumbnailSize(300, 300));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List?>(
          future: _future,
          builder: (_, snap) {
            if (snap.hasData) {
              return Image.memory(
                snap.data!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              );
            }
            if (snap.connectionState == ConnectionState.done) {
              return _placeholder();
            }
            return const AppLoading();
          },
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${widget.record.displaySavedPercent}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => ColoredBox(
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
    ),
  );
}

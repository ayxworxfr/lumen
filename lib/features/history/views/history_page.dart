import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../compress/services/savings_estimator.dart';
import '../controllers/history_controller.dart';
import '../models/compressed_record.dart';

/// 已压缩画廊页
class HistoryPage extends GetView<HistoryController> {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pagesHistoryTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() => _buildBody(context, l10n)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (controller.isLoading.value) return AppLoading.page();

    if (controller.records.isEmpty) {
      return AppEmpty.noData();
    }

    return Column(
      children: [
        _buildSummaryHeader(context, l10n),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => controller.loadRecords(),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: controller.records.length,
              itemBuilder: (_, i) =>
                  _buildRecordCard(context, l10n, controller.records[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(BuildContext context, AppLocalizations l10n) {
    final saved = controller.totalSavedBytes;
    if (saved <= 0) return const SizedBox.shrink();

    final savedStr = SavingsEstimator.formatBytes(saved);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.success.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            l10n.pagesHistoryTotalSaved(savedStr),
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            l10n.pagesHistoryCount(controller.records.length),
            style: const TextStyle(color: AppColors.success, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    AppLocalizations l10n,
    CompressedRecord record,
  ) {
    return GestureDetector(
      onTap: () => AppRouter.push(AppRoutes.historyDetail(record.id)),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildAvifPreview(record),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${record.displaySavedPercent}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.displayOriginalSize} → ${record.displayCompressedSize}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  Text(
                    l10n.pagesHistorySaved(record.displaySavedSize),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvifPreview(CompressedRecord record) =>
      _RecordThumbnail(record: record);
}

// ─── 原图缩略图（替代直接显示 AVIF，Android < API 31 不支持 AVIF 解码）────

class _RecordThumbnail extends StatefulWidget {
  const _RecordThumbnail({required this.record});

  final CompressedRecord record;

  @override
  State<_RecordThumbnail> createState() => _RecordThumbnailState();
}

class _RecordThumbnailState extends State<_RecordThumbnail> {
  late final Future<Uint8List?> _future = _loadThumbnail();

  Future<Uint8List?> _loadThumbnail() async {
    final entity = await AssetEntity.fromId(widget.record.sourceAssetId);
    return entity?.thumbnailDataWithSize(const ThumbnailSize(400, 400));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const _ThumbnailPlaceholder();
        }
        return const AppLoading();
      },
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
    );
  }
}

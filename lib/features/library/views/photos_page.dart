import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../compress/models/compress_job.dart';
import '../../compress/widgets/compress_progress_bar.dart';
import '../../history/views/compressed_gallery_page.dart';
import '../controllers/library_controller.dart';
import '../models/photo_asset.dart';
import '../widgets/album_grid_widget.dart';
import '../widgets/photo_grid_cell.dart';

/// 照片 Tab 主页
///
/// 段落 0：原图网格（含按时间/按相册切换、多选压缩）
/// 段落 1：已压缩 AVIF 画廊
class PhotosPage extends GetView<LibraryController> {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
      body: Obx(() => _buildBody(context, l10n)),
      bottomNavigationBar: Obx(
        () =>
            controller.isSelectionMode.value &&
                controller.photosSegment.value == 0
            ? _buildSelectionBar(context, l10n)
            : const SizedBox.shrink(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      title: Obx(() {
        if (controller.isSelectionMode.value &&
            controller.photosSegment.value == 0) {
          return Text(
            l10n.pagesLibrarySelectedCount(controller.selectedIds.length),
          );
        }
        return Text(l10n.pagesPhotosTitle);
      }),
      centerTitle: true,
      elevation: 0,
      actions: [
        Obx(() {
          if (controller.photosSegment.value != 0) {
            return const SizedBox.shrink();
          }
          if (controller.isSelectionMode.value) {
            return TextButton(
              onPressed: controller.exitSelectionMode,
              child: Text(l10n.commonCancel),
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.tabMode.value == LibraryTabMode.byTime)
                PopupMenuButton<LibrarySortOrder>(
                  icon: const Icon(Icons.sort),
                  onSelected: controller.changeSortOrder,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: LibrarySortOrder.bySize,
                      child: Text(l10n.pagesLibrarySortBySize),
                    ),
                    PopupMenuItem(
                      value: LibrarySortOrder.byDate,
                      child: Text(l10n.pagesLibrarySortByDate),
                    ),
                  ],
                ),
              TextButton(
                onPressed: () => controller.enterSelectionMode(),
                child: Text(l10n.pagesLibrarySelect),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        CompressProgressBar(
          onViewCompressed: () {
            if (controller.isSelectionMode.value) {
              controller.exitSelectionMode();
            }
            controller.photosSegment.value = 1;
          },
        ),
        _buildSegmentControl(context, l10n),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: controller.photosSegment.value == 0
                ? _buildLibrarySegment(context, l10n)
                : const CompressedGalleryPage(key: ValueKey('compressed')),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentControl(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey.shade200,
          ),
        ),
      ),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: controller.photosSegment.value,
        onValueChanged: (v) {
          if (v == null) return;
          controller.photosSegment.value = v;
          if (controller.isSelectionMode.value) {
            controller.exitSelectionMode();
          }
        },
        children: {
          0: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(l10n.pagesPhotosSegmentOriginals),
          ),
          1: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(l10n.pagesPhotosSegmentCompressed),
          ),
        },
      ),
    );
  }

  Widget _buildLibrarySegment(BuildContext context, AppLocalizations l10n) {
    if (controller.isLoading.value) {
      return AppLoading.page();
    }
    if (!controller.hasPermission.value) {
      return _buildPermissionDenied(context, l10n);
    }
    return Column(
      key: const ValueKey('library'),
      children: [
        if (controller.isLimitedAccess.value)
          _buildLimitedAccessBanner(context, l10n),
        _buildTabBar(context, l10n),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: controller.tabMode.value == LibraryTabMode.byTime
                ? const _ByTimeView(key: ValueKey('byTime'))
                : const _ByAlbumView(key: ValueKey('byAlbum')),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          _TabItem(
            label: l10n.pagesLibraryByTime,
            isSelected: controller.tabMode.value == LibraryTabMode.byTime,
            onTap: () => controller.switchTabMode(LibraryTabMode.byTime),
          ),
          _TabItem(
            label: l10n.pagesLibraryByAlbum,
            isSelected: controller.tabMode.value == LibraryTabMode.byAlbum,
            onTap: () => controller.switchTabMode(LibraryTabMode.byAlbum),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedAccessBanner(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.pagesLibraryLimitedAccess,
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
          TextButton(
            onPressed: kIsWeb ? null : PhotoManager.openSetting,
            child: Text(
              l10n.pagesLibraryGoSettings,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pagesLibraryPermissionDenied,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.pagesLibraryGoSettings,
              onPressed: kIsWeb ? null : PhotoManager.openSetting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.pagesLibrarySelectedCount(controller.selectedIds.length),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: controller.selectAll,
              child: Text(l10n.commonSelectAll),
            ),
            const SizedBox(width: 8),
            AppButton(
              text: l10n.pagesLibraryCompress,
              onPressed: controller.selectedIds.isEmpty
                  ? null
                  : () => _showPresetSheet(context, l10n),
              size: AppButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PresetPickerSheet(
        onSelected: controller.enqueueWithPreset,
        l10n: l10n,
      ),
    );
  }
}

// ─── Tab 指示器 ────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── 按时间视图 ────────────────────────────────────────────────────

class _ByTimeView extends GetView<LibraryController> {
  const _ByTimeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.photos.isEmpty) return AppEmpty.noData();

      final photos = controller.photos.toList();
      final groups = _groupByYearMonth(photos);

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 400) {
            controller.loadMore();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            if (controller.estimatedSavings > 0)
              SliverToBoxAdapter(child: _buildSavingsHeader(context)),
            for (final entry in groups.entries) ...[
              SliverToBoxAdapter(
                child: _buildGroupHeader(
                  context,
                  entry.key,
                  entry.value.length,
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final asset = entry.value[i];
                  final globalIndex = photos.indexOf(asset);
                  return Obx(
                    () => PhotoGridCell(
                      asset: asset,
                      isSelected: controller.isSelected(asset.id),
                      isSelectionMode: controller.isSelectionMode.value,
                      isCompressed: controller.isCompressed(asset.id),
                      onTap: () {
                        if (controller.isSelectionMode.value) {
                          controller.toggleSelection(asset.id);
                        } else {
                          controller.openViewer(globalIndex);
                        }
                      },
                      onLongPress: () {
                        if (!controller.isSelectionMode.value) {
                          controller.enterSelectionMode(asset.id);
                        }
                      },
                    ),
                  );
                }, childCount: entry.value.length),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSavingsHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingsMB = (controller.estimatedSavings / (1024 * 1024))
        .toStringAsFixed(1);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        l10n.pagesLibraryEstimatedSavings(savingsMB),
        style: TextStyle(
          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, String title, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 按年月分组，保持原有顺序
  Map<String, List<PhotoAsset>> _groupByYearMonth(List<PhotoAsset> photos) {
    final groups = <String, List<PhotoAsset>>{};
    for (final photo in photos) {
      final key = '${photo.createdAt.year}年${photo.createdAt.month}月';
      (groups[key] ??= []).add(photo);
    }
    return groups;
  }
}

// ─── 按相册视图 ────────────────────────────────────────────────────

class _ByAlbumView extends GetView<LibraryController> {
  const _ByAlbumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingAlbums.value) return AppLoading.page();
      if (controller.albums.isEmpty) return AppEmpty.noData();

      return AlbumGridWidget(
        albums: controller.albums.toList(),
        onAlbumTap: (album) =>
            AppRouter.push(AppRoutes.galleryAlbum, extra: album),
      );
    });
  }
}

// ─── 压缩预设选择底部弹层 ──────────────────────────────────────────

class _PresetPickerSheet extends StatelessWidget {
  const _PresetPickerSheet({required this.onSelected, required this.l10n});

  final void Function(CompressPreset) onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.pagesCompressSelectPreset,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPresetTile(
            context,
            icon: Icons.compress,
            iconColor: Colors.green,
            title: l10n.pagesCompressPresetSmaller,
            subtitle: l10n.pagesCompressPresetSmallerDesc,
            preset: CompressPreset.smaller,
          ),
          _buildPresetTile(
            context,
            icon: Icons.balance,
            iconColor: AppColors.primary,
            title: l10n.pagesCompressPresetBalanced,
            subtitle: l10n.pagesCompressPresetBalancedDesc,
            preset: CompressPreset.balanced,
            isDefault: true,
          ),
          _buildPresetTile(
            context,
            icon: Icons.high_quality,
            iconColor: Colors.purple,
            title: l10n.pagesCompressPresetHigherQuality,
            subtitle: l10n.pagesCompressPresetHigherQualityDesc,
            preset: CompressPreset.higherQuality,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required CompressPreset preset,
    bool isDefault = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
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
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.of(context).pop();
        onSelected(preset);
      },
    );
  }
}

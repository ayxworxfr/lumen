import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../compress/models/compress_job.dart';
import '../controllers/library_controller.dart';
import '../widgets/photo_grid.dart';

/// 系统相册浏览页
class LibraryPage extends GetView<LibraryController> {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context, l10n, isDark),
      body: Obx(() => _buildBody(context, l10n)),
      bottomNavigationBar: Obx(
        () => controller.selectedIds.isNotEmpty
            ? _buildSelectionBar(context, l10n)
            : const SizedBox.shrink(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return AppBar(
      title: Text(l10n.pagesLibraryTitle),
      centerTitle: true,
      elevation: 0,
      actions: [
        Obx(
          () => controller.selectedIds.isNotEmpty
              ? TextButton(
                  onPressed: controller.clearSelection,
                  child: Text(l10n.commonCancel),
                )
              : PopupMenuButton<LibrarySortOrder>(
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
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (controller.isLoading.value) {
      return AppLoading.page();
    }

    if (!controller.hasPermission.value) {
      return _buildPermissionDenied(context, l10n);
    }

    if (controller.photos.isEmpty) {
      return AppEmpty.noData();
    }

    return Column(
      children: [
        if (controller.isLimitedAccess.value)
          _buildLimitedAccessBanner(context, l10n),
        _buildSavingsHeader(context, l10n),
        const Expanded(child: PhotoGrid()),
      ],
    );
  }

  Widget _buildSavingsHeader(BuildContext context, AppLocalizations l10n) {
    final savings = controller.estimatedSavings;
    if (savings <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingsMB = (savings / (1024 * 1024)).toStringAsFixed(1);

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
            onPressed: kIsWeb ? null : () => PhotoManager.openSetting(),
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
              onPressed: kIsWeb ? null : () => PhotoManager.openSetting(),
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
              onPressed: () => _showPresetSheet(context, l10n),
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

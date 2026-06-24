import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/compress_controller.dart';
import '../services/savings_estimator.dart';

/// 压缩进度横幅
///
/// 当队列有任务时显示，任务全部完成后提供快速跳转到已压缩画廊的入口。
/// 队列为空时折叠为零高度。
class CompressProgressBar extends GetView<CompressController> {
  const CompressProgressBar({this.onViewCompressed, super.key});

  final VoidCallback? onViewCompressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Obx(() {
      final total = controller.totalJobs;
      if (total == 0) return const SizedBox.shrink();

      final done = controller.doneCount;
      final allDone = done == total;
      final savedStr = SavingsEstimator.formatBytes(controller.totalSavedBytes);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: allDone
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  if (!allDone)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allDone
                          ? l10n.pagesPhotosProgressDone(savedStr)
                          : l10n.pagesPhotosProgressRunning(done, total),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (allDone && onViewCompressed != null)
                    GestureDetector(
                      onTap: onViewCompressed,
                      child: Text(
                        l10n.pagesPhotosSegmentCompressed,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (!allDone)
                    GestureDetector(
                      onTap: controller.cancelAll,
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            if (!allDone)
              LinearProgressIndicator(
                value: total > 0 ? done / total : 0,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
          ],
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/compress_controller.dart';
import '../models/compress_job.dart';
import '../services/savings_estimator.dart';

/// 压缩队列进度页
class ProgressPage extends GetView<CompressController> {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pagesCompressProgress),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() => _buildBody(context, l10n)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final jobs = controller.jobs;

    if (jobs.isEmpty) {
      return Center(child: Text(l10n.pagesCompressNoJobs));
    }

    final allFinished = jobs.every((j) => j.isFinished);

    return Column(
      children: [
        _buildSummaryHeader(context, l10n, allFinished),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (_, i) => _buildJobTile(context, l10n, jobs[i]),
          ),
        ),
        _buildActionBar(context, l10n, allFinished),
      ],
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool allFinished,
  ) {
    final done = controller.doneCount;
    final total = controller.totalJobs;
    final saved = SavingsEstimator.formatBytes(controller.totalSavedBytes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            allFinished
                ? l10n.pagesCompressDone
                : l10n.pagesCompressRunning(done, total),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (done > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.pagesCompressSaved(saved),
              style: const TextStyle(color: AppColors.success),
            ),
          ],
          if (!allFinished) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobTile(
    BuildContext context,
    AppLocalizations l10n,
    CompressJob job,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildStatusIcon(job),
        title: Text(
          job.source.displaySize,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: _buildJobSubtitle(l10n, job),
        trailing:
            job.status == JobStatus.pending || job.status == JobStatus.running
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined),
                onPressed: () => controller.cancelJob(job.id),
              )
            : null,
      ),
    );
  }

  Widget _buildStatusIcon(CompressJob job) {
    switch (job.status) {
      case JobStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.grey);
      case JobStatus.running:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case JobStatus.done:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case JobStatus.failed:
        return const Icon(Icons.error_outline, color: AppColors.error);
      case JobStatus.canceled:
        return const Icon(Icons.cancel, color: Colors.grey);
    }
  }

  Widget? _buildJobSubtitle(AppLocalizations l10n, CompressJob job) {
    switch (job.status) {
      case JobStatus.done:
        if (job.savedBytes != null) {
          final pct = ((1 - (job.compressionRatio ?? 1)) * 100).toInt();
          return Text(
            l10n.pagesCompressJobSaved(pct),
            style: const TextStyle(color: AppColors.success),
          );
        }
        return null;
      case JobStatus.failed:
        final msg = job.errorMessage;
        if (msg == 'no_savings') {
          return Text(l10n.pagesCompressNoSavings);
        }
        return Text(
          l10n.pagesCompressJobFailed,
          style: const TextStyle(color: AppColors.error),
        );
      case JobStatus.pending:
        return Text(l10n.pagesCompressJobPending);
      case JobStatus.running:
        return Text(l10n.pagesCompressJobRunning);
      case JobStatus.canceled:
        return Text(l10n.pagesCompressJobCanceled);
    }
  }

  Widget _buildActionBar(
    BuildContext context,
    AppLocalizations l10n,
    bool allFinished,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (controller.failedCount > 0 && allFinished)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppButton(
                    text: l10n.pagesCompressRetryFailed(controller.failedCount),
                    onPressed: controller.retryFailed,
                    type: AppButtonType.secondary,
                  ),
                ),
              ),
            Expanded(
              child: AppButton(
                text: allFinished
                    ? l10n.pagesCompressViewHistory
                    : l10n.pagesCompressCancelAll,
                onPressed: allFinished
                    ? controller.goToHistory
                    : controller.cancelAll,
                type: allFinished
                    ? AppButtonType.primary
                    : AppButtonType.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

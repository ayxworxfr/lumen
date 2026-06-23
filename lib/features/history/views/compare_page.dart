import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/compare_controller.dart';
import '../controllers/history_controller.dart';
import '../models/compressed_record.dart';
import '../widgets/before_after_slider.dart';

/// 前后对比详情页
class ComparePage extends StatefulWidget {
  const ComparePage({required this.recordId, super.key});

  final String recordId;

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  late final CompareController _compareCtrl;
  late final HistoryController _historyCtrl;

  @override
  void initState() {
    super.initState();
    _compareCtrl = Get.find<CompareController>();
    _historyCtrl = Get.find<HistoryController>();
    _compareCtrl.loadRecord(
      widget.recordId,
    ); // async — originalPath updates via Rxn
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pagesCompareTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        final record = _compareCtrl.record.value;
        if (record == null) {
          return Center(child: Text(l10n.pagesCompareNotFound));
        }

        return Column(
          children: [
            Expanded(
              child: BeforeAfterSlider(
                originalPath: _compareCtrl.originalPath.value,
                compressedPath: record.outputPath,
              ),
            ),
            _buildInfoPanel(context, l10n, record),
            _buildActionBar(context, l10n, record),
          ],
        );
      }),
    );
  }

  Widget _buildInfoPanel(
    BuildContext context,
    AppLocalizations l10n,
    CompressedRecord record,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(l10n.pagesCompareOriginal, record.displayOriginalSize),
          const Icon(Icons.arrow_forward, color: Colors.grey),
          _buildStat(l10n.pagesCompareCompressed, record.displayCompressedSize),
          _buildStat(
            l10n.pagesCompareSaved,
            '-${record.displaySavedPercent}',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    AppLocalizations l10n,
    CompressedRecord record,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            if (!record.originalDeleted)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppButton(
                    text: l10n.pagesCompareDeleteOriginal,
                    onPressed: () => _confirmDeleteOriginal(context, l10n),
                    type: AppButtonType.danger,
                  ),
                ),
              ),
            Expanded(
              child: AppButton(
                text: l10n.pagesCompareRollback,
                onPressed: () => _confirmRollback(context, l10n),
                type: AppButtonType.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOriginal(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.pagesCompareDeleteOriginalTitle),
        content: Text(l10n.pagesCompareDeleteOriginalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _historyCtrl.deleteOriginal(widget.recordId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  void _confirmRollback(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.pagesCompareRollbackTitle),
        content: Text(l10n.pagesCompareRollbackConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _historyCtrl.deleteRecord(widget.recordId);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

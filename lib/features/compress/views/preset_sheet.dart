import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/compress_controller.dart';
import '../models/compress_job.dart';

/// 预设选择页（作为独立路由，供非 LibraryPage 场景使用）
class PresetSheet extends GetView<CompressController> {
  const PresetSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pagesCompressSelectPreset),
        leading: CloseButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPresetCard(
            context,
            l10n,
            icon: Icons.compress,
            iconColor: Colors.green,
            title: l10n.pagesCompressPresetSmaller,
            description: l10n.pagesCompressPresetSmallerDesc,
            preset: CompressPreset.smaller,
          ),
          const SizedBox(height: 12),
          _buildPresetCard(
            context,
            l10n,
            icon: Icons.balance,
            iconColor: AppColors.primary,
            title: l10n.pagesCompressPresetBalanced,
            description: l10n.pagesCompressPresetBalancedDesc,
            preset: CompressPreset.balanced,
            isRecommended: true,
          ),
          const SizedBox(height: 12),
          _buildPresetCard(
            context,
            l10n,
            icon: Icons.high_quality,
            iconColor: Colors.purple,
            title: l10n.pagesCompressPresetHigherQuality,
            description: l10n.pagesCompressPresetHigherQualityDesc,
            preset: CompressPreset.higherQuality,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    AppLocalizations l10n, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required CompressPreset preset,
    bool isRecommended = false,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isRecommended) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text(
                  'Recommended',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
        trailing: AppButton(
          text: l10n.commonConfirm,
          onPressed: () => Navigator.of(context).pop(preset),
          size: AppButtonSize.small,
        ),
      ),
    );
  }
}

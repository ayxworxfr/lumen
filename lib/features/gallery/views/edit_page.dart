import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../compress/models/compress_job.dart';
import '../../compress/services/compress_service.dart';
import '../../library/models/photo_asset.dart';
import '../../library/services/photo_library_service.dart';
import '../controllers/edit_controller.dart';

/// 图片编辑页
///
/// 提供亮度 / 对比度 / 饱和度实时预览（ColorFiltered），
/// 以及裁剪（image_cropper）。保存时选择新文件或覆盖原图。
class EditPage extends StatefulWidget {
  const EditPage({required this.asset, super.key});

  final PhotoAsset asset;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final EditController _ctrl;
  String? _sourcePath;
  bool _isLoadingSource = true;

  @override
  void initState() {
    super.initState();
    _loadSourcePath();
  }

  Future<void> _loadSourcePath() async {
    final path = await Get.find<PhotoLibraryService>().getFilePath(
      widget.asset.id,
    );
    if (!mounted) return;

    if (path == null) {
      setState(() => _isLoadingSource = false);
      return;
    }

    _ctrl = Get.put(EditController(asset: widget.asset, sourcePath: path));
    setState(() {
      _sourcePath = path;
      _isLoadingSource = false;
    });
  }

  @override
  void dispose() {
    if (_sourcePath != null) Get.delete<EditController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context, l10n),
      body: _isLoadingSource
          ? AppLoading.page()
          : _sourcePath == null
          ? _buildLoadFailed()
          : _buildEditor(context, l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(
        l10n.pagesEditTitle,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        if (_sourcePath != null)
          Obx(
            () => TextButton(
              onPressed: _ctrl.isSaving.value
                  ? null
                  : () => _onSaveTapped(context, l10n),
              child: _ctrl.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l10n.commonSave,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadFailed() {
    return const Center(
      child: Text('无法读取原图', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildEditor(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(child: _buildPreview()),
        _buildToolbar(context, l10n),
      ],
    );
  }

  Widget _buildPreview() {
    return Obx(() {
      final matrix = _buildColorMatrix(
        brightness: _ctrl.brightness.value,
        contrast: _ctrl.contrast.value,
        saturation: _ctrl.saturation.value,
      );

      return ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: Center(
          child: FutureBuilder<File?>(
            // key 变化时重新加载（裁剪后路径更新）
            key: ValueKey(_ctrl.currentSourcePath),
            future: _loadPreviewFile(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const AppLoading();
              }
              final file = snapshot.data;
              if (file == null) {
                return const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 64,
                );
              }
              return Image.file(file, fit: BoxFit.contain);
            },
          ),
        ),
      );
    });
  }

  Future<File?> _loadPreviewFile() async {
    final path = _ctrl.currentSourcePath;
    final f = File(path);
    if (f.existsSync()) return f;
    // 如果是系统资源（AssetEntity 路径），通过 photo_manager 获取
    final entity = await AssetEntity.fromId(widget.asset.id);
    return entity?.file;
  }

  Widget _buildToolbar(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 裁剪 / 旋转 / 重置 工具按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: Icons.crop,
                label: l10n.pagesEditCrop,
                onTap: () => _ctrl.crop(),
              ),
              _ToolButton(
                icon: Icons.rotate_right,
                label: l10n.pagesEditRotate,
                onTap: _onRotateTapped,
              ),
              Obx(
                () => _ToolButton(
                  icon: Icons.refresh,
                  label: l10n.pagesEditReset,
                  onTap: _ctrl.hasChanges ? _ctrl.resetAll : null,
                  dimmed: !_ctrl.hasChanges,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 调节滑条
          Obx(
            () => Column(
              children: [
                _AdjustSlider(
                  label: l10n.pagesEditBrightness,
                  value: _ctrl.brightness.value,
                  min: 0.5,
                  max: 1.5,
                  onChanged: (v) => _ctrl.brightness.value = v,
                ),
                _AdjustSlider(
                  label: l10n.pagesEditContrast,
                  value: _ctrl.contrast.value,
                  min: 0.5,
                  max: 1.5,
                  onChanged: (v) => _ctrl.contrast.value = v,
                ),
                _AdjustSlider(
                  label: l10n.pagesEditSaturation,
                  value: _ctrl.saturation.value,
                  min: 0,
                  max: 2,
                  onChanged: (v) => _ctrl.saturation.value = v,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onRotateTapped() {
    // 旋转通过 image_cropper 实现：打开裁剪界面，用户可自行旋转
    _ctrl.crop();
  }

  void _onSaveTapped(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SaveOptionsSheet(
        l10n: l10n,
        onSaveNew: () => _doSave(context, l10n, overwrite: false),
        onOverwrite: () => _doSave(context, l10n, overwrite: true),
      ),
    );
  }

  Future<void> _doSave(
    BuildContext context,
    AppLocalizations l10n, {
    required bool overwrite,
  }) async {
    // 在 async gap 前捕获 Navigator 和 Messenger，避免跨异步使用 BuildContext
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    navigator.pop(); // 关闭 bottom sheet
    final savedPath = await _ctrl.save(overwriteOriginal: overwrite);

    if (!mounted) return;

    if (savedPath == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pagesEditSaveFailed)));
      return;
    }

    // 保存成功后询问是否立即压缩
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.pagesEditSavedSuccess),
        action: SnackBarAction(
          label: l10n.pagesEditCompressNow,
          onPressed: () => _compressEditedFile(savedPath),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _compressEditedFile(String editedPath) {
    // 创建一个临时 PhotoAsset 代表编辑后的文件（不在系统相册中）
    final editedAsset = widget.asset.copyWith(path: editedPath);
    final compressService = Get.find<CompressService>();
    compressService.enqueue([editedAsset], CompressPreset.balanced);
  }
}

// ─── 保存选项底部弹层 ──────────────────────────────────────────

class _SaveOptionsSheet extends StatelessWidget {
  const _SaveOptionsSheet({
    required this.l10n,
    required this.onSaveNew,
    required this.onOverwrite,
  });

  final AppLocalizations l10n;
  final VoidCallback onSaveNew;
  final VoidCallback onOverwrite;

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
            l10n.pagesEditSaveTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _SaveOptionTile(
            icon: Icons.file_copy_outlined,
            title: l10n.pagesEditSaveNew,
            subtitle: l10n.pagesEditSaveNewDesc,
            onTap: () {
              Navigator.of(context).pop();
              onSaveNew();
            },
          ),
          _SaveOptionTile(
            icon: Icons.swap_horiz,
            title: l10n.pagesEditOverwrite,
            subtitle: l10n.pagesEditOverwriteDesc,
            destructive: true,
            onTap: () {
              Navigator.of(context).pop();
              onOverwrite();
            },
          ),
        ],
      ),
    );
  }
}

class _SaveOptionTile extends StatelessWidget {
  const _SaveOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red[300]! : Colors.white;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

// ─── 工具按钮 ──────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? Colors.grey[700]! : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── 调节滑条 ──────────────────────────────────────────────────

class _AdjustSlider extends StatelessWidget {
  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toStringAsFixed(2),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── ColorFilter 矩阵计算 ──────────────────────────────────────

/// 将亮度 / 对比度 / 饱和度合并为单个 4×5 ColorFilter 矩阵。
///
/// 数学推导见注释：亮度偏移 → 对比度缩放 → 饱和度（Rec.709 权重），三步合一。
List<double> _buildColorMatrix({
  required double brightness, // 0.5–1.5，1.0=无变化
  required double contrast, // 0.5–1.5，1.0=无变化
  required double saturation, // 0.0–2.0，1.0=无变化
}) {
  // Rec.709 亮度权重
  const rw = 0.2126;
  const gw = 0.7152;
  const bw = 0.0722;

  final bOffset = (brightness - 1.0) * 255.0;
  final c = contrast;
  final cOffset = 128.0 * (1.0 - c);
  final combinedOffset = c * bOffset + cOffset;

  final s = saturation;

  // 最终矩阵系数 = contrast × saturation 组合
  return [
    c * (s + rw * (1 - s)),
    c * gw * (1 - s),
    c * bw * (1 - s),
    0,
    combinedOffset,
    c * rw * (1 - s),
    c * (s + gw * (1 - s)),
    c * bw * (1 - s),
    0,
    combinedOffset,
    c * rw * (1 - s),
    c * gw * (1 - s),
    c * (s + bw * (1 - s)),
    0,
    combinedOffset,
    0,
    0,
    0,
    1,
    0,
  ];
}

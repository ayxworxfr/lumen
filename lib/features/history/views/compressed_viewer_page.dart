import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../../../core/codec/android/android_avif_encoder.dart'
    if (dart.library.html) '../../../core/codec/web/web_avif_encoder_stub.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/platform/platform_file.dart' as pf;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../library/services/photo_library_service.dart';
import '../controllers/history_controller.dart';
import '../models/compressed_record.dart';
import '../widgets/before_after_slider.dart';

/// 导航参数：传递记录快照和初始索引
class CompressedViewerArgs {
  const CompressedViewerArgs({
    required this.records,
    required this.initialIndex,
  });

  final List<CompressedRecord> records;
  final int initialIndex;
}

/// 全屏 AVIF 查看器
///
/// 左右滑动翻页，长按显示 BeforeAfterSlider 对比覆盖层，
/// 点击 ⓘ 图标展开底部信息面板（节省数据、删除原图、回滚操作）。
class CompressedViewerPage extends StatefulWidget {
  const CompressedViewerPage({
    required this.records,
    required this.initialIndex,
    super.key,
  });

  final List<CompressedRecord> records;
  final int initialIndex;

  @override
  State<CompressedViewerPage> createState() => _CompressedViewerPageState();
}

class _CompressedViewerPageState extends State<CompressedViewerPage> {
  late final PageController _pageController;

  /// 查看器持有自己的记录副本，以便删除原图后本地更新 originalDeleted 状态
  late final List<CompressedRecord> _records;

  late int _currentIndex;
  bool _showCompare = false;
  String? _originalPath;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  CompressedRecord get _current => _records[_currentIndex];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.pagesGalleryPhotoIndex(_currentIndex + 1, _records.length),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _records.length,
            onPageChanged: (i) => setState(() {
              _currentIndex = i;
              _showCompare = false;
              _originalPath = null;
            }),
            itemBuilder: (_, i) => GestureDetector(
              onLongPress: _toggleCompare,
              child: _AvifImageView(record: _records[i]),
            ),
          ),
          if (_showCompare)
            BeforeAfterSlider(
              originalPath: _originalPath,
              compressedPath: _current.outputPath,
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context, l10n),
          ),
          if (!_showCompare)
            Positioned(
              bottom: 92,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.pagesCompressedViewerLongPress,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _OverlayStat(
            label: l10n.pagesCompareOriginal,
            value: _current.displayOriginalSize,
            color: Colors.white70,
          ),
          const Icon(Icons.arrow_forward, color: Colors.white38, size: 14),
          _OverlayStat(
            label: l10n.pagesCompareCompressed,
            value: _current.displayCompressedSize,
          ),
          _OverlayStat(
            label: l10n.pagesCompareSaved,
            value: '-${_current.displaySavedPercent}',
            color: AppColors.success,
          ),
          GestureDetector(
            onTap: () => _showInfoSheet(context, l10n),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.info_outline, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompare() async {
    if (_showCompare) {
      setState(() {
        _showCompare = false;
      });
      return;
    }
    if (!_current.originalDeleted) {
      final path = await Get.find<PhotoLibraryService>().getFilePath(
        _current.sourceAssetId,
      );
      if (!mounted) return;
      setState(() {
        _originalPath = path;
        _showCompare = true;
      });
    } else {
      setState(() {
        _originalPath = null;
        _showCompare = true;
      });
    }
  }

  void _showInfoSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InfoSheet(
        record: _current,
        l10n: l10n,
        onDeleteOriginal: _current.originalDeleted
            ? null
            : () async {
                Navigator.of(context).pop();
                await _doDeleteOriginal();
              },
        onRollback: () async {
          Navigator.of(context).pop();
          await _doRollback();
        },
      ),
    );
  }

  Future<void> _doDeleteOriginal() async {
    await Get.find<HistoryController>().deleteOriginal(_current.id);
    if (!mounted) return;
    setState(() {
      _records[_currentIndex] = _records[_currentIndex].copyWith(
        originalDeleted: true,
      );
      _showCompare = false;
    });
  }

  Future<void> _doRollback() async {
    await Get.find<HistoryController>().deleteRecord(_current.id);
    if (mounted) AppRouter.pop();
  }
}

// ─── AVIF 图片显示（iOS 原生，Android 通过 JNI 解码）─────────────

class _AvifImageView extends StatefulWidget {
  const _AvifImageView({required this.record});

  final CompressedRecord record;

  @override
  State<_AvifImageView> createState() => _AvifImageViewState();
}

class _AvifImageViewState extends State<_AvifImageView> {
  late final Future<Uint8List?> _decodeFuture = _decode();

  Future<Uint8List?> _decode() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Future<Uint8List?>.value();
    }
    return AndroidAvifEncoder.decode(widget.record.outputPath, maxSide: 2048);
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return InteractiveViewer(
        child: pf.buildFileImage(widget.record.outputPath, fit: BoxFit.contain),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _decodeFuture,
      builder: (_, snap) {
        if (snap.hasData) {
          return InteractiveViewer(
            child: Image.memory(snap.data!, fit: BoxFit.contain),
          );
        }
        if (snap.connectionState == ConnectionState.done) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
          );
        }
        return const Center(child: AppLoading());
      },
    );
  }
}

// ─── 覆盖层底部数据展示 ───────────────────────────────────────────

class _OverlayStat extends StatelessWidget {
  const _OverlayStat({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }
}

// ─── 底部信息面板 ──────────────────────────────────────────────────

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.record,
    required this.l10n,
    required this.onDeleteOriginal,
    required this.onRollback,
  });

  final CompressedRecord record;
  final AppLocalizations l10n;
  final VoidCallback? onDeleteOriginal;
  final VoidCallback onRollback;

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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SheetStat(
                label: l10n.pagesCompareOriginal,
                value: record.displayOriginalSize,
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              _SheetStat(
                label: l10n.pagesCompareCompressed,
                value: record.displayCompressedSize,
              ),
              _SheetStat(
                label: l10n.pagesCompareSaved,
                value: '-${record.displaySavedPercent}',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.compressedAt.toLocal().toString().split('.').first,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (onDeleteOriginal != null) ...[
            AppButton(
              text: l10n.pagesCompareDeleteOriginal,
              onPressed: onDeleteOriginal,
              type: AppButtonType.danger,
              expanded: true,
            ),
            const SizedBox(height: 8),
          ],
          AppButton(
            text: l10n.pagesCompareRollback,
            onPressed: onRollback,
            type: AppButtonType.secondary,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
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
}

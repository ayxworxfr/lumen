# App UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 App 从"压缩工具"风格重设计为 Apple Photos 风格的画廊体验：2 个 Tab（照片 + 设置），照片 Tab 内嵌段落切换（原图 | 已压缩），全屏 AVIF 查看器替代独立对比页和历史 Tab。

**Architecture:** `PhotosPage` 作为照片 Tab 的顶层页面，通过 `CupertinoSlidingSegmentedControl` 在 `_LibraryBody`（原图网格）和 `CompressedGalleryPage`（已压缩画廊）之间切换。压缩进度改为顶部内嵌进度条。`CompressedViewerPage` 替代 `ComparePage`，长按触发 BeforeAfterSlider 覆盖层。

**Tech Stack:** Flutter/Dart, GetX, go_router, photo_manager, CupertinoSlidingSegmentedControl, 现有 BeforeAfterSlider + AndroidAvifEncoder 基础设施。

---

## 文件变更总览

| 操作 | 文件 |
|------|------|
| **新建** | `lib/features/compress/widgets/compress_progress_bar.dart` |
| **新建** | `lib/features/history/views/compressed_gallery_page.dart` |
| **新建** | `lib/features/history/views/compressed_viewer_page.dart` |
| **新建** | `lib/features/library/views/photos_page.dart` |
| **修改** | `lib/features/library/controllers/library_controller.dart` |
| **修改** | `lib/features/history/controllers/history_controller.dart` |
| **修改** | `lib/features/home/views/main_shell.dart` |
| **修改** | `lib/app/router/app_router.dart` |
| **修改** | `lib/features/compress/controllers/compress_controller.dart` |
| **修改** | `lib/features/history/bindings/history_binding.dart` |
| **修改** | `lib/l10n/app_zh.arb` + `lib/l10n/app_en.arb` |
| **删除** | `lib/features/history/views/history_page.dart` |
| **删除** | `lib/features/history/views/compare_page.dart` |
| **删除** | `lib/features/history/controllers/compare_controller.dart` |
| **删除** | `lib/features/compress/views/progress_page.dart` |
| **删除** | `lib/features/library/views/library_page.dart` |

---

## Task 1: ARB 字符串 + 重新生成 l10n

**Files:**
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: 在 app_zh.arb 中新增以下 key，追加到 `pagesLibrarySelect` 之后**

```json
  "pagesPhotosTitle": "照片",
  "pagesPhotosSegmentOriginals": "原图",
  "pagesPhotosSegmentCompressed": "已压缩",
  "pagesPhotosProgressRunning": "正在压缩 {done}/{total}",
  "@pagesPhotosProgressRunning": {
    "placeholders": {
      "done": { "type": "int" },
      "total": { "type": "int" }
    }
  },
  "pagesPhotosProgressDone": "已完成 · 节省 {size}",
  "@pagesPhotosProgressDone": {
    "placeholders": {
      "size": { "type": "String" }
    }
  },
  "pagesCompressedGalleryStats": "{count} 张 · 节省 {size}",
  "@pagesCompressedGalleryStats": {
    "placeholders": {
      "count": { "type": "int" },
      "size": { "type": "String" }
    }
  },
  "pagesCompressedGalleryEmpty": "还没有压缩过的照片",
  "pagesCompressedViewerLongPress": "长按对比原图",
```

- [ ] **Step 2: 在 app_zh.arb 中删除以下不再使用的 key**

删除这些 key 及其 `@metadata` 块（如有）：
- `pagesHistoryTitle`
- `pagesHistoryTotalSaved` + `@pagesHistoryTotalSaved`
- `pagesHistoryCount` + `@pagesHistoryCount`
- `pagesHistorySaved` + `@pagesHistorySaved`
- `pagesCompressProgress`
- `pagesCompressNoJobs`
- `pagesCompressDone`
- `pagesCompressRunning` + `@pagesCompressRunning`
- `pagesCompressSaved` + `@pagesCompressSaved`
- `pagesCompressJobSaved` + `@pagesCompressJobSaved`
- `pagesCompressJobFailed`
- `pagesCompressJobPending`
- `pagesCompressJobRunning`
- `pagesCompressJobCanceled`
- `pagesCompressNoSavings`
- `pagesCompressRetryFailed` + `@pagesCompressRetryFailed`
- `pagesCompressViewHistory`
- `pagesCompressCancelAll`
- `pagesCompareTitle`
- `pagesCompareNotFound`

保留（CompressedViewerPage 仍使用）：`pagesCompareOriginal`, `pagesCompareCompressed`, `pagesCompareSaved`, `pagesCompareDeleteOriginal`, `pagesCompareDeleteOriginalTitle`, `pagesCompareDeleteOriginalConfirm`, `pagesCompareRollback`, `pagesCompareRollbackTitle`, `pagesCompareRollbackConfirm`

- [ ] **Step 3: 对 app_en.arb 执行同样的新增和删除操作**

新增 key（英文版）追加到 `pagesLibrarySelect` 之后：
```json
  "pagesPhotosTitle": "Photos",
  "pagesPhotosSegmentOriginals": "Originals",
  "pagesPhotosSegmentCompressed": "Compressed",
  "pagesPhotosProgressRunning": "Compressing {done}/{total}",
  "@pagesPhotosProgressRunning": {
    "placeholders": {
      "done": { "type": "int" },
      "total": { "type": "int" }
    }
  },
  "pagesPhotosProgressDone": "Done · saved {size}",
  "@pagesPhotosProgressDone": {
    "placeholders": {
      "size": { "type": "String" }
    }
  },
  "pagesCompressedGalleryStats": "{count} photos · saved {size}",
  "@pagesCompressedGalleryStats": {
    "placeholders": {
      "count": { "type": "int" },
      "size": { "type": "String" }
    }
  },
  "pagesCompressedGalleryEmpty": "No compressed photos yet",
  "pagesCompressedViewerLongPress": "Long press to compare",
```

删除与中文相同的那些 key。

- [ ] **Step 4: 重新生成 l10n**

```bash
cd D:/project/study/lumen && make l10n
```

Expected: 无错误，`lib/l10n/generated/app_localizations*.dart` 更新。

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_zh.arb lib/l10n/app_en.arb lib/l10n/generated/
git commit -m "feat(l10n): add photos tab + compressed gallery strings, remove obsolete history/progress keys"
```

---

## Task 2: LibraryController 添加 photosSegment 字段

**Files:**
- Modify: `lib/features/library/controllers/library_controller.dart`

- [ ] **Step 1: 在现有状态字段区域（`isLoadingMore` 之后）添加 photosSegment**

找到以下代码块：
```dart
  final hasMore = true.obs;
  final isLoadingMore = false.obs;
```

在其后添加：
```dart

  /// 照片 Tab 段落索引：0 = 原图，1 = 已压缩
  final photosSegment = 0.obs;
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/library/controllers/library_controller.dart
git commit -m "feat(library): add photosSegment observable for Photos tab segment control"
```

---

## Task 3: HistoryController 订阅压缩完成事件

**Files:**
- Modify: `lib/features/history/controllers/history_controller.dart`

- [ ] **Step 1: 更新 onInit，在加载完记录后订阅 CompressService.jobStream**

将现有 `onInit` 替换为：

```dart
  @override
  void onInit() {
    super.onInit();
    loadRecords();
    _subscribeToCompressEvents();
  }
```

在 `loadRecords()` 方法之前新增：

```dart
  void _subscribeToCompressEvents() {
    try {
      final compressService = Get.find<CompressService>();
      compressService.jobStream.listen((job) {
        if (job.status == JobStatus.done) loadRecords();
      });
    } catch (_) {
      // CompressService 未注册时（测试环境）静默忽略
    }
  }
```

- [ ] **Step 2: 在文件顶部补充缺失的 import**

```dart
import '../../compress/models/compress_job.dart';
import '../../compress/services/compress_service.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/history/controllers/history_controller.dart
git commit -m "feat(history): auto-reload records when a compression job completes"
```

---

## Task 4: CompressProgressBar 进度条 Widget

**Files:**
- Create: `lib/features/compress/widgets/compress_progress_bar.dart`

- [ ] **Step 1: 创建文件**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/compress/widgets/compress_progress_bar.dart
git commit -m "feat(compress): add CompressProgressBar inline progress widget"
```

---

## Task 5: CompressedGalleryPage 已压缩画廊

**Files:**
- Create: `lib/features/history/views/compressed_gallery_page.dart`

- [ ] **Step 1: 创建文件**

```dart
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
/// 使用原图缩略图展示（与 AssetEntity.thumbnailDataWithSize），
/// 避免在网格中解码 AVIF 带来的性能开销。
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
                (_, i) => _buildCell(context, i),
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

  Widget _buildCell(BuildContext context, int index) {
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

  Widget _placeholder() => Container(
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_outlined, size: 32, color: Colors.grey),
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/history/views/compressed_gallery_page.dart
git commit -m "feat(history): add CompressedGalleryPage full-bleed AVIF gallery grid"
```

---

## Task 6: CompressedViewerPage 全屏 AVIF 查看器

**Files:**
- Create: `lib/features/history/views/compressed_viewer_page.dart`

- [ ] **Step 1: 创建文件**

```dart
import 'dart:typed_data';

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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
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
      setState(() { _showCompare = false; });
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
        onDeleteOriginal: _current.originalDeleted ? null : () async {
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
      _records[_currentIndex] = _records[_currentIndex]
          .copyWith(originalDeleted: true);
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
      return Future.value(null);
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/history/views/compressed_viewer_page.dart
git commit -m "feat(history): add CompressedViewerPage with AVIF display, long-press compare, and info sheet"
```

---

## Task 7: PhotosPage 新照片 Tab 主页

**Files:**
- Create: `lib/features/library/views/photos_page.dart`

内容包含：AppBar（动态标题+操作）、段落控件、进度条、库内容、已压缩画廊、选择操作栏。将原 `library_page.dart` 的全部私有 Widget 迁移至此。

- [ ] **Step 1: 创建文件**

```dart
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
              SliverToBoxAdapter(
                child: _buildSavingsHeader(context),
              ),
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
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
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
                  },
                  childCount: entry.value.length,
                ),
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/library/views/photos_page.dart
git commit -m "feat(library): add PhotosPage with segment control, library body, and compressed gallery"
```

---

## Task 8: 更新 Router + MainShell（2 Tab）

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/home/views/main_shell.dart`

- [ ] **Step 1: 更新 app_router.dart**

完整替换文件内容为：

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_service.dart';
import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/register_page.dart';
import '../../features/compress/bindings/compress_binding.dart';
import '../../features/compress/views/preset_sheet.dart';
import '../../features/gallery/bindings/gallery_binding.dart';
import '../../features/gallery/views/album_page.dart';
import '../../features/gallery/views/edit_page.dart';
import '../../features/gallery/views/gallery_viewer_page.dart';
import '../../features/history/bindings/history_binding.dart';
import '../../features/history/views/compressed_viewer_page.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/views/main_shell.dart';
import '../../features/home/views/settings_page.dart';
import '../../features/library/bindings/library_binding.dart';
import '../../features/library/controllers/library_controller.dart';
import '../../features/library/models/album_info.dart';
import '../../features/library/models/photo_asset.dart';
import '../../features/library/views/photos_page.dart';
import '../../features/splash/views/splash_page.dart';
import '../../shared/constants/storage_keys.dart';

/// 路由路径常量
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const mainLibrary = '/main/library';
  static const mainSettings = '/main/settings';
  static const compressPreset = '/compress/preset';
  static const compressedViewer = '/compressed/viewer';
  static const galleryViewer = '/gallery/viewer';
  static const galleryAlbum = '/gallery/album';
  static const galleryEdit = '/gallery/edit';
}

/// 应用路由配置
///
/// 使用 go_router。[navigatorKey] 暴露给需要在 BuildContext 之外导航的场景
/// （如 Controller 中调用 AppRouter.go('/main')）。
class AppRouter {
  AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: _guard,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, __) {
          AuthBinding().dependencies();
          return const NoTransitionPage(child: LoginPage());
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, __) {
          AuthBinding().dependencies();
          return const CustomTransitionPage(
            child: RegisterPage(),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (_, __, child) {
          HomeBinding().dependencies();
          LibraryBinding().dependencies();
          HistoryBinding().dependencies();
          CompressBinding().dependencies();
          return NoTransitionPage(child: MainShell(child: child));
        },
        routes: [
          GoRoute(
            path: AppRoutes.mainLibrary,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: PhotosPage()),
          ),
          GoRoute(
            path: AppRoutes.mainSettings,
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.main, redirect: (_, __) => AppRoutes.mainLibrary),
      GoRoute(
        path: AppRoutes.compressPreset,
        pageBuilder: (_, __) {
          CompressBinding().dependencies();
          return const CustomTransitionPage(
            child: PresetSheet(),
            transitionsBuilder: _slideFromBottom,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.compressedViewer,
        pageBuilder: (_, state) {
          HistoryBinding().dependencies();
          final args = state.extra! as CompressedViewerArgs;
          return CustomTransitionPage(
            child: CompressedViewerPage(
              records: args.records,
              initialIndex: args.initialIndex,
            ),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryViewer,
        pageBuilder: (_, state) {
          GalleryBinding().dependencies();
          final args = state.extra! as GalleryViewerArgs;
          return CustomTransitionPage(
            child: GalleryViewerPage(
              photos: args.photos,
              initialIndex: args.initialIndex,
            ),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryAlbum,
        pageBuilder: (_, state) {
          GalleryBinding().dependencies();
          final album = state.extra! as AlbumInfo;
          return CustomTransitionPage(
            child: AlbumPage(album: album),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.galleryEdit,
        pageBuilder: (_, state) {
          GalleryBinding().dependencies();
          final asset = state.extra! as PhotoAsset;
          return CustomTransitionPage(
            child: EditPage(asset: asset),
            transitionsBuilder: _slideFromRight,
          );
        },
      ),
    ],
  );

  /// Guards: protect /main/* when not authenticated.
  /// 使用 sessionActive 布尔标志同步判断登录状态，避免直接读取异步安全存储。
  static String? _guard(BuildContext context, GoRouterState state) {
    final unprotected = {AppRoutes.splash, AppRoutes.login, AppRoutes.register};
    if (unprotected.contains(state.matchedLocation)) return null;

    final storage = Get.find<StorageService>();
    final isLoggedIn = storage.getBool(StorageKeys.sessionActive) ?? false;

    return isLoggedIn ? null : AppRoutes.login;
  }

  // ─── Navigation helpers ──────────────────────────────────

  /// Navigate to [location], replacing the entire stack.
  static void go(String location) => router.go(location);

  /// Push [location] onto the stack, optionally passing [extra] data.
  static void push(String location, {Object? extra}) =>
      router.push(location, extra: extra);

  /// Pop the top route if possible.
  static void pop() {
    if (router.canPop()) router.pop();
  }

  // ─── Transitions ─────────────────────────────────────────

  static Widget _slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }

  static Widget _slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: child,
    );
  }
}
```

- [ ] **Step 2: 更新 main_shell.dart**

完整替换文件内容为：

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../controllers/home_controller.dart';

/// 主 Shell：包含底部 Tab 导航（照片 / 设置）
class MainShell extends GetView<HomeController> {
  const MainShell({required this.child, super.key});

  final Widget child;

  static int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.mainSettings)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(currentLocation);

    // 同步 controller 索引（避免 controller 和路由状态不一致）
    if (controller.currentIndex.value != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.currentIndex.value = currentIndex;
      });
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final l10n = context.l10n;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        controller.currentIndex.value = index;
        switch (index) {
          case 0:
            context.go(AppRoutes.mainLibrary);
          case 1:
            context.go(AppRoutes.mainSettings);
        }
      },
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.photo_library_outlined),
          selectedIcon: const Icon(Icons.photo_library),
          label: l10n.pagesPhotosTitle,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.pagesSettingsTitle,
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/app/router/app_router.dart lib/features/home/views/main_shell.dart
git commit -m "feat(nav): collapse to 2 tabs (Photos + Settings), add compressed viewer route"
```

---

## Task 9: 清理 CompressController

**Files:**
- Modify: `lib/features/compress/controllers/compress_controller.dart`

- [ ] **Step 1: 删除 goToHistory() 方法，并移除对 AppRoutes.mainHistory 的引用**

找到并删除以下代码块：
```dart
  /// 全部完成后跳转到历史页
  void goToHistory() {
    AppRouter.go(AppRoutes.mainHistory);
  }
```

同时检查文件顶部的 import，如果 `AppRouter` 不再被其他方法引用则删除该 import 行：
```dart
import '../../../app/router/app_router.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/compress/controllers/compress_controller.dart
git commit -m "refactor(compress): remove goToHistory, navigation now handled by CompressProgressBar"
```

---

## Task 10: 清理 HistoryBinding

**Files:**
- Modify: `lib/features/history/bindings/history_binding.dart`

- [ ] **Step 1: 删除 CompareController 的注册**

将整个 `dependencies()` 方法替换为：

```dart
  @override
  void dependencies() {
    if (!Get.isRegistered<CompressedRecordRepo>()) {
      Get.lazyPut<CompressedRecordRepo>(CompressedRecordRepo.new);
    }
    if (!Get.isRegistered<PhotoLibraryService>()) {
      Get.lazyPut<PhotoLibraryService>(PhotoLibraryService.new);
    }
    if (!Get.isRegistered<HistoryService>()) {
      Get.lazyPut<HistoryService>(
        () => HistoryService(
          repo: Get.find<CompressedRecordRepo>(),
          libraryService: Get.find<PhotoLibraryService>(),
        ),
      );
    }

    Get.lazyPut<HistoryController>(
      () => HistoryController(historyService: Get.find<HistoryService>()),
    );
  }
```

删除文件顶部的 import：
```dart
import '../controllers/compare_controller.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/history/bindings/history_binding.dart
git commit -m "refactor(history): remove CompareController registration from HistoryBinding"
```

---

## Task 11: 删除废弃文件

**Files to Delete:**
- `lib/features/history/views/history_page.dart`
- `lib/features/history/views/compare_page.dart`
- `lib/features/history/controllers/compare_controller.dart`
- `lib/features/compress/views/progress_page.dart`
- `lib/features/library/views/library_page.dart`

- [ ] **Step 1: 删除文件**

```bash
rm lib/features/history/views/history_page.dart
rm lib/features/history/views/compare_page.dart
rm lib/features/history/controllers/compare_controller.dart
rm lib/features/compress/views/progress_page.dart
rm lib/features/library/views/library_page.dart
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "refactor: delete HistoryPage, ComparePage, CompareController, ProgressPage, LibraryPage (replaced by new design)"
```

---

## Task 12: 静态分析 + 修复

**Files:** 根据分析结果调整

- [ ] **Step 1: 运行分析**

```bash
cd D:/project/study/lumen && make analyze
```

Expected: 0 errors, 可能有少量 info/warning。

- [ ] **Step 2: 修复所有 error**

常见问题排查：
- **未使用的 import**：删除对应 import 行
- **`AppRoutes.mainHistory` 残留引用**：全局搜索并替换
- **`CompareController` 残留引用**：全局搜索并删除
- **`HistoryPage` / `ProgressPage` 残留引用**：全局搜索并删除
- **ARB key 拼写错误**：对照 Step 1 生成的 `app_localizations.dart` 检查方法名

- [ ] **Step 3: 运行构建验证**

```bash
cd D:/project/study/lumen && flutter build apk --debug 2>&1 | tail -20
```

Expected: Build successful。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "fix: resolve static analysis issues after UI redesign"
```

---

## 验收标准

- [ ] 底部导航只有 2 个 Tab：照片 + 设置
- [ ] 照片 Tab 顶部有「原图 | 已压缩」段落切换
- [ ] 原图段落显示系统相册网格，支持选择和压缩
- [ ] 压缩进行中时段落控件下方显示进度条，完成后显示「已完成」+「查看」入口
- [ ] 点击「查看」切换到已压缩段落，画廊显示 3 列 AVIF 缩略图
- [ ] 点击已压缩照片进入全屏查看器，支持左右滑动翻页
- [ ] 长按全屏查看器显示 BeforeAfterSlider 对比覆盖层
- [ ] 点击 ⓘ 展开信息面板，包含文件大小统计、删除原图、回滚操作
- [ ] `make analyze` 无 error

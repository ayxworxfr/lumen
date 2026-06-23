# Gallery 全功能相册：查看 + 分组 + 基础编辑

**日期**: 2026-06-23（v2，含相册分组 + 图片编辑）  
**档位**: 方案卡（large 子模式）

---

## 意图与边界

**Job-to-be-Done**：  
当用户在 Lumen 压缩图片后，想在 App 内完成"浏览全部照片 / 按相册找图 / 简单调色后直接压缩"的完整闭环，以便不需要离开 App 切回系统相册或其他编辑软件。

**Goals**：
1. Library 标签升级为全功能相册：点击图片 → 全屏查看器（捏放 + 左右滑动）
2. 相册分组：顶部 Tab 切换「按时间（年月分节）」和「按相册（系统相册封面）」两种浏览方式
3. 查看器底部：系统分享 / 未压缩→「压缩」/ 已压缩→「对比」入口
4. 已压缩图片在网格内显示 AVIF 徽章
5. 图片编辑：裁剪 + 旋转 + 亮度/对比度/饱和度调整，保存输出新文件（原图不变）
6. 编辑后可直接发起压缩（进入现有压缩流程，source 换为编辑后文件）
7. 选择模式改为：长按 或 AppBar「选择」按钮进入

**Non-Goals**：
- 不做滤镜（Instagram 风格）、文字贴纸、涂鸦
- 不做视频支持
- 不替换或修改原始照片（编辑结果另存为新文件）
- 不改 History 标签 / ComparePage 内部逻辑
- 不改压缩流程（Preset → Progress 流程保持不变）
- 不做 web 支持（library 已是 mobile-only）

**成功标准**：
1. `flutter analyze` 通过，无新警告
2. 「按时间」Tab：照片网格按年月分节显示
3. 「按相册」Tab：展示系统相册封面，点进后看该相册图片
4. 真机：点击图片 → 查看器，左右滑动、捏放正常，底部按钮上下文正确
5. 图片编辑：调整亮度/对比/饱和实时预览，裁剪框可拖拽，「保存」输出新 JPEG 文件
6. 编辑后可选「压缩」进入压缩流程，source 为编辑后的临时文件

---

## 决策驱动变量

| 变量 | 类别 | 取值 | 来源 |
|---|---|---|---|
| 导航结构 | driver（已确认） | 改造 Library 标签（3 tabs 不变） | 用户确认 |
| 查看器功能 | driver（已确认） | 捏放+滑动 + 系统分享 + 压缩对比入口 + 一键压缩 | 用户确认 |
| 编辑级别 | driver（已确认） | 裁剪 + 旋转 + 亮度/对比/饱和度 | 用户确认 |
| 分组方式 | driver（已确认） | 按时间分节 + 按系统相册（Tab 切换） | 用户确认 |
| 图片编辑库 | driver（待选型） | 候选：`pro_image_editor` / `image_cropper` + 自定义颜色矩阵 | 见切片4依赖评估 |
| share_plus 是否可用 | driver | 未在 pubspec.yaml 中，需新增 | pubspec.yaml 核查 |
| 压缩状态数据来源 | driver（可推断） | `CompressedRecordRepo.loadAll()` 取 sourceAssetId 集合 | `compressed_record.dart:sourceAssetId` |
| 编辑文件存储路径 | 边角 | `<AppDocs>/edited/<uuid>.jpg`（假设，不覆盖原图） | 参考 `FileStore` 路径策略 |

---

## 项目事实

| 文件 | 关键内容 |
|---|---|
| `lib/features/library/controllers/library_controller.dart` | `selectedIds`, `photos`, `hasMore`, `isLoadingMore`；无 `isSelectionMode` flag，选择态隐式（selectedIds 非空） |
| `lib/features/library/views/library_page.dart` | AppBar：排序 + 取消选择；PhotoGrid 组件；底部选择条（selectedIds 非空时出现） |
| `lib/features/library/widgets/photo_grid_cell.dart` | `onTap` 直接调 `toggleSelection`；有大小徽章；无查看器入口 |
| `lib/features/library/services/photo_library_service.dart` | `getPhotos(page, pageSize)` 分页；`getFilePath(assetId)`；无相册（album）列表接口 |
| `lib/features/library/bindings/library_binding.dart` | 注册 PhotoLibraryService + LibraryController |
| `lib/app/router/app_router.dart` | ShellRoute `/main/*`；无 gallery viewer / album 路由 |
| `lib/features/history/models/compressed_record.dart` | `sourceAssetId`：photo_manager asset ID，用于判断图片是否已压缩 |
| `lib/features/history/services/compressed_record_repo.dart` | `loadAll()`：返回所有压缩记录 |
| `pubspec.yaml` | `photo_manager: ^3.5.0`（支持相册列表 `getAssetPathList()`）；**无 `share_plus`**；**无图片编辑库** |

---

## 档位

**选定：方案卡（large 子模式）**  
选档理由：新增 5+ 文件，修改 5+ 现有文件，含新路由 + 新库依赖；但无公开 API 跨模块变更，维持方案卡。diff 预算超大（~850 行），需明确分 4 个切片交付。

---

## diff 预算

| 切片 | 新建文件 | 修改文件 | 行数量级 |
|---|---|---|---|
| 切片1 Walking Skeleton（查看器） | 2 | 5 | ~300 行 |
| 切片2 相册分组 | 3 | 2 | ~250 行 |
| 切片3 查看器操作栏（share / 压缩 / 对比）| 0 | 3 | ~150 行 |
| 切片4 图片编辑 | 3 | 3 | ~300 行 |
| pubspec.yaml（share_plus + 编辑库） | 0 | 1 | ~4 行 |
| **合计** | **8 文件** | **14 文件** | **~1000 行** |

---

## 代码级约束（命中项）

**性能：PageView + InteractiveViewer 手势冲突**
- 缩放后横扫图片误触 PageView 换页
- 检查方式：zoom scale > 1.0 时将 PageView.physics 设为 NeverScrollableScrollPhysics

**性能：全尺寸图片异步加载**
- HEIC/RAW 可达 10MB+，需逐页异步 + shimmer 占位
- 检查方式：真机 HEIC 图片不出现白屏 > 1s

**性能：相册封面批量加载**
- 「按相册」Tab 需加载每个相册封面缩略图；若相册数量 > 20，需懒加载
- 检查方式：100 个相册时滚动 FPS ≥ 55

**可靠：压缩状态集合刷新**
- `compressedAssetIds` 在 onInit 加载，用户压缩后切回 Library 不刷新
- 检查方式：压缩完成后切回 Library，AVIF 徽章出现（onResume 刷新或监听 CompressService 完成事件）

**可靠：编辑后文件管理**
- 用户编辑多次会堆积 `edited/` 目录；App 卸载前需清理
- 检查方式：编辑 10 次后检查目录大小；App 启动时清理 > 7 天的旧 edited 文件

**兼容：share_plus 分享 .avif**
- Android 可能无法识别 .avif MIME type
- 检查方式：真机 Android 13+ 测试，传入 `mimeType: 'image/avif'`

---

## 子模式展开（large — 4 个垂直切片）

### 切片 1：Walking Skeleton（查看器基础）

**完成标志**：Library 点击图片 → 全屏查看器，能捏放 + 左右滑动，Back 返回 Library。  
涉及文件：
- `GalleryViewerPage`（新建）：PageView + InteractiveViewer，zoom-aware page scroll
- `GalleryViewerController`（新建）：currentIndex，持有 photos 引用，pagination trigger
- `app_router.dart`：添加 `/gallery/viewer` 路由（extra: initialIndex）
- `library_binding.dart`：注册 GalleryViewerController
- `library_controller.dart`：添加 `isSelectionMode` flag；tap 分支（非选模式→push viewer）
- `photo_grid_cell.dart`：onTap → open viewer；onLongPress → enter selection mode

### 切片 2：相册分组

**完成标志**：Library 页顶部出现「按时间 / 按相册」Tab；按时间视图显示年月节头；按相册视图显示相册封面网格，点入查看相册内图片。  
涉及文件：
- `LibraryTabMode` enum + `library_controller.dart`：添加 `tabMode`、`albums`、`loadAlbums()`
- `photo_library_service.dart`：添加 `getAlbums()` 调用 `PhotoManager.getAssetPathList()`，返回 `List<AlbumInfo>`
- `AlbumInfo` model（新建，简单 freezed）：albumId, name, coverAsset, count
- `AlbumGridWidget`（新建）：相册封面网格
- `library_page.dart`：顶部 TabBar 切换；按时间视图加 SliverStickyHeader 节头；按相册视图嵌入 AlbumGrid
- `app_router.dart`：添加 `/gallery/album/:albumId` 路由

按时间分组逻辑：`photos` 按 `createdAt` 排序后按「年-月」分桶，渲染 SliverList + 节头。

### 切片 3：查看器操作栏（Context-aware）

**完成标志**：查看器底部出现分享/压缩/对比按钮（根据是否已压缩显示不同 action）；分享触发系统 Sheet；对比跳 ComparePage；压缩进入 Preset 流程。  
涉及文件：
- `GalleryViewerPage`：添加底部 ActionBar（AnimatedSwitcher 切换两种状态）
- `GalleryViewerController`：加载 `compressedAssetIds`，判断当前图片状态
- `library_binding.dart`：注册 CompressedRecordRepo
- `pubspec.yaml`：添加 `share_plus: ^10.x`

底部按钮逻辑：
```
已压缩图片：[分享] [对比查看] [···]
未压缩图片：[分享] [编辑] [压缩]
```

### 切片 4：图片编辑

**完成标志**：查看器底部「编辑」→ 进入编辑页；裁剪框可拖拽，亮度/对比/饱和滑条实时预览；「保存」输出新 JPEG 到 `<AppDocs>/edited/<uuid>.jpg`；保存后可选「立即压缩」进入压缩流程。  
涉及文件：
- **依赖评估**（building 实施前需验证）：  
  候选 A：`pro_image_editor` — 一体化编辑库，覆盖裁剪+调色，API 简单，bundle 较大  
  候选 B：`image_cropper` (native crop) + `ColorFiltered` widget 预览 + `image` 包离线处理
  → 推荐候选 B：native crop UX 更好，颜色调整用 dart `image` 包处理，无重量级依赖
- `EditPage`（新建）：StatefulWidget，展示裁剪 + 调色工具栏
- `EditController`（新建）：管理编辑状态（crop rect, brightness, contrast, saturation），触发保存
- `EditBinding`（新建）：注册 EditController
- `app_router.dart`：添加 `/gallery/edit` 路由（extra: PhotoAsset）
- `GalleryViewerPage`：「编辑」按钮跳转 EditPage

---

## 失败模式与验证

| # | 失败模式 | 级别 | 验证项 |
|---|---|---|---|
| F-1 | PageView + InteractiveViewer 手势冲突：缩放后横扫误触换页 | **High** | widget test：scale>1.0 时 PageView physics = NeverScrollable；真机捏放后平移不换页 |
| F-2 | 全尺寸图片加载阻塞（HEIC 10MB+）：白屏或 ANR | **High** | FutureBuilder loading state 存在；真机 HEIC 测试无 ANR |
| F-3 | 相册封面批量 thumbnail 加载卡帧 | Medium | 滚动性能真机测试 FPS ≥ 55；封面用 200x200 缩略图（非原图） |
| F-4 | 编辑后文件堆积磁盘（用户多次编辑未压缩） | Medium | App 启动时清理 > 7 天 edited/ 文件；单测 EditController 验证文件写入路径 |
| F-5 | PageView 翻到分页边界（第 80 张）无更多图片 | Medium | 单测 GalleryViewerController：index 临近 photos.length-3 时触发 loadMore |
| F-6 | share_plus 分享 .avif 失败（Android MIME 不识别）| Medium | 真机 Android 13+ 测试；显式传入 mimeType: 'image/avif' |
| F-7 | 按相册 Tab：用户无系统相册（仅 Camera Roll）→ 封面网格空或只有一项 | Low | 单测 `getAlbums()` 返回空列表时显示 Empty State |
| F-8 | 导航链 Bug：Gallery → Edit → Back 后 viewer 状态丢失 | Low | 集成测试：Library → Viewer → Edit → Back → Viewer 显示同一张图片 |

---

## 推荐与决策

**推荐：4 切片渐进交付，切片间可独立验证**

**决策理由：**
- 切片 1 和 切片 2 互相独立，可并行开发（两个子 agent 同时实施）
- 切片 3 依赖切片 1 完成（需要 viewer 存在）
- 切片 4 依赖切片 1 和 3（need viewer + 先确认编辑库选型）

**影响范围：**  
Library 模块全部（新增 8 文件 + 修改 9 文件）+ Router（3 条新路由）+ pubspec（2 个新依赖）。  
History / Compress / Settings 模块不变。

**diff 预算**：~16 文件，~1000 行

**下一步实施边界（building 契约）**：
1. 切片 1 + 切片 2 **并行**开始（互不依赖）
2. 切片 1 完成后开始切片 3（需 viewer route 存在）
3. 切片 3 完成后评估切片 4 编辑库选型，再实施切片 4
4. 所有切片完成后运行 `make analyze` + 真机全链路验证

**重评估条件**：
- 若 `pro_image_editor` bundle size > 5MB 不可接受 → 切换候选 B（`image_cropper` + `image` 包）
- 若 按相册 Tab 导致 LibraryController 过于庞大（> 300 行）→ 拆出 AlbumController
- 若 4 个月内 History 标签需要独立功能扩展 → 重新评估是否拆 4 tabs

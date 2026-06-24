# AVIF 图像压缩 + 基础相册浏览（Sub-project 1）设计文档

> 创建日期：2026-06-12
> 范围：本文档只覆盖 MVP（sub-project 1）。AV1 视频压缩、桌面/Web、图片编辑器为独立后续子项目。

---

## 1. 背景与目标

基于现有 Flutter 脚手架开发一款**面向移动端用户的图片压缩工具 + 轻量相册浏览器**。核心卖点：

- 用 AVIF 在**视觉无损**前提下显著压缩用户手机上的存量大图，主要针对 JPEG / PNG / WebP 输入（HEIC 输入收益较小但仍支持）
- 提供"已压缩"画廊以建立信任：随时查看前/后对比、磁盘节省统计、一键回滚
- 提供完整相册浏览能力，按文件大小/格式排序找出"压缩收益最高"的图片

**非目标**：图片编辑、视频压缩、云同步、多人协作、桌面/Web 端。

---

## 2. 范围

| 类别 | 包含 | 不包含 |
|---|---|---|
| 平台 | iOS 16+、Android 9+ (API 28+) | 桌面、Web、Android 9 以下 |
| 编解码 | AVIF 编码（输出）；JPEG/PNG/WebP/HEIC 解码（输入） | AV1 视频；GIF/SVG/RAW |
| 功能 | 完整相册浏览、批量压缩、已压缩画廊、前后对比、回滚 | 图片编辑、滤镜、标注、分享面板深定制 |
| 商业化 | 仅留接入位（控制器/服务接口可扩展），不实现具体方案 | 订阅、内购、广告 |

**最低系统版本理由**：
- iOS 16+：系统 ImageIO 原生支持 AVIF 编码，免去打包 libavif XCFramework，节省二进制体积约 4-6MB
- Android 9+：系统 `BitmapFactory` 支持 HEIC 解码；libavif 编码通过 FFI 由 App 自带

---

## 3. 用户场景与核心流程

### 主场景 A：批量压缩"省空间"

```
打开 App
  → 落地到「相册」Tab，默认按文件大小倒序
  → 顶部展示"潜在可节省 X GB"估算
  → 用户选中或多选大图（系统相册视图）
  → 点"压缩"，弹出预设选择（更小 / 平衡 / 更高质量），默认"平衡"
  → 显示批量队列进度（可后台、可取消）
  → 完成后跳到「已压缩」Tab，显示该批次结果（节省了 X MB）
```

### 主场景 B：查看与回滚

```
「已压缩」Tab
  → 网格展示历史压缩记录（带"省了 X%"角标）
  → 点开 → 全屏前后对比（双指/拖拽对比 slider）
  → 顶栏操作：删除原图（释放空间）/ 回滚（删除压缩文件）/ 分享压缩文件
```

### 关键非功能要求

- 单张 12MP 图片端到端压缩耗时 P95 < 8s（端机 SoC 中位数下）
- 队列必须可在 App 后台继续；进入后台 30 分钟内不被杀
- 失败单图不阻塞队列；尾部展示"X 张失败，重试"入口
- 压缩文件必须能保留 EXIF 关键字段（拍摄时间、GPS、方向）

---

## 4. 总体架构

沿用脚手架的 3 层架构（Presentation / Domain / Data），并新增一层"原生编解码层"（Platform 适配层）。

```
┌────────────────────────────────────────────────────────────┐
│  Presentation  (GetX Controllers · Pages · Widgets)         │
│   - LibraryController   - CompressController                │
│   - HistoryController   - CompareController                 │
└────────────────────────────────────────────────────────────┘
                          ↑↓
┌────────────────────────────────────────────────────────────┐
│  Domain  (Services · Pure Dart Models)                      │
│   - PhotoLibraryService   - CompressService                 │
│   - HistoryService        - SavingsEstimator                │
└────────────────────────────────────────────────────────────┘
                          ↑↓
┌────────────────────────────────────────────────────────────┐
│  Data  (Adapters · Storage)                                 │
│   - PhotoManagerAdapter (photo_manager pkg)                 │
│   - CompressedRecordRepo (Hive)                             │
│   - FileStore (path_provider + dart:io)                     │
└────────────────────────────────────────────────────────────┘
                          ↑↓
┌────────────────────────────────────────────────────────────┐
│  Platform Codec  (Dart 接口 + 原生实现)                      │
│   abstract class AvifEncoder                                │
│     ├ IosAvifEncoder      → MethodChannel → ImageIO         │
│     └ AndroidAvifEncoder  → MethodChannel → Kotlin → JNI   │
│                             → libheif+libaom (.so)          │
│                                                             │
│   class ImageDecoder (格式检测；AVIF 显示见下方说明)         │
└────────────────────────────────────────────────────────────┘
```

**为什么把原生编解码层独立**：编码是延迟敏感、资源密集、平台差异大的部分，必须有清晰的抽象边界以便：
1. 在不同平台用最合适的实现（iOS 系统 vs Android FFI）
2. 在测试中用 fake encoder 替换
3. 后期扩到桌面/Web 时只换实现不动上层

---

## 5. 模块拆分

按脚手架现有 `lib/features/<feature>/` 模式扩展：

```
lib/
├── features/
│   ├── library/                  ← 系统相册浏览（含选择模式）
│   │   ├── controllers/library_controller.dart
│   │   ├── services/photo_library_service.dart
│   │   ├── views/library_page.dart
│   │   ├── widgets/photo_grid.dart, photo_grid_cell.dart
│   │   ├── bindings/library_binding.dart
│   │   └── models/photo_asset.dart
│   ├── compress/                 ← 压缩流程（预设、队列、进度）
│   │   ├── controllers/compress_controller.dart
│   │   ├── services/compress_service.dart, savings_estimator.dart
│   │   ├── views/preset_sheet.dart, progress_page.dart
│   │   ├── bindings/compress_binding.dart
│   │   └── models/compress_job.dart, compress_preset.dart
│   ├── history/                  ← "已压缩"画廊 + 前后对比
│   │   ├── controllers/history_controller.dart, compare_controller.dart
│   │   ├── services/history_service.dart
│   │   ├── views/history_page.dart, compare_page.dart
│   │   ├── widgets/before_after_slider.dart
│   │   ├── bindings/history_binding.dart
│   │   └── models/compressed_record.dart
│   ├── home/                     ← 已存在，扩展为底部 Tab 容器
│   └── auth/                     ← 已存在
├── core/
│   ├── codec/                    ← 原生编解码层
│   │   ├── avif_encoder.dart            (abstract)
│   │   ├── image_decoder.dart           (格式检测工具)
│   │   ├── encoder_factory.dart
│   │   ├── ios/ios_avif_encoder.dart    (MethodChannel)
│   │   ├── android/android_avif_encoder.dart  (MethodChannel + decode 静态方法)
│   │   └── web/web_avif_encoder_stub.dart     (web 存根)
│   ├── isolate/                  ← 编码隔离 worker
│   │   └── compress_worker.dart
│   └── storage/                  ← 已存在，扩展 file_store.dart
ios/Runner/
└── codec/AvifEncoderPlugin.swift
android/app/src/main/
├── kotlin/.../codec/AvifEncoderChannel.kt   (编码 + 解码双 MethodChannel handler)
└── cpp/avif_jni.cpp + CMakeLists.txt        (libheif v1.23.0 + libaom v3.9.1，编译为 lumen_avif.so)
```

---

## 6. 数据模型

全部用 `@freezed` + `@JsonSerializable`（Hive 用的需 `@HiveType`）。

```dart
@freezed
class PhotoAsset {
  String id;                 // PHAsset.localIdentifier / MediaStore.Images _id
  String? path;              // 在沙盒内的临时缓存路径（按需获取）
  int byteSize;
  ImageFormat format;        // jpeg / png / heic / webp / avif / unknown
  int width, height;
  DateTime createdAt;
  String? mimeType;
}

enum CompressPreset { smaller, balanced, higherQuality, lossless }
// smaller   → AVIF Q70 + speed 6
// balanced  → AVIF Q85 + speed 6   (默认)
// higher    → AVIF Q92 + speed 4
// lossless  → AVIF lossless（高级模式才暴露）

@freezed
class CompressJob {
  String id;
  PhotoAsset source;
  CompressPreset preset;
  JobStatus status;          // pending / running / done / failed / canceled
  double progress;           // 0..1
  int? outputBytes;
  String? outputPath;
  String? errorMessage;
  DateTime queuedAt;
  DateTime? finishedAt;
}

@freezed
class CompressedRecord {
  String id;
  String sourceAssetId;      // 原图引用
  String outputPath;         // App 沙盒内 .avif 文件路径
  int originalBytes, compressedBytes;
  CompressPreset preset;
  ImageFormat originalFormat;
  DateTime compressedAt;
  bool originalDeleted;      // 用户是否已删除原图（释放空间）
}
// 注：不使用 @HiveType；Hive box 存 JSON map（Box<dynamic>），无需类型适配器
```

`ImageFormat` 用枚举，后续若加 RAW/GIF 直接扩展。

---

## 7. 关键技术选型

### 7.1 AVIF 编码

#### iOS：MethodChannel → ImageIO

iOS 16 起 `CGImageDestinationCreateWithURL` 支持 UTI `org.aomediacodec.avif-image`。流程：

```
Dart: AvifEncoder.encode(srcPath, preset)
  ↓ MethodChannel(channel: 'lumen/avif', method: 'encode')
Swift: AvifEncoderPlugin
  → CGImageSourceCreateWithURL（解码任意输入）
  → CGImageDestinationCreateWithURL(.avif, kCGImageDestinationLossyCompressionQuality)
  → CGImageDestinationAddImage（带 EXIF 元数据透传）
  → CGImageDestinationFinalize
  ← 返回输出路径 + 字节数
```

优点：零 native 依赖、系统优化好、自动选 HW 加速（A14+ 上有部分 HW 加速）。
风险：iOS 16 早期小版本有个别尺寸编码崩溃的报告；MVP 处理方案是把该 job 标 failed 并在 UI 上提示用户跳过（不退出队列）。打包 libavif XCFramework 作为 fallback 列入后续优化清单，不在 MVP 内。

#### Android：MethodChannel → Kotlin → JNI → libheif+libaom

使用与 iOS 对称的 MethodChannel 方案，不使用 Dart FFI。原因：
- `AvifEncoderChannel.kt` 在后台线程运行，不阻塞主线程
- 编码前用 `BitmapFactory` 进行源图解码（系统原生支持 JPEG/PNG/WebP/HEIC），省去在 Dart 层做格式解码
- Native 库通过 CMake + NDK 在构建时编译，无需预置 `.so` 文件

**实现层次**：
```
Dart AndroidAvifEncoder.encode()
  → MethodChannel('lumen/avif', method: 'encode')
  → Kotlin AvifEncoderChannel（后台 Thread）
    → BitmapFactory.decodeFile → ByteBuffer（RGBA 像素）
    → JNI encodeToAvif()
      → libheif：heif_image_create + RGBA plane
      → libaom：AV1 编码
      → heif_context_write_to_file
  ← 返回 {outputPath, outputBytes}
```

**ABI 支持**：`arm64-v8a`、`armeabi-v7a`（`x86_64` 暂不支持，模拟器开发需用 arm 模拟器）。

**Native 库**：`lumen_avif.so`，CMake FetchContent 从源码编译 libheif v1.23.0 + libaom v3.9.1。key cmake 配置：`AOM_TARGET_CPU=generic`（Windows 交叉编译不触发 ASM 检测），`WITH_AOM_ENCODER=ON`，`WITH_AOM_DECODER=ON`，其他编解码器全部 OFF。

#### 解码（输入侧 + AVIF 显示侧）

**编码输入**：`BitmapFactory`（Kotlin 层，系统原生支持 JPEG/PNG/WebP/HEIC，API 28+）。

**AVIF 显示**（Android 特殊处理）：Android API < 31 无原生 AVIF 解码能力，`Image.file(avifPath)` 会静默白屏。实际方案：
- `AvifEncoderChannel.kt` 同时支持 `decode` MethodChannel 方法
- JNI `decodeAvif()` 使用 libheif+libaom 解码 → RGBA 像素 → Kotlin 转 Bitmap → JPEG bytes
- `AndroidAvifEncoder.decode(path, {maxSide})` 静态方法返回 `Future<Uint8List?>`
- `BeforeAfterSlider` 对 Android 用此方法异步加载压缩后图片；iOS 直接 `pf.buildFileImage()`（系统原生支持 AVIF）
- 历史页网格不走 AVIF 解码，使用 `AssetEntity.thumbnailDataWithSize()` 取原图的系统缩略图

### 7.2 系统相册访问

直接采用社区成熟包：[`photo_manager`](https://pub.dev/packages/photo_manager)。

理由：
- 同时封装 PhotoKit（iOS）和 MediaStore（Android）
- 支持懒加载缩略图、按尺寸排序、监听变化
- 自己重写要踩很多坑（iOS limited photo access、Android scoped storage、各种厂商 ROM 差异）

权限：
- iOS：`NSPhotoLibraryUsageDescription`（必要时申请 limited access，但 MVP 默认申请 full）
- Android 13+：`READ_MEDIA_IMAGES`
- Android 12-：`READ_EXTERNAL_STORAGE`

### 7.3 后台任务与并发

**Isolate 池**：每个 ABI 上同时跑 N=2 个编码 isolate（手机 CPU 通常 4-8 核但发热严重，不能跑满）。N 通过运行时探测核数动态调（`Platform.numberOfProcessors / 2`，下限 1，上限 4）。

**队列调度**：`CompressService` 维护一个 `Queue<CompressJob>`，对外暴露 `Stream<CompressJob>` 让 UI 层监听进度。

**iOS 后台**：使用 `UIApplication.beginBackgroundTask`，系统通常给 30-180s 不等的真后台时间（动态分配，不可保证）；超时前必须暂停队列、把状态写入 Hive `pending_jobs`，下次进入 App 自动续跑。
**Android 后台**：用前台 Service + 通知，可以稳定后台跑（这是 Android 用户的核心优势，应该作为 Android 版本的卖点之一）。

**取消/暂停**：`CompressJob.status` 是单一真相源，每个 isolate 在每次 encode 调用前 check 状态。

---

## 8. 路由与页面（go_router）

```
/                            → SplashPage  (已存在)
/login                       → LoginPage   (已存在，开发模式可绕过)
/main                        → MainShell (3 个底部 Tab 容器)
   /main/library             → LibraryPage          (默认 Tab)
   /main/history             → HistoryPage
   /main/settings            → SettingsPage         (已存在)
/library/select              → LibraryPage(selectMode=true)  通过 query 参数
/compress/preset             → PresetSheet (modal bottom sheet)
/compress/progress           → ProgressPage
/history/:recordId           → ComparePage
```

底部 Tab 的"压缩"入口：在 LibraryPage 多选模式下用底部行动栏触发，不是独立 Tab——避免"空 Tab"。

---

## 9. 状态管理与 DI（GetX）

| Controller | 范围 | 持久化 |
|---|---|---|
| `AppController` (已存在) | 主题、locale | SharedPrefs |
| `LibraryController` | 当前分组、排序、多选集 | 内存（重启重置） |
| `CompressController` | 当前队列、进度、preset | Hive（跨重启续跑） |
| `HistoryController` | 已压缩记录列表、过滤 | Hive |
| `CompareController` | 当前对比详情 | 内存 |

`CompressService` 注册为 `Get.put(permanent: true)`——队列必须比页面活得久。

---

## 10. 持久化与文件系统

| 数据 | 存储位置 | 备份 |
|---|---|---|
| `CompressedRecord` | Hive box `'compressed_records'`（key: `StorageKeys.compressedRecordsBox`） | iCloud/Auto Backup 排除（避免占云端空间） |
| 压缩输出 .avif | `<AppDocs>/compressed/<yyyyMM>/<id>.avif` | 同上排除 |
| 用户偏好（默认 preset 等） | SharedPrefs（已有体系） | 跟随 |
| 进行中队列状态 | Hive box `'pending_jobs'`（key: `StorageKeys.pendingJobsBox`） | 排除 |

**iOS 排除备份**：用 `URLResourceKey.isExcludedFromBackup`。
**Android**：默认放 internal storage，不参与 Auto Backup。

**文件命名**：UUID v4，避免相册扫描器误识别。

**清理策略**：用户主动删除压缩记录时，同步删 .avif 文件；"原图删除"是单向操作（删完不可逆，UI 强提示+二次确认）。

---

## 11. 权限与最小系统版本

| 平台 | 最低版本 | 必需权限 | 可选权限 |
|---|---|---|---|
| iOS | 16.0 | Photo Library (full) | App Tracking Transparency（暂不） |
| Android | 9.0 (API 28) | READ_MEDIA_IMAGES (13+) / READ_EXTERNAL_STORAGE (12-) | POST_NOTIFICATIONS（13+，前台 Service 通知） |

权限拒绝时的 UX：
- 首次拒绝：解释卡片 + "去设置"按钮
- 限制访问（iOS limited）：显示"仅可访问 X 张图，前往设置开放完整访问"banner

---

## 12. 错误处理与边界情况

| 情况 | 处理 |
|---|---|
| 单张编码失败 | 记入 job.errorMessage，跳过，继续队列；详情页可重试 |
| 输入图片解码失败 | 提前在 enqueue 时检测格式，未识别格式直接拒绝入队 |
| 输出文件大小 ≥ 原图 | 不替换、不生成记录，提示"该图压缩无收益"（保护用户预期） |
| 存储不足 | 入队前预估总输出大小，不足则拒绝并提示 |
| 队列中途用户回滚 / 删除原图 | 任务状态机里增加幂等校验 |
| iOS limited access：选中图后该图被用户从 App 视图移除 | 监听 PhotoLibrary 变化，将 Job 标记 canceled |
| Android scoped storage：写回相册被拒 | MVP 不直接写回原相册，统一写到 App 沙盒（见第 13 条 Open Question） |
| 编码 isolate 崩溃 | Service 层捕获 isolate exit，重启 isolate，对应 job 标 failed |
| 用户在"已压缩"画廊确认删除原图 | iOS：`PHPhotoLibrary.shared().performChanges` + `PHAssetChangeRequest.deleteAssets`，会触发系统删除确认 UI；Android：对 `MediaStore` URI 调 `ContentResolver.delete`，Android 11+ 走 `MediaStore.createDeleteRequest` 触发系统弹窗。两端都不可静默删除——这点要在 UI 文案里提前告知 |

---

## 13. 国际化

沿用脚手架 ARB 模式。新增 key 命名空间：
- `pagesLibrary*` 相册浏览
- `pagesCompress*` 压缩流程
- `pagesHistory*` 已压缩画廊
- `pagesCompare*` 前后对比
- `widgetsCodec*` 编码相关错误文案

支持中英两种（同脚手架现状）。

---

## 14. 测试策略

| 层 | 框架 | 覆盖 |
|---|---|---|
| Unit | flutter_test + mocktail | Services 全部、Models 序列化、SavingsEstimator |
| Widget | flutter_test | 三个主要 Page、PhotoGrid、BeforeAfterSlider |
| Integration | integration_test + 桩 encoder | 完整压缩-保存-列表流程 |
| 平台原生 | XCTest / JUnit | AvifEncoder iOS/Android 实现，单图正确性 + EXIF 透传 |
| 端到端真机 | 手动 | 各档预设的实际压缩比与时长基线，每个 release 跑一次 |

`AvifEncoder` 测试用 `FakeAvifEncoder` 注入，不依赖真编码器。

---

## 15. 后续子项目（不在本 spec 内）

按优先级：

1. **AV1 视频压缩**：单独 spec。难点：iOS AVAssetExportSession 不直接支持 AV1（需要外接 ffmpeg-kit 或自带 libaom），Android MediaCodec 7.0+ 才有 AV1 编码硬件加速覆盖。
2. **图片编辑器**：裁剪、旋转、亮度对比度、滤镜。考虑用 `image_editor` 包或自研 GPU pipeline。
3. **桌面/Web 扩展**：libavif 桌面动态库 + WASM，UI 层零成本复用。
4. **云端备份压缩结果**：可选订阅服务，把压缩结果同步到自有云。

---

## 16. 待你决策的开放问题

这些是我在写 spec 时替你拍的板，请逐条确认或推翻：

| # | 我拍的板 | 备选 |
|---|---|---|
| Q1 | 默认不"原地替换原图"——压缩输出存 App 沙盒，原图删除是用户在"已压缩"画廊里手动确认的二次操作 | 一压完自动删原图（更激进、风险更高） |
| Q2 | iOS 最低 16.0，省下打包 libavif 的体积 | iOS 13+，但需要打 libavif XCFramework，包体 +5MB |
| Q3 | Android 最低 9.0（HEIC 系统解码） | Android 7.0+，需自带 libheif 解码 |
| Q4 | 只支持 AVIF 输出，不让用户选 HEIC/WebP 输出格式 | 提供输出格式选择（增加 UX 复杂度） |
| Q5 | 编码 isolate 数量 = `numberOfProcessors / 2`，min 1 max 4 | 让用户在设置里手动选 |
| Q6 | 商业化模式不在 MVP 决定，但留接入位（Service 层接口可扩展） | 现在就定（订阅 / 内购 / 免费 + 高级解锁） |
| Q7 | "压缩后体积 ≥ 原图"的图直接不输出，只展示提示 | 仍然输出并让用户决定 |
| Q8 | 输出文件全部放 App 沙盒，不回写系统相册 | MVP 就支持回写系统相册（iOS 创建新资源、Android 写 MediaStore） |
| Q9 | 不内置 EXIF 编辑器；元数据透传保留 | 提供"压缩时移除 GPS"开关 |
| Q10 | App 名称 / 图标 / 品牌色 待定 | （需要你给方向） |

---

## 17. 实施顺序建议（写实现计划时参考）

1. 原生编解码层（先 iOS，Platform Channel + ImageIO；Android 用 FakeEncoder 跑 UI）
2. PhotoLibraryService + LibraryPage（系统相册浏览）
3. CompressService + CompressController + 队列基础设施
4. PresetSheet + ProgressPage
5. Android MethodChannel + libheif+libaom 接入（最重的一块，含 JNI 编解码）
6. HistoryPage + CompressedRecord 持久化
7. ComparePage + 前后对比交互
8. 错误处理、权限引导、i18n 收口
9. 真机性能基线、回归测试

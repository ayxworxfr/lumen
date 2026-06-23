# Android AVIF 编码器升级：libavif（自写 JNI）→ libheif（strukturag）

**日期**: 2026-06-23（初版 awxkee 方案已废弃，本版更新为 libheif 方案）
**档位**: 方案卡（design）

---

## 意图与边界

**Job-to-be-Done**：  
JNI + CMake 路线已跑通，但 `avif_jni.cpp` 是手写的低质量 C++ 代码（直接调用 libavif 底层 API），  
需要替换为 strukturag/libheif 的高层 C API，获得工业级 C 库维护背书，  
以便提升代码可靠性、可读性，并消除手动 RGBA→YUV 转换等易错实现。

**Goals**:
- 用 libheif `heif.h` API 重写 `avif_jni.cpp`（保留 JNI 函数签名不变）
- 用 libheif 替换 `CMakeLists.txt` 中的 libavif FetchContent（libaom 继续保留作 AV1 编码后端）
- `MethodChannel('lumen/avif')` 协议完全不变（Dart 层、Kotlin 层零改动）
- AVIF 输出语义不变：quality 0-100、lossless flag、输出文件路径

**Non-Goals**:
- 不改 iOS 编码器（Swift ImageIO 已正常工作）
- 不改 Dart 层 `AndroidAvifEncoder` / `CompressService` / 测试
- 不启用 HEIC 编码（libheif 支持，但本项目只需 AVIF）
- 不改 `AvifEncoderChannel.kt`（Kotlin JNI 声明签名不变）
- 不改 `build.gradle.kts`（NDK + externalNativeBuild 配置保持不动）
- 不改 UI、路由、历史记录等功能

**成功标准**:
1. `flutter build apk --debug` 成功，`lumen_avif.so` 出现在 APK
2. 真机运行：选 JPEG → balanced 压缩 → `job.status == done`，输出 `.avif` 文件存在
3. `outputBytes < sourceBytes`（balanced/smaller/higherQuality 预设）
4. lossless 预设：输出文件可被系统图库正常预览

---

## 决策驱动变量

| 变量 | 类别 | 取值 | 来源 |
|---|---|---|---|
| JNI+CMake 路线可行性 | driver（已确认） | 已跑通，libaom 编译成功 | 用户确认 |
| C 代码质量问题 | driver | 手写 libavif 低层 API，RGBA→YUV 手动转换易出错 | `avif_jni.cpp` 代码审查 |
| MethodChannel 协议 | driver（硬约束） | 不能变：sourcePath/outputPath/quality/lossless | `android_avif_encoder.dart` |
| JNI 函数签名 | driver（硬约束） | 不能变：`encodeToAvif(w,h,buf,quality,lossless,path):Int` | `AvifEncoderChannel.kt:67` |
| libheif 许可证 | driver | LGPL v3（需确认 Android .so 动态链接满足合规要求） | github.com/strukturag/libheif |
| AOM_TARGET_CPU=generic | driver（保留） | 必须保留以绕过 Windows 交叉编译汇编器缺失问题 | `CMakeLists.txt:10`，已验证 |

---

## 项目事实

| 文件 | 关键内容 |
|---|---|
| `android/app/src/main/cpp/avif_jni.cpp` | 当前实现：手动 `avifRGBImageSetDefaults` → `avifImageRGBToYUV` → `avifEncoderWrite` → `ofstream` 写文件 |
| `android/app/src/main/cpp/CMakeLists.txt` | FetchContent libavif v1.1.1（AVIF_CODEC_AOM="LOCAL" 内含 libaom）；`AOM_TARGET_CPU=generic` |
| `android/app/build.gradle.kts:32-45` | `externalNativeBuild` + `ndk { abiFilters arm64-v8a, armeabi-v7a }` 不动 |
| `android/app/src/main/kotlin/.../AvifEncoderChannel.kt:67-74` | JNI 声明 `external fun encodeToAvif(...)` — 签名是契约，不能改 |
| `lib/core/codec/android/android_avif_encoder.dart` | Dart 层 MethodChannel 调用，不动 |
| `lib/features/compress/models/compress_job.dart` | presets: smaller Q70 / balanced Q85 / higherQuality Q92 / lossless Q100 + isLossless=true |

---

## 档位

**选定：方案卡**
选档理由：改动仅限 2 个 C/CMake 文件，JNI 签名和上层全部不变，属于"换引擎不换接口"的局部替换。

---

## diff 预算

| 文件 | 操作 | 预计行数 |
|---|---|---|
| `android/app/src/main/cpp/avif_jni.cpp` | 完整重写 | ~80 行（原 79 行） |
| `android/app/src/main/cpp/CMakeLists.txt` | 完整重写 | ~50 行（原 37 行） |
| 其他所有文件 | **不动** | 0 |

---

## 代码级约束（命中项）

| 约束 | 具体场景 | 检查方式 |
|---|---|---|
| 可靠性 | libheif 错误通过 `heif_error` struct 返回，需逐个检查并映射到 JNI 异常 | code review：每个 heif_* 调用后检查 `err.code != heif_error_Ok` |
| 内存安全 | libheif 对象（context/encoder/image/handle）需按序释放，异常路径也要 | 用 RAII 包装或 goto cleanup 模式；valgrind / asan 可选 |
| LGPL 合规 | libheif 是 LGPL v3；Android `.so` 动态链接满足"允许用户重新链接"要求 | APK 中 `lumen_avif.so` 动态链接 `libheif.so`（或静态链入，需确认 LGPL 条款） |
| 构建时间 | libheif + libaom 首次编译仍需 ~30 分钟（libaom 不变） | 同现在；`.cxx` 缓存后增量构建秒级 |

---

## libheif vs libavif 选型对比

| 维度 | libavif（当前） | libheif（目标） |
|---|---|---|
| GitHub ⭐ | ~1.4k | **2.3k** |
| 维护方 | AOMedia 社区 | Struktur AG（Pinterest / Shopify 赞助） |
| 许可证 | BSD-2 | LGPL v3（动态链接合规） |
| C API 层次 | 底层：需手动 RGBA→YUV、管理 avifRGBImage | **高层**：`heif_context_encode_image()` 一步完成 |
| lossless 支持 | `encoder->quality = AVIF_QUALITY_LOSSLESS` | `heif_encoder_set_lossless(encoder, 1)` |
| 错误处理 | 返回码 `avifResult`，需 `avifResultToString` | `heif_error` struct，内含 `message` 字符串 |
| AVIF 编码后端 | libaom（内置） | libaom / rav1e / svt-av1（可选，我们用 libaom）|
| CMake 集成复杂度 | 中：AVIF_CODEC_AOM="LOCAL" 一行搞定 | **中-高**：libheif 需找到已编译的 libaom |

---

## 实施细节

### 1. `CMakeLists.txt`（完整重写）

```cmake
cmake_minimum_required(VERSION 3.22.1)
project(lumen_avif CXX)

include(FetchContent)
set(FETCHCONTENT_QUIET OFF)

# ── libaom（AV1 编码后端，与之前完全相同）──────────────────
set(AOM_TARGET_CPU    "generic" CACHE STRING "" FORCE)
set(BUILD_SHARED_LIBS OFF       CACHE BOOL   "" FORCE)
set(ENABLE_TESTS      OFF       CACHE BOOL   "" FORCE)
set(ENABLE_EXAMPLES   OFF       CACHE BOOL   "" FORCE)
set(ENABLE_DOCS       OFF       CACHE BOOL   "" FORCE)

FetchContent_Declare(libaom
    GIT_REPOSITORY https://aomedia.googlesource.com/aom
    GIT_TAG        v3.9.1
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(libaom)

# ── 告知 libheif 在哪里找 libaom ────────────────────────────
# libheif 的 cmake/FindAOM.cmake 通过这两个变量定位 libaom
set(AOM_FOUND        TRUE               CACHE BOOL   "" FORCE)
set(AOM_INCLUDE_DIRS "${libaom_SOURCE_DIR}" CACHE PATH "" FORCE)
set(AOM_LIBRARIES    aom                CACHE STRING "" FORCE)

# ── libheif ─────────────────────────────────────────────────
FetchContent_Declare(libheif
    GIT_REPOSITORY https://github.com/strukturag/libheif.git
    GIT_TAG        v1.23.0      # 使用最新稳定 tag（2025-05-29）
    GIT_SHALLOW    TRUE
)
# 只启用 AVIF（AV1），关闭所有其他编解码器
set(WITH_EXAMPLES             OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING             OFF CACHE BOOL "" FORCE)
set(ENABLE_PLUGIN_LOADING     OFF CACHE BOOL "" FORCE)
set(WITH_LIBDE265             OFF CACHE BOOL "" FORCE)  # HEIC decode
set(WITH_X265                 OFF CACHE BOOL "" FORCE)  # HEIC encode
set(WITH_SvtEnc               OFF CACHE BOOL "" FORCE)
set(WITH_DAV1D                OFF CACHE BOOL "" FORCE)
set(WITH_RAV1E                OFF CACHE BOOL "" FORCE)
set(WITH_OpenJPEG_DECODER     OFF CACHE BOOL "" FORCE)
set(WITH_JPEG_DECODER         OFF CACHE BOOL "" FORCE)
set(WITH_JPEG_ENCODER         OFF CACHE BOOL "" FORCE)
set(WITH_AOM_ENCODER          ON  CACHE BOOL "" FORCE)  # AVIF encode via libaom
set(WITH_AOM_DECODER          ON  CACHE BOOL "" FORCE)  # AVIF decode via libaom
FetchContent_MakeAvailable(libheif)

# ── lumen_avif.so（JNI 包装） ───────────────────────────────
add_library(lumen_avif SHARED avif_jni.cpp)
target_compile_features(lumen_avif PRIVATE cxx_std_17)
target_include_directories(lumen_avif PRIVATE
    ${libheif_SOURCE_DIR}/include
)
target_link_libraries(lumen_avif PRIVATE heif android log)
```

### 2. `avif_jni.cpp`（用 libheif 高层 API 重写）

```cpp
#include <jni.h>
#include <android/log.h>
#include <sys/stat.h>
#include <cstring>
#include "libheif/heif.h"

#define TAG "AvifJNI"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

static void throwJava(JNIEnv *env, const char *msg) {
    env->ThrowNew(env->FindClass("java/lang/RuntimeException"), msg);
}

extern "C" JNIEXPORT jint JNICALL
Java_com_graycen_lumen_codec_AvifEncoderChannel_encodeToAvif(
    JNIEnv *env, jobject,
    jint width, jint height, jobject pixelsBuf,
    jint quality, jboolean isLossless, jstring outputPathJ)
{
    auto *pixels = static_cast<const uint8_t *>(env->GetDirectBufferAddress(pixelsBuf));
    if (!pixels) {
        throwJava(env, "pixels buffer must be a direct ByteBuffer");
        return -1;
    }
    const char *outputPath = env->GetStringUTFChars(outputPathJ, nullptr);

    heif_context  *ctx     = heif_context_alloc();
    heif_encoder  *encoder = nullptr;
    heif_image    *image   = nullptr;
    heif_image_handle *handle  = nullptr;
    heif_encoding_options *opts = nullptr;
    jint result = -1;

    auto cleanup = [&] {
        if (opts)    heif_encoding_options_free(opts);
        if (handle)  heif_image_handle_release(handle);
        if (image)   heif_image_release(image);
        if (encoder) heif_encoder_release(encoder);
        heif_context_free(ctx);
        env->ReleaseStringUTFChars(outputPathJ, outputPath);
    };

    // 获取 AV1（AVIF）编码器
    heif_error err = heif_context_get_encoder_for_format(ctx, heif_compression_AV1, &encoder);
    if (err.code != heif_error_Ok) {
        LOGE("get encoder failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return -1;
    }

    // 设置质量
    if (isLossless) {
        heif_encoder_set_lossless(encoder, 1);
    } else {
        heif_encoder_set_lossy_quality(encoder, quality);
    }

    // 创建 RGBA 图像
    err = heif_image_create(width, height,
                            heif_colorspace_RGB,
                            heif_chroma_interleaved_RGBA,
                            &image);
    if (err.code != heif_error_Ok) {
        throwJava(env, err.message);
        cleanup();
        return -1;
    }

    heif_image_add_plane(image, heif_channel_interleaved, width, height, 8);

    int stride = 0;
    uint8_t *plane = heif_image_get_plane(image, heif_channel_interleaved, &stride);
    for (int y = 0; y < height; y++) {
        memcpy(plane + y * stride, pixels + y * width * 4, (size_t)width * 4);
    }

    // 编码
    opts = heif_encoding_options_alloc();
    err  = heif_context_encode_image(ctx, image, encoder, opts, &handle);
    if (err.code != heif_error_Ok) {
        LOGE("encode failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return -1;
    }

    // 写文件
    err = heif_context_write_to_file(ctx, outputPath);
    if (err.code != heif_error_Ok) {
        LOGE("write failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return -1;
    }

    // 获取输出字节数
    struct stat st{};
    if (stat(outputPath, &st) == 0) {
        result = (jint)st.st_size;
    }

    cleanup();
    return result;
}
```

**libheif 相比旧 libavif 代码的改进**：
- 无手动 `avifRGBImage` / `avifImageRGBToYUV`：libheif 内部处理 RGB→YUV
- `heif_error.message` 直接是人可读字符串，不需要 `avifResultToString`
- lossless 有独立 API `heif_encoder_set_lossless()`，不需要 magic number
- `heif_context_write_to_file()` 代替手写 `std::ofstream`

---

## 失败模式与验证

| # | 失败模式 | 级别 | 验证项 |
|---|---|---|---|
| F-A | libheif 的 `FindAOM.cmake` 找不到我们的 FetchContent libaom → CMake 报"AOM not found" | **High** | `flutter build apk --debug`；如报错则改用 `set(AOM_FOUND TRUE ...)` 注入或检查 libheif 版本是否支持 FetchContent AOM |
| F-B | libheif tag v1.19.5 不存在或 API 有变 | **High** | 构建报错；fallback：改用 `main` 分支或查 GitHub releases 页确认最新 stable tag |
| F-C | `heif_context_get_encoder_for_format(AV1)` 返回 `heif_error_unsupported_feature`（AOM 未编入）| **High** | logcat 看 `ENCODE_FAILED` + message；确认 CMake WITH_AOM_ENCODER=ON 生效 |
| F-D | `ENABLE_PLUGIN_LOADING=OFF` 与 libheif 内部默认冲突，导致编码器注册失败 | Medium | 若 F-C 发生，尝试 `ENABLE_PLUGIN_LOADING=ON` 并将 libaom plugin .so 一起打包 |
| F-E | LGPL 合规：静态链接 libheif 进 lumen_avif.so 被认为是"衍生作品" | Low | 确认 `target_link_libraries(lumen_avif PRIVATE heif)`：Android 动态链接 .so 满足 LGPL 要求；若法务要求则改动态链接 libheif |
| F-F | 输出 AVIF 文件无法被 iOS/PC 预览（HEIF 容器兼容性） | Low | 在 iOS Files app 和 Windows 照片查看器打开输出文件验证 |

---

## 推荐与决策

**推荐方案：JNI + CMake + libheif**（用户已确认路线，本文件记录实施契约）

**为什么 libheif 优于当前 libavif**：
- 维护质量更高（Struktur AG 公司出品，2.3k ⭐ vs libavif 1.4k ⭐，赞助方包括 Pinterest/Shopify）
- C API 层次更高，消除手动 YUV 转换等易错逻辑
- `heif_error.message` 提供可读错误字符串，调试更容易
- 同为主流开源项目，Homebrew / Debian / Arch 均有官方包

**影响范围**：仅 `avif_jni.cpp` 和 `CMakeLists.txt`，其他全部不动

**diff 预算**：2 文件，净变化约 +20 行（libheif CMake 配置比 libavif 多，但 C++ 代码质量更高）

**下一步实施边界**（building 契约）：
1. 重写 `CMakeLists.txt`（用 libheif 替换 libavif）
2. 重写 `avif_jni.cpp`（用 heif.h API）
3. 运行 `flutter build apk --debug` 验证编译
4. 真机跑一次完整压缩流程验证 F-A / F-B / F-C

**重评估条件**：
- 若 libheif 的 CMake FetchContent 集成无法让它找到我们的 libaom → 考虑切回 libavif（已验证可用）或改用 ExternalProject_Add 精确控制
- 若 LGPL 合规有法务风险 → 改用 libavif（BSD-2）

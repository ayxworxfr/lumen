#include <jni.h>
#include <android/log.h>
#include <sys/stat.h>
#include <cstring>
#include <algorithm>
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

    heif_context        *ctx     = heif_context_alloc();
    heif_encoder        *encoder = nullptr;
    heif_image          *image   = nullptr;
    heif_image_handle   *handle  = nullptr;
    heif_encoding_options *opts  = nullptr;
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
        heif_encoder_set_lossy_quality(encoder, (int)quality);
    }

    // 创建 RGBA 图像
    err = heif_image_create(width, height,
                            heif_colorspace_RGB,
                            heif_chroma_interleaved_RGBA,
                            &image);
    if (err.code != heif_error_Ok) {
        LOGE("heif_image_create failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return -1;
    }

    heif_image_add_plane(image, heif_channel_interleaved, width, height, 8);

    int stride = 0;
    uint8_t *plane = heif_image_get_plane(image, heif_channel_interleaved, &stride);
    for (int y = 0; y < height; y++) {
        memcpy(plane + y * stride, pixels + (size_t)y * (size_t)width * 4, (size_t)width * 4);
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

    // 返回输出字节数
    struct stat st{};
    if (stat(outputPath, &st) == 0) {
        result = (jint)st.st_size;
    }

    cleanup();
    return result;
}

/// 解码 AVIF 文件，返回 RGBA 像素数据（direct ByteBuffer）。
/// maxSide > 0 时按比例缩小到 maxSide × maxSide 以内（libheif 原生缩放）。
/// 返回 ByteBuffer，调用方负责读取 width/height（通过 out 数组传回）。
extern "C" JNIEXPORT jobject JNICALL
Java_com_graycen_lumen_codec_AvifEncoderChannel_decodeAvif(
    JNIEnv *env, jobject,
    jstring pathJ, jint maxSide, jintArray outDimensions)
{
    const char *path = env->GetStringUTFChars(pathJ, nullptr);

    heif_context      *ctx    = heif_context_alloc();
    heif_image_handle *handle = nullptr;
    heif_image        *image  = nullptr;

    auto cleanup = [&] {
        if (image)  heif_image_release(image);
        if (handle) heif_image_handle_release(handle);
        heif_context_free(ctx);
        env->ReleaseStringUTFChars(pathJ, path);
    };

    heif_error err = heif_context_read_from_file(ctx, path, nullptr);
    if (err.code != heif_error_Ok) {
        LOGE("read failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return nullptr;
    }

    err = heif_context_get_primary_image_handle(ctx, &handle);
    if (err.code != heif_error_Ok) {
        LOGE("get primary handle failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return nullptr;
    }

    // 计算缩放尺寸（maxSide <= 0 表示不缩放）
    int origW = heif_image_handle_get_width(handle);
    int origH = heif_image_handle_get_height(handle);
    int decodeW = origW;
    int decodeH = origH;
    if (maxSide > 0 && (origW > maxSide || origH > maxSide)) {
        float scale = static_cast<float>(maxSide) / static_cast<float>(std::max(origW, origH));
        decodeW = static_cast<int>(origW * scale);
        decodeH = static_cast<int>(origH * scale);
    }

    heif_decoding_options *decOpts = heif_decoding_options_alloc();
    decOpts->convert_hdr_to_8bit = 1;
    err = heif_decode_image(handle, &image,
                            heif_colorspace_RGB, heif_chroma_interleaved_RGBA,
                            decOpts);
    heif_decoding_options_free(decOpts);

    if (err.code != heif_error_Ok) {
        LOGE("decode failed: %s", err.message);
        throwJava(env, err.message);
        cleanup();
        return nullptr;
    }

    // libheif 不支持 decode 时直接缩放，需要在 decode 后缩放
    if (decodeW != origW || decodeH != origH) {
        heif_image *scaled = nullptr;
        err = heif_image_scale_image(image, &scaled, decodeW, decodeH, nullptr);
        heif_image_release(image);
        image = nullptr;
        if (err.code != heif_error_Ok) {
            LOGE("scale failed: %s", err.message);
            throwJava(env, err.message);
            cleanup();
            return nullptr;
        }
        image = scaled;
    }

    int finalW = heif_image_get_width(image, heif_channel_interleaved);
    int finalH = heif_image_get_height(image, heif_channel_interleaved);

    int stride = 0;
    const uint8_t *plane = heif_image_get_plane_readonly(image, heif_channel_interleaved, &stride);
    if (!plane) {
        throwJava(env, "Failed to get image plane");
        cleanup();
        return nullptr;
    }

    // 写出宽高供 Kotlin 使用
    jint dims[2] = { (jint)finalW, (jint)finalH };
    env->SetIntArrayRegion(outDimensions, 0, 2, dims);

    // 用 byte[] 传回像素，避免 NewDirectByteBuffer 的 native 内存生命周期问题
    size_t bufSize = (size_t)finalW * (size_t)finalH * 4;
    jbyteArray byteArr = env->NewByteArray((jsize)bufSize);
    if (!byteArr) {
        throwJava(env, "Failed to allocate output byte array");
        cleanup();
        return nullptr;
    }

    // 逐行拷贝（消除 stride padding）
    jbyte *dst = env->GetByteArrayElements(byteArr, nullptr);
    for (int y = 0; y < finalH; y++) {
        memcpy(dst + (size_t)y * finalW * 4,
               plane + (size_t)y * stride,
               (size_t)finalW * 4);
    }
    env->ReleaseByteArrayElements(byteArr, dst, 0);

    cleanup();
    return byteArr;
}

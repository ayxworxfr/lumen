#include <jni.h>
#include <android/log.h>
#include <fstream>
#include <cstring>
#include "avif/avif.h"

#define TAG "AvifJNI"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

extern "C" JNIEXPORT jint JNICALL
Java_com_graycen_lumen_codec_AvifEncoderChannel_encodeToAvif(
    JNIEnv *env, jobject /* thiz */,
    jint width, jint height, jobject pixelsBuf,
    jint quality, jboolean isLossless, jstring outputPathJ)
{
    auto *pixels = static_cast<uint8_t *>(env->GetDirectBufferAddress(pixelsBuf));
    if (!pixels) {
        env->ThrowNew(env->FindClass("java/lang/IllegalArgumentException"),
                      "pixels buffer must be a direct ByteBuffer");
        return -1;
    }

    const char *outputPath = env->GetStringUTFChars(outputPathJ, nullptr);

    avifImage *image = avifImageCreate(width, height, 8, AVIF_PIXEL_FORMAT_YUV444);
    if (!image) {
        env->ReleaseStringUTFChars(outputPathJ, outputPath);
        env->ThrowNew(env->FindClass("java/lang/RuntimeException"), "avifImageCreate failed");
        return -1;
    }

    avifRGBImage rgb;
    avifRGBImageSetDefaults(&rgb, image);
    rgb.format = AVIF_RGB_FORMAT_RGBA;
    avifResult rgbResult = avifRGBImageAllocatePixels(&rgb);
    if (rgbResult != AVIF_RESULT_OK) {
        avifImageDestroy(image);
        env->ReleaseStringUTFChars(outputPathJ, outputPath);
        env->ThrowNew(env->FindClass("java/lang/RuntimeException"), avifResultToString(rgbResult));
        return -1;
    }

    memcpy(rgb.pixels, pixels, (size_t)rgb.rowBytes * (size_t)height);

    avifResult yuvResult = avifImageRGBToYUV(image, &rgb);
    avifRGBImageFreePixels(&rgb);
    if (yuvResult != AVIF_RESULT_OK) {
        avifImageDestroy(image);
        env->ReleaseStringUTFChars(outputPathJ, outputPath);
        env->ThrowNew(env->FindClass("java/lang/RuntimeException"), avifResultToString(yuvResult));
        return -1;
    }

    avifEncoder *encoder = avifEncoderCreate();
    encoder->quality      = isLossless ? AVIF_QUALITY_LOSSLESS : (int)quality;
    encoder->qualityAlpha = AVIF_QUALITY_LOSSLESS;
    encoder->speed        = 6;

    avifRWData output = AVIF_DATA_EMPTY;
    avifResult encResult = avifEncoderWrite(encoder, image, &output);
    avifEncoderDestroy(encoder);
    avifImageDestroy(image);

    if (encResult != AVIF_RESULT_OK) {
        avifRWDataFree(&output);
        env->ReleaseStringUTFChars(outputPathJ, outputPath);
        env->ThrowNew(env->FindClass("java/lang/RuntimeException"), avifResultToString(encResult));
        return -1;
    }

    std::ofstream ofs(outputPath, std::ios::binary);
    ofs.write(reinterpret_cast<const char *>(output.data), (std::streamsize)output.size);
    jint bytesWritten = (jint)output.size;

    avifRWDataFree(&output);
    env->ReleaseStringUTFChars(outputPathJ, outputPath);
    return bytesWritten;
}

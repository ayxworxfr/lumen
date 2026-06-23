package com.graycen.lumen.codec

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

object AvifEncoderChannel {

    private const val CHANNEL_NAME = "lumen/avif"

    init {
        System.loadLibrary("lumen_avif")
    }

    fun register(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "encode" -> handleEncode(call.arguments, result)
                "decode" -> handleDecode(call.arguments, result)
                else     -> result.notImplemented()
            }
        }
    }

    private fun handleEncode(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGS", "Arguments must be a map", null)
            return
        }

        val sourcePath = args["sourcePath"] as? String
        val outputPath = args["outputPath"] as? String
        val quality    = args["quality"]    as? Int
        val isLossless = args["lossless"]   as? Boolean

        if (sourcePath == null || outputPath == null || quality == null || isLossless == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        Thread {
            try {
                val opts = BitmapFactory.Options().apply {
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                }
                val bitmap = BitmapFactory.decodeFile(sourcePath, opts)
                    ?: throw Exception("Cannot decode source image: $sourcePath")

                val buf = ByteBuffer.allocateDirect(bitmap.byteCount)
                bitmap.copyPixelsToBuffer(buf)
                val bitmapWidth  = bitmap.width
                val bitmapHeight = bitmap.height
                bitmap.recycle()

                val outputBytes = encodeToAvif(
                    bitmapWidth, bitmapHeight, buf,
                    quality, isLossless, outputPath
                )
                result.success(mapOf("outputPath" to outputPath, "outputBytes" to outputBytes))
            } catch (e: Exception) {
                result.error("ENCODE_FAILED", e.message, null)
            }
        }.start()
    }

    private fun handleDecode(arguments: Any?, result: MethodChannel.Result) {
        val args = arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGS", "Arguments must be a map", null)
            return
        }

        val path    = args["path"]    as? String
        val maxSide = (args["maxSide"] as? Int) ?: 0

        if (path == null) {
            result.error("INVALID_ARGS", "Missing path argument", null)
            return
        }

        Thread {
            try {
                // JNI 解码 AVIF → RGBA 像素
                val dims = IntArray(2)
                val rgba: ByteArray = decodeAvif(path, maxSide, dims)
                val width  = dims[0]
                val height = dims[1]

                // RGBA byte[] → Bitmap → JPEG byte[]
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                // copyPixelsFromBuffer 期望 ARGB（Android 内存顺序与 RGBA 相同）
                bitmap.copyPixelsFromBuffer(java.nio.ByteBuffer.wrap(rgba))

                val out = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
                bitmap.recycle()

                result.success(out.toByteArray())
            } catch (e: Exception) {
                result.error("DECODE_FAILED", e.message, null)
            }
        }.start()
    }

    private external fun encodeToAvif(
        width: Int,
        height: Int,
        pixels: ByteBuffer,
        quality: Int,
        isLossless: Boolean,
        outputPath: String
    ): Int

    private external fun decodeAvif(
        path: String,
        maxSide: Int,
        outDimensions: IntArray
    ): ByteArray
}

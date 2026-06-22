package com.graycen.lumen.codec

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

object AvifEncoderChannel {

    private const val CHANNEL_NAME = "lumen/avif"

    init {
        System.loadLibrary("lumen_avif")
    }

    fun register(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            if (call.method != "encode") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val args = call.arguments as? Map<*, *>
            if (args == null) {
                result.error("INVALID_ARGS", "Arguments must be a map", null)
                return@setMethodCallHandler
            }

            val sourcePath = args["sourcePath"] as? String
            val outputPath = args["outputPath"] as? String
            val quality    = args["quality"]    as? Int
            val isLossless = args["lossless"]   as? Boolean

            if (sourcePath == null || outputPath == null || quality == null || isLossless == null) {
                result.error("INVALID_ARGS", "Missing required arguments", null)
                return@setMethodCallHandler
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
    }

    private external fun encodeToAvif(
        width: Int,
        height: Int,
        pixels: ByteBuffer,
        quality: Int,
        isLossless: Boolean,
        outputPath: String
    ): Int
}

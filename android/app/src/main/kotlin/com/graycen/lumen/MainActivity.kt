package com.graycen.lumen

import com.graycen.lumen.codec.AvifEncoderChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AvifEncoderChannel.register(flutterEngine)
    }
}

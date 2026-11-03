package com.zhao.serial.dbg

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PingMethodChannel.register(flutterEngine.dartExecutor.binaryMessenger)
        AndroidPlatformMethodChannel.register(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }
}

package com.zhao.serial.dbg

import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 提供 Dart 侧进行 Android 版本分支所需的只读平台信息。
 */
object AndroidPlatformMethodChannel {
    private const val CHANNEL_NAME = "com.zhao.serial.dbg/platform"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                else -> result.notImplemented()
            }
        }
    }
}

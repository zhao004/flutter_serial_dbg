package com.zhao.serial.dbg

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 提供 Dart 侧所需的 Android 版本、CPU 架构和安装权限能力。
 */
object AndroidPlatformMethodChannel {
    private const val CHANNEL_NAME = "com.zhao.serial.dbg/platform"

    fun register(activity: Activity, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                "getSupportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "canRequestPackageInstalls" -> result.success(canRequestPackageInstalls(activity))
                "openInstallPermissionSettings" -> {
                    openInstallPermissionSettings(activity, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canRequestPackageInstalls(activity: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallPermissionSettings(
        activity: Activity,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(true)
            return
        }
        val intent = Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:${activity.packageName}"),
        )
        try {
            activity.startActivity(intent)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            result.error("SETTINGS_UNAVAILABLE", "无法打开安装权限设置", null)
        } catch (_: RuntimeException) {
            result.error("SETTINGS_UNAVAILABLE", "无法打开安装权限设置", null)
        }
    }
}

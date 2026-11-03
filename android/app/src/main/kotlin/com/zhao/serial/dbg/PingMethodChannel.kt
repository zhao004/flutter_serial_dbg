package com.zhao.serial.dbg

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress
import java.util.concurrent.Executors

/**
 * 在后台线程执行 Android 原生 ICMP 可达性检测。
 *
 * 该通道不记录目标地址或异常详情，避免诊断日志泄露设备标识。
 */
object PingMethodChannel {
    private const val CHANNEL_NAME = "com.zhao.serial.dbg/diagnostics"
    private const val MAX_HOST_LENGTH = 255
    private const val MIN_TIMEOUT_MS = 100
    private const val MAX_TIMEOUT_MS = 30_000

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "isReachable" -> handlePing(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handlePing(call: MethodCall, result: MethodChannel.Result) {
        val host = call.argument<String>("host")?.trim().orEmpty()
        val timeoutMs = call.argument<Number>("timeoutMs")?.toInt() ?: 0
        if (host.isEmpty() || host.length > MAX_HOST_LENGTH) {
            result.error("invalid_host", "Ping 目标无效", null)
            return
        }
        if (timeoutMs !in MIN_TIMEOUT_MS..MAX_TIMEOUT_MS) {
            result.error("invalid_timeout", "Ping 超时参数无效", null)
            return
        }

        executor.execute {
            try {
                val reachable = InetAddress.getByName(host).isReachable(timeoutMs)
                mainHandler.post { result.success(reachable) }
            } catch (_: Exception) {
                mainHandler.post {
                    result.error("ping_failed", "Ping 执行失败", null)
                }
            }
        }
    }
}

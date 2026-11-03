import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../models/ping_result.dart';
import '../../utils/constants.dart';

/// 网络诊断能力接口，便于页面测试注入替代实现。
abstract interface class NetworkDiagnostics {
  /// 返回当前设备非回环 IPv4 地址。
  Future<List<String>> localIpv4Addresses();

  /// 使用 Android 原生 ICMP 能力执行 Ping。
  Future<PingResult> ping(
    String host, {
    Duration timeout = NetworkDefaults.pingTimeout,
  });
}

/// 基于 dart:io 和 Android MethodChannel 的默认诊断实现。
final class PlatformNetworkDiagnostics implements NetworkDiagnostics {
  const PlatformNetworkDiagnostics();

  static const MethodChannel _channel = MethodChannel(
    'com.zhao.serial.dbg/diagnostics',
  );

  @override
  Future<List<String>> localIpv4Addresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      final addresses =
          interfaces
              .expand((interface) => interface.addresses)
              .where((address) => !address.isLoopback)
              .map((address) => address.address)
              .toSet()
              .toList()
            ..sort();
      return addresses;
    } on SocketException {
      throw const NetworkDiagnosticsException('读取本机网络地址失败');
    }
  }

  @override
  Future<PingResult> ping(
    String host, {
    Duration timeout = NetworkDefaults.pingTimeout,
  }) async {
    final normalized = host.trim();
    if (normalized.isEmpty) {
      throw const NetworkDiagnosticsException('Ping 目标不能为空');
    }
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 30)) {
      throw const NetworkDiagnosticsException('Ping 超时参数无效');
    }

    final stopwatch = Stopwatch()..start();
    try {
      final reachable = await _channel
          .invokeMethod<bool>('isReachable', <String, Object>{
            'host': normalized,
            'timeoutMs': timeout.inMilliseconds,
          })
          .timeout(timeout + const Duration(seconds: 1));
      stopwatch.stop();
      if (reachable == true) {
        return PingResult(
          target: normalized,
          status: PingStatus.success,
          duration: stopwatch.elapsed,
        );
      }
      return PingResult(
        target: normalized,
        status: PingStatus.unreachable,
        duration: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();
      return PingResult(
        target: normalized,
        status: PingStatus.timeout,
        duration: stopwatch.elapsed,
      );
    } on MissingPluginException {
      throw const NetworkDiagnosticsException('当前平台不支持 Ping 诊断');
    } on PlatformException {
      throw const NetworkDiagnosticsException('Ping 执行失败，请检查目标地址');
    }
  }
}

/// 网络诊断的可展示异常。
final class NetworkDiagnosticsException implements Exception {
  const NetworkDiagnosticsException(this.message);

  final String message;

  @override
  String toString() => message;
}

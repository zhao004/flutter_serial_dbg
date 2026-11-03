import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// BLE 运行时权限结果。
enum BlePermissionOutcome { granted, denied, permanentlyDenied, unsupported }

/// BLE 权限申请边界，便于无设备测试。
abstract interface class BlePermissionService {
  /// 按 Android 版本申请扫描和连接所需权限。
  Future<BlePermissionOutcome> request();

  /// 打开系统应用设置页。
  Future<bool> openSettings();
}

/// Android 版本感知的 BLE 权限实现。
final class AndroidBlePermissionService implements BlePermissionService {
  const AndroidBlePermissionService();

  static const MethodChannel _channel = MethodChannel(
    'com.zhao.serial.dbg/platform',
  );

  @override
  Future<BlePermissionOutcome> request() async {
    if (!Platform.isAndroid) {
      return BlePermissionOutcome.unsupported;
    }
    final sdkInt = await _channel.invokeMethod<int>('getAndroidSdkInt');
    if (sdkInt == null || sdkInt < 21) {
      return BlePermissionOutcome.unsupported;
    }

    final permissions = sdkInt >= 31
        ? <Permission>[Permission.bluetoothScan, Permission.bluetoothConnect]
        : <Permission>[Permission.locationWhenInUse];
    final statuses = await permissions.request();
    if (permissions.every(
      (permission) => statuses[permission]?.isGranted == true,
    )) {
      return BlePermissionOutcome.granted;
    }
    if (permissions.any(
      (permission) => statuses[permission]?.isPermanentlyDenied == true,
    )) {
      return BlePermissionOutcome.permanentlyDenied;
    }
    return BlePermissionOutcome.denied;
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}

import 'package:flutter/services.dart';

import '../../models/app_update.dart';

/// Android 更新所需的平台能力边界。
abstract interface class UpdatePlatformService {
  /// 返回系统支持的 ABI，优先项排在前面。
  Future<List<String>> supportedAbis();

  /// 判断当前应用是否可以请求安装未知来源应用。
  Future<bool> canRequestPackageInstalls();

  /// 打开当前应用的未知来源安装权限设置。
  Future<bool> openInstallPermissionSettings();
}

/// 通过 Android MethodChannel 提供的更新平台能力。
final class AndroidUpdatePlatformService implements UpdatePlatformService {
  const AndroidUpdatePlatformService();

  static const MethodChannel _channel = MethodChannel(
    'com.zhao.serial.dbg/platform',
  );

  @override
  Future<List<String>> supportedAbis() async {
    try {
      final values = await _channel.invokeListMethod<String>(
        'getSupportedAbis',
      );
      if (values == null || values.isEmpty) {
        throw const AppUpdateException(
          AppUpdateFailureKind.unsupportedPlatform,
          '无法识别当前设备架构',
        );
      }
      return List<String>.unmodifiable(values);
    } on MissingPluginException {
      throw const AppUpdateException(
        AppUpdateFailureKind.unsupportedPlatform,
        '当前平台不支持应用内更新',
      );
    } on PlatformException {
      throw const AppUpdateException(
        AppUpdateFailureKind.unsupportedPlatform,
        '无法识别当前设备架构',
      );
    }
  }

  @override
  Future<bool> canRequestPackageInstalls() async {
    try {
      return await _channel.invokeMethod<bool>('canRequestPackageInstalls') ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    try {
      return await _channel.invokeMethod<bool>(
            'openInstallPermissionSettings',
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

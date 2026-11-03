import 'dart:async';

import 'package:ota_update/ota_update.dart';

import '../../models/app_update.dart';

/// APK 下载与系统安装的边界。
abstract interface class ApkInstaller {
  /// 下载指定资产并拉起 Android 系统安装界面。
  Stream<ApkInstallEvent> install(AvailableUpdate update);

  /// 取消正在进行的下载。
  Future<void> cancel();
}

/// 基于 `ota_update` 的 APK 下载与安装实现。
final class OtaApkInstaller implements ApkInstaller {
  OtaUpdate? _activeUpdate;

  @override
  Stream<ApkInstallEvent> install(AvailableUpdate update) async* {
    final otaUpdate = OtaUpdate();
    _activeUpdate = otaUpdate;
    try {
      final events = otaUpdate.execute(
        update.asset.downloadUri.toString(),
        headers: const <String, String>{
          'Accept': 'application/octet-stream',
          'User-Agent': 'SerialDbg-Android',
        },
        destinationFilename: update.asset.fileName,
        sha256checksum: update.asset.sha256,
        usePackageInstaller: false,
      );
      await for (final event in events) {
        yield _mapEvent(event);
      }
    } finally {
      if (identical(_activeUpdate, otaUpdate)) {
        _activeUpdate = null;
      }
    }
  }

  @override
  Future<void> cancel() async {
    final activeUpdate = _activeUpdate;
    if (activeUpdate == null) {
      return;
    }
    try {
      await activeUpdate.cancel();
    } catch (_) {
      // 下载已结束时取消无副作用，插件错误不向界面泄露。
    }
  }

  ApkInstallEvent _mapEvent(OtaEvent event) {
    return switch (event.status) {
      OtaStatus.DOWNLOADING => ApkInstallEvent.downloading(
        _parseProgress(event.value),
      ),
      OtaStatus.INSTALLING => const ApkInstallEvent.installing(),
      OtaStatus.INSTALLATION_DONE => const ApkInstallEvent.completed(),
      OtaStatus.CANCELED => const ApkInstallEvent.cancelled(),
      OtaStatus.CHECKSUM_ERROR => const ApkInstallEvent.failed(
        AppUpdateFailureKind.checksumFailed,
        '安装包完整性校验失败，请重试',
      ),
      OtaStatus.PERMISSION_NOT_GRANTED_ERROR => const ApkInstallEvent.failed(
        AppUpdateFailureKind.permissionDenied,
        '需要允许安装应用后才能继续更新',
      ),
      OtaStatus.DOWNLOAD_ERROR => const ApkInstallEvent.failed(
        AppUpdateFailureKind.downloadFailed,
        '下载安装包失败，请检查网络后重试',
      ),
      OtaStatus.INSTALLATION_ERROR ||
      OtaStatus.INTERNAL_ERROR ||
      OtaStatus.ALREADY_RUNNING_ERROR => const ApkInstallEvent.failed(
        AppUpdateFailureKind.installFailed,
        '启动系统安装失败，请稍后重试',
      ),
    };
  }

  double _parseProgress(String? value) {
    final percentage = int.tryParse(value ?? '');
    if (percentage == null) {
      return 0;
    }
    return (percentage / 100).clamp(0, 1);
  }
}

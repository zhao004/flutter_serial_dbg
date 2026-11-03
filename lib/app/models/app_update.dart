import 'package:pub_semver/pub_semver.dart';

/// 已安装应用的版本信息。
final class InstalledAppInfo {
  const InstalledAppInfo({
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });

  /// Android versionName。
  final String version;

  /// Android versionCode 对应的构建号。
  final String buildNumber;

  /// 当前 Android 应用包名。
  final String packageName;

  /// 设置页展示的完整版本号。
  String get displayVersion {
    return buildNumber.isEmpty ? version : '$version ($buildNumber)';
  }
}

/// 与当前设备 ABI 匹配的发布 APK。
final class UpdateAsset {
  const UpdateAsset({
    required this.abi,
    required this.fileName,
    required this.downloadUri,
    required this.sizeBytes,
    required this.sha256,
  });

  /// APK 对应的 Android ABI。
  final String abi;

  /// Release 中的资产文件名。
  final String fileName;

  /// GitHub Release 的 HTTPS 下载地址。
  final Uri downloadUri;

  /// 资产字节数。
  final int sizeBytes;

  /// 小写十六进制 SHA-256 摘要。
  final String sha256;
}

/// 可在当前设备上安装的新版本。
final class AvailableUpdate {
  const AvailableUpdate({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.asset,
    this.publishedAt,
  });

  /// 语义化版本号。
  final Version version;

  /// GitHub Release 标签。
  final String tagName;

  /// Release 正文。
  final String releaseNotes;

  /// 与设备 ABI 匹配的 APK。
  final UpdateAsset asset;

  /// Release 发布时间。
  final DateTime? publishedAt;
}

/// 一次更新检查的结果。
final class UpdateCheckResult {
  const UpdateCheckResult({required this.installed, this.update});

  /// 当前安装版本。
  final InstalledAppInfo installed;

  /// 可安装的新版本；已是最新版时为空。
  final AvailableUpdate? update;

  /// 是否存在可安装的新版本。
  bool get hasUpdate => update != null;
}

/// 更新流程中的失败分类。
enum AppUpdateFailureKind {
  network,
  rateLimited,
  noRelease,
  invalidRelease,
  incompatibleDevice,
  checksumUnavailable,
  permissionDenied,
  downloadFailed,
  checksumFailed,
  installFailed,
  cancelled,
  unsupportedPlatform,
}

/// 更新能力的可展示异常。
final class AppUpdateException implements Exception {
  const AppUpdateException(this.kind, this.message);

  /// 稳定的失败分类，用于控制器映射状态。
  final AppUpdateFailureKind kind;

  /// 可安全展示给用户的中文说明。
  final String message;

  @override
  String toString() => message;
}

/// APK 安装过程对外发布的事件类型。
enum ApkInstallEventType {
  downloading,
  installing,
  completed,
  cancelled,
  failed,
}

/// APK 下载或安装过程中的单个事件。
final class ApkInstallEvent {
  const ApkInstallEvent.downloading(this.progress)
    : type = ApkInstallEventType.downloading,
      failureKind = null,
      message = null;

  const ApkInstallEvent.installing()
    : type = ApkInstallEventType.installing,
      progress = null,
      failureKind = null,
      message = null;

  const ApkInstallEvent.completed()
    : type = ApkInstallEventType.completed,
      progress = null,
      failureKind = null,
      message = null;

  const ApkInstallEvent.cancelled()
    : type = ApkInstallEventType.cancelled,
      progress = null,
      failureKind = null,
      message = null;

  const ApkInstallEvent.failed(this.failureKind, this.message)
    : type = ApkInstallEventType.failed,
      progress = null;

  /// 当前事件类型。
  final ApkInstallEventType type;

  /// 下载进度，范围为 0 到 1。
  final double? progress;

  /// 失败分类，仅失败事件有值。
  final AppUpdateFailureKind? failureKind;

  /// 可安全展示的中文失败说明。
  final String? message;
}

/// 更新控制器的主状态。
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  awaitingInstall,
  upToDate,
  failed,
}

/// 更新页面使用的不可变状态快照。
final class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.installed,
    this.update,
    this.progress,
    this.errorMessage,
  });

  /// 当前流程状态。
  final UpdateStatus status;

  /// 已读取的安装版本信息。
  final InstalledAppInfo? installed;

  /// 当前发现的可用更新。
  final AvailableUpdate? update;

  /// 下载进度，范围为 0 到 1。
  final double? progress;

  /// 当前可展示的失败原因。
  final String? errorMessage;

  /// 是否正在执行更新检查或 APK 下载。
  bool get isBusy {
    return status == UpdateStatus.checking ||
        status == UpdateStatus.downloading;
  }
}

/// 更新提示的消息类型。
enum UpdateNoticeKind { info, success, warning, error }

/// 需要由页面展示一次的短暂更新提示。
final class UpdateNotice {
  const UpdateNotice(this.message, this.kind);

  /// 可安全展示的中文提示。
  final String message;

  /// 提示级别。
  final UpdateNoticeKind kind;
}

/// 更新检查触发来源。
enum UpdateCheckTrigger { automatic, manual }

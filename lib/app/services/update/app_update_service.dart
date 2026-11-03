import 'package:pub_semver/pub_semver.dart';

import '../../models/app_update.dart';
import 'apk_installer.dart';
import 'github_release_client.dart';
import 'installed_app_info_provider.dart';
import 'update_platform_service.dart';

/// 更新检查、资产选择和安装编排的数据边界。
abstract interface class AppUpdateService {
  /// 读取当前安装应用版本。
  Future<InstalledAppInfo> installedInfo();

  /// 检查固定 GitHub 仓库是否存在适用新版本。
  Future<UpdateCheckResult> checkForUpdate();

  /// 下载并安装指定更新。
  Stream<ApkInstallEvent> install(AvailableUpdate update);

  /// 取消正在进行的 APK 下载。
  Future<void> cancelDownload();

  /// 判断当前应用能否拉起系统安装器。
  Future<bool> canRequestPackageInstalls();

  /// 打开当前应用的安装未知来源权限设置。
  Future<bool> openInstallPermissionSettings();
}

/// 串联 GitHub、安装版本、设备 ABI 和 Android 安装器的默认实现。
final class GitHubAppUpdateService implements AppUpdateService {
  factory GitHubAppUpdateService({
    required GitHubReleaseClient releaseClient,
    required InstalledAppInfoProvider installedAppInfoProvider,
    required UpdatePlatformService platformService,
    required ApkInstaller apkInstaller,
  }) {
    return GitHubAppUpdateService._(
      releaseClient,
      installedAppInfoProvider,
      platformService,
      apkInstaller,
    );
  }

  GitHubAppUpdateService._(
    this._releaseClient,
    this._installedAppInfoProvider,
    this._platformService,
    this._apkInstaller,
  );

  static final RegExp _stableTagPattern = RegExp(
    r'^v(\d+\.\d+\.\d+)(?:\+[0-9A-Za-z.-]+)?$',
  );
  static final RegExp _apkContentTypePattern = RegExp(
    r'^application/(?:vnd\.android\.package-archive|octet-stream)$',
  );
  static final RegExp _sha256DigestPattern = RegExp(
    r'^sha256:([0-9a-fA-F]{64})$',
  );
  static const String _expectedDownloadPrefix =
      '/zhao004/flutter_serial_dbg/releases/download/';

  final GitHubReleaseClient _releaseClient;
  final InstalledAppInfoProvider _installedAppInfoProvider;
  final UpdatePlatformService _platformService;
  final ApkInstaller _apkInstaller;

  @override
  Future<InstalledAppInfo> installedInfo() {
    return _installedAppInfoProvider.load();
  }

  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    final installed = await _installedAppInfoProvider.load();
    final currentVersion = _parseInstalledVersion(installed.version);
    final release = await _releaseClient.fetchLatestStableRelease(
      userAgent: 'SerialDbg/${installed.version}',
    );
    final remoteVersion = _parseReleaseVersion(release);
    if (remoteVersion <= currentVersion) {
      return UpdateCheckResult(installed: installed);
    }

    final abis = await _platformService.supportedAbis();
    final asset = _selectAsset(release, abis);
    return UpdateCheckResult(
      installed: installed,
      update: AvailableUpdate(
        version: remoteVersion,
        tagName: release.tagName,
        releaseNotes: release.body.trim().isEmpty
            ? '该版本未提供更新说明。'
            : release.body.trim(),
        asset: asset,
        publishedAt: release.publishedAt,
      ),
    );
  }

  @override
  Stream<ApkInstallEvent> install(AvailableUpdate update) {
    return _apkInstaller.install(update);
  }

  @override
  Future<void> cancelDownload() {
    return _apkInstaller.cancel();
  }

  @override
  Future<bool> canRequestPackageInstalls() {
    return _platformService.canRequestPackageInstalls();
  }

  @override
  Future<bool> openInstallPermissionSettings() {
    return _platformService.openInstallPermissionSettings();
  }

  Version _parseInstalledVersion(String value) {
    try {
      return Version.parse(value);
    } on FormatException {
      throw const AppUpdateException(
        AppUpdateFailureKind.unsupportedPlatform,
        '当前应用版本格式无效，无法检查更新',
      );
    }
  }

  Version _parseReleaseVersion(GitHubRelease release) {
    if (release.draft ||
        release.prerelease ||
        !_stableTagPattern.hasMatch(release.tagName)) {
      throw const AppUpdateException(
        AppUpdateFailureKind.invalidRelease,
        '当前没有可用的稳定版本',
      );
    }
    try {
      return Version.parse(release.tagName.substring(1));
    } on FormatException {
      throw const AppUpdateException(
        AppUpdateFailureKind.invalidRelease,
        'GitHub 版本号格式无效',
      );
    }
  }

  UpdateAsset _selectAsset(GitHubRelease release, List<String> abis) {
    for (final abi in abis) {
      final expectedName = 'serialdbg-${release.tagName}-$abi.apk';
      for (final asset in release.assets) {
        if (asset.name != expectedName) {
          continue;
        }
        if (asset.size <= 0 ||
            !_apkContentTypePattern.hasMatch(asset.contentType)) {
          throw const AppUpdateException(
            AppUpdateFailureKind.invalidRelease,
            'GitHub 安装包信息无效',
          );
        }
        final digestMatch = _sha256DigestPattern.firstMatch(asset.digest ?? '');
        if (digestMatch == null) {
          throw const AppUpdateException(
            AppUpdateFailureKind.checksumUnavailable,
            '安装包缺少安全校验信息，已停止更新',
          );
        }
        final downloadUri = Uri.tryParse(asset.downloadUrl);
        if (downloadUri == null ||
            downloadUri.scheme != 'https' ||
            downloadUri.host != 'github.com' ||
            !downloadUri.path.startsWith(_expectedDownloadPrefix)) {
          throw const AppUpdateException(
            AppUpdateFailureKind.invalidRelease,
            'GitHub 安装包下载地址无效',
          );
        }
        return UpdateAsset(
          abi: abi,
          fileName: asset.name,
          downloadUri: downloadUri,
          sizeBytes: asset.size,
          sha256: digestMatch.group(1)!.toLowerCase(),
        );
      }
    }
    throw const AppUpdateException(
      AppUpdateFailureKind.incompatibleDevice,
      '当前设备架构没有可用的安装包',
    );
  }
}

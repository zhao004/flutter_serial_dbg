import 'package:package_info_plus/package_info_plus.dart';

import '../../models/app_update.dart';

/// 读取当前安装应用版本的数据边界。
abstract interface class InstalledAppInfoProvider {
  /// 返回当前 Android 安装包信息。
  Future<InstalledAppInfo> load();
}

/// 使用 `package_info_plus` 读取 Android 安装包信息。
final class PackageInfoInstalledAppInfoProvider
    implements InstalledAppInfoProvider {
  const PackageInfoInstalledAppInfoProvider();

  @override
  Future<InstalledAppInfo> load() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      if (version.isEmpty) {
        throw const AppUpdateException(
          AppUpdateFailureKind.unsupportedPlatform,
          '无法读取当前应用版本',
        );
      }
      return InstalledAppInfo(
        version: version,
        buildNumber: packageInfo.buildNumber.trim(),
        packageName: packageInfo.packageName,
      );
    } on AppUpdateException {
      rethrow;
    } catch (_) {
      throw const AppUpdateException(
        AppUpdateFailureKind.unsupportedPlatform,
        '无法读取当前应用版本',
      );
    }
  }
}

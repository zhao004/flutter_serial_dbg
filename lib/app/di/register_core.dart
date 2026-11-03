import 'package:http/http.dart' as http;

import '../database/app_repository.dart';
import '../database/database.dart';
import '../services/ble/ble_permission_service.dart';
import '../services/ble/ble_scanner.dart';
import '../services/diagnostics/network_diagnostics.dart';
import '../services/logging/log_exporter.dart';
import '../services/update/apk_installer.dart';
import '../services/update/app_update_service.dart';
import '../services/update/github_release_client.dart';
import '../services/update/installed_app_info_provider.dart';
import '../services/update/update_platform_service.dart';
import '../services/usb/usb_serial_service.dart';
import 'injector.dart';

/// 注册无业务页依赖的核心服务。
void registerCore() {
  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  }
  if (!getIt.isRegistered<AppRepository>()) {
    getIt.registerLazySingleton<AppRepository>(
      () => DriftAppRepository(database: getIt<AppDatabase>()),
      dispose: (repository) => repository.close(),
    );
  }
  if (!getIt.isRegistered<NetworkDiagnostics>()) {
    getIt.registerLazySingleton<NetworkDiagnostics>(
      PlatformNetworkDiagnostics.new,
    );
  }
  if (!getIt.isRegistered<LogExporter>()) {
    getIt.registerLazySingleton<LogExporter>(FileSelectorLogExporter.new);
  }
  if (!getIt.isRegistered<BlePermissionService>()) {
    getIt.registerLazySingleton<BlePermissionService>(
      AndroidBlePermissionService.new,
    );
  }
  if (!getIt.isRegistered<BleScanner>()) {
    getIt.registerLazySingleton<BleScanner>(
      FlutterBluePlusBleScanner.new,
      dispose: (scanner) => scanner.dispose(),
    );
  }
  if (!getIt.isRegistered<UsbSerialService>()) {
    getIt.registerLazySingleton<UsbSerialService>(
      FlutterUsbSerialService.new,
      dispose: (service) => service.dispose(),
    );
  }
  if (!getIt.isRegistered<GitHubReleaseClient>()) {
    getIt.registerLazySingleton<GitHubReleaseClient>(
      () => HttpGitHubReleaseClient(client: http.Client()),
      dispose: (client) => client.close(),
    );
  }
  if (!getIt.isRegistered<InstalledAppInfoProvider>()) {
    getIt.registerLazySingleton<InstalledAppInfoProvider>(
      PackageInfoInstalledAppInfoProvider.new,
    );
  }
  if (!getIt.isRegistered<UpdatePlatformService>()) {
    getIt.registerLazySingleton<UpdatePlatformService>(
      AndroidUpdatePlatformService.new,
    );
  }
  if (!getIt.isRegistered<ApkInstaller>()) {
    getIt.registerLazySingleton<ApkInstaller>(OtaApkInstaller.new);
  }
  if (!getIt.isRegistered<AppUpdateService>()) {
    getIt.registerLazySingleton<AppUpdateService>(
      () => GitHubAppUpdateService(
        releaseClient: getIt<GitHubReleaseClient>(),
        installedAppInfoProvider: getIt<InstalledAppInfoProvider>(),
        platformService: getIt<UpdatePlatformService>(),
        apkInstaller: getIt<ApkInstaller>(),
      ),
    );
  }
}

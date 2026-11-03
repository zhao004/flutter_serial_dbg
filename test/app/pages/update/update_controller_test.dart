import 'dart:async';

import 'package:flutter_serial_dbg/app/models/app_update.dart';
import 'package:flutter_serial_dbg/app/pages/update/update_controller.dart';
import 'package:flutter_serial_dbg/app/services/update/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('loads installed app information during initialization', () async {
    final service = _FakeAppUpdateService();
    final controller = UpdateController(service);
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state.value.installed?.version, '1.0.0');
    expect(controller.state.value.installed?.buildNumber, '7');
  });

  test('automatic check failures stay silent', () async {
    final service = _FakeAppUpdateService()
      ..checkError = const AppUpdateException(
        AppUpdateFailureKind.network,
        '网络不可用',
      );
    final controller = UpdateController(service);
    addTearDown(controller.dispose);

    final result = await controller.checkForUpdates(
      trigger: UpdateCheckTrigger.automatic,
    );

    expect(result, isNull);
    expect(controller.state.value.status, UpdateStatus.idle);
    expect(controller.state.value.errorMessage, isNull);
    expect(controller.notice.value, isNull);
  });

  test('manual check reports that the app is current', () async {
    final service = _FakeAppUpdateService();
    final controller = UpdateController(service);
    addTearDown(controller.dispose);

    final result = await controller.checkForUpdates(
      trigger: UpdateCheckTrigger.manual,
    );

    expect(result?.hasUpdate, isFalse);
    expect(controller.state.value.status, UpdateStatus.upToDate);
    expect(controller.notice.value?.message, '当前已是最新版本');
  });

  test('startup check only runs once per controller', () async {
    final service = _FakeAppUpdateService();
    final controller = UpdateController(service);
    addTearDown(controller.dispose);

    await controller.checkAtStartup();
    await controller.checkAtStartup();

    expect(service.checkCalls, 1);
  });

  test('deduplicates checks while initialization is pending', () async {
    final service = _FakeAppUpdateService()
      ..installedCompleter = Completer<InstalledAppInfo>();
    final controller = UpdateController(service);
    addTearDown(controller.dispose);

    final first = controller.checkForUpdates(
      trigger: UpdateCheckTrigger.manual,
    );
    final second = controller.checkForUpdates(
      trigger: UpdateCheckTrigger.manual,
    );
    service.installedCompleter!.complete(
      const InstalledAppInfo(
        version: '1.0.0',
        buildNumber: '7',
        packageName: 'com.zhao.serial.dbg',
      ),
    );

    expect(await second, isNull);
    expect(await first, isNotNull);
    expect(service.checkCalls, 1);
  });

  test(
    'opens install permission settings when installation is denied',
    () async {
      final service = _FakeAppUpdateService()
        ..canInstall = false
        ..checkResult = _updateCheckResult();
      final controller = UpdateController(service);
      addTearDown(controller.dispose);
      await controller.checkForUpdates(trigger: UpdateCheckTrigger.manual);

      await controller.downloadAndInstall();

      expect(service.settingsCalls, 1);
      expect(service.installCalls, 0);
      expect(controller.state.value.status, UpdateStatus.available);
      expect(controller.state.value.errorMessage, contains('允许'));
    },
  );

  test('deduplicates install requests during permission checks', () async {
    final service = _FakeAppUpdateService()
      ..checkResult = _updateCheckResult()
      ..installPermissionCompleter = Completer<bool>();
    final controller = UpdateController(service);
    addTearDown(controller.dispose);
    await controller.checkForUpdates(trigger: UpdateCheckTrigger.manual);

    final first = controller.downloadAndInstall();
    final second = controller.downloadAndInstall();
    service.installPermissionCompleter!.complete(true);
    await Future<void>.delayed(Duration.zero);
    service.installEvents.add(const ApkInstallEvent.installing());
    await Future.wait<void>(<Future<void>>[first, second]);

    expect(service.installCalls, 1);
  });

  test(
    'publishes download progress and waits for system installation',
    () async {
      final service = _FakeAppUpdateService()
        ..checkResult = _updateCheckResult();
      final controller = UpdateController(service);
      addTearDown(controller.dispose);
      await controller.checkForUpdates(trigger: UpdateCheckTrigger.manual);

      final operation = controller.downloadAndInstall();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.value.status, UpdateStatus.downloading);

      service.installEvents.add(const ApkInstallEvent.downloading(0.45));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.value.progress, 0.45);

      service.installEvents.add(const ApkInstallEvent.installing());
      await operation;
      expect(controller.state.value.status, UpdateStatus.awaitingInstall);
    },
  );
}

UpdateCheckResult _updateCheckResult() {
  const installed = InstalledAppInfo(
    version: '1.0.0',
    buildNumber: '7',
    packageName: 'com.zhao.serial.dbg',
  );
  return UpdateCheckResult(
    installed: installed,
    update: AvailableUpdate(
      version: Version.parse('1.1.0'),
      tagName: 'v1.1.0',
      releaseNotes: '更新说明',
      asset: UpdateAsset(
        abi: 'arm64-v8a',
        fileName: 'serialdbg-v1.1.0-arm64-v8a.apk',
        downloadUri: Uri.parse(
          'https://github.com/zhao004/flutter_serial_dbg/releases/download/v1.1.0/serialdbg-v1.1.0-arm64-v8a.apk',
        ),
        sizeBytes: 1024,
        sha256: 'a' * 64,
      ),
    ),
  );
}

final class _FakeAppUpdateService implements AppUpdateService {
  UpdateCheckResult? checkResult;
  AppUpdateException? checkError;
  bool canInstall = true;
  Completer<InstalledAppInfo>? installedCompleter;
  Completer<bool>? installPermissionCompleter;
  int checkCalls = 0;
  int settingsCalls = 0;
  int installCalls = 0;
  final StreamController<ApkInstallEvent> installEvents =
      StreamController<ApkInstallEvent>();

  @override
  Future<InstalledAppInfo> installedInfo() async {
    final completer = installedCompleter;
    if (completer != null) {
      return completer.future;
    }
    return const InstalledAppInfo(
      version: '1.0.0',
      buildNumber: '7',
      packageName: 'com.zhao.serial.dbg',
    );
  }

  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    checkCalls += 1;
    final error = checkError;
    if (error != null) {
      throw error;
    }
    return checkResult ??
        const UpdateCheckResult(
          installed: InstalledAppInfo(
            version: '1.0.0',
            buildNumber: '7',
            packageName: 'com.zhao.serial.dbg',
          ),
        );
  }

  @override
  Stream<ApkInstallEvent> install(AvailableUpdate update) {
    installCalls += 1;
    return installEvents.stream;
  }

  @override
  Future<void> cancelDownload() async {}

  @override
  Future<bool> canRequestPackageInstalls() async {
    final completer = installPermissionCompleter;
    if (completer != null) {
      return completer.future;
    }
    return canInstall;
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    settingsCalls += 1;
    return true;
  }
}

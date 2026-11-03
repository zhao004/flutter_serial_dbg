import 'package:flutter_serial_dbg/app/models/app_update.dart';
import 'package:flutter_serial_dbg/app/services/update/apk_installer.dart';
import 'package:flutter_serial_dbg/app/services/update/app_update_service.dart';
import 'package:flutter_serial_dbg/app/services/update/github_release_client.dart';
import 'package:flutter_serial_dbg/app/services/update/installed_app_info_provider.dart';
import 'package:flutter_serial_dbg/app/services/update/update_platform_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selects the first matching device ABI asset', () async {
    final digest = 'a' * 64;
    final service = _service(
      release: _release(
        tagName: 'v1.1.0',
        assets: <GitHubReleaseAsset>[
          _asset('armeabi-v7a', digest),
          _asset('arm64-v8a', digest),
        ],
      ),
      abis: const <String>['x86_64', 'arm64-v8a', 'armeabi-v7a'],
    );

    final result = await service.checkForUpdate();

    expect(result.hasUpdate, isTrue);
    expect(result.update?.tagName, 'v1.1.0');
    expect(result.update?.asset.abi, 'arm64-v8a');
    expect(result.update?.asset.sha256, digest);
  });

  test(
    'does not request ABI data when the installed version is current',
    () async {
      final platform = _FakePlatformService();
      final service = _service(
        release: _release(tagName: 'v1.0.0'),
        platform: platform,
      );

      final result = await service.checkForUpdate();

      expect(result.hasUpdate, isFalse);
      expect(platform.abiCalls, 0);
    },
  );

  test('rejects prerelease tags even if GitHub flags them as stable', () async {
    final service = _service(release: _release(tagName: 'v1.1.0-beta.1'));

    await expectLater(
      service.checkForUpdate(),
      throwsA(
        isA<AppUpdateException>().having(
          (error) => error.kind,
          'kind',
          AppUpdateFailureKind.invalidRelease,
        ),
      ),
    );
  });

  test('refuses an APK without a SHA-256 digest', () async {
    final service = _service(
      release: _release(
        tagName: 'v1.1.0',
        assets: <GitHubReleaseAsset>[_asset('arm64-v8a', null)],
      ),
    );

    await expectLater(
      service.checkForUpdate(),
      throwsA(
        isA<AppUpdateException>().having(
          (error) => error.kind,
          'kind',
          AppUpdateFailureKind.checksumUnavailable,
        ),
      ),
    );
  });

  test('reports a missing compatible APK', () async {
    final service = _service(
      release: _release(
        tagName: 'v1.1.0',
        assets: <GitHubReleaseAsset>[_asset('x86_64', 'a' * 64)],
      ),
      abis: const <String>['arm64-v8a'],
    );

    await expectLater(
      service.checkForUpdate(),
      throwsA(
        isA<AppUpdateException>().having(
          (error) => error.kind,
          'kind',
          AppUpdateFailureKind.incompatibleDevice,
        ),
      ),
    );
  });
}

GitHubAppUpdateService _service({
  required GitHubRelease release,
  List<String> abis = const <String>['arm64-v8a'],
  _FakePlatformService? platform,
}) {
  return GitHubAppUpdateService(
    releaseClient: _FakeReleaseClient(release),
    installedAppInfoProvider: const _FakeInstalledAppInfoProvider(),
    platformService: platform ?? _FakePlatformService(abis: abis),
    apkInstaller: _FakeApkInstaller(),
  );
}

GitHubRelease _release({
  required String tagName,
  List<GitHubReleaseAsset> assets = const <GitHubReleaseAsset>[],
}) {
  return GitHubRelease(
    tagName: tagName,
    body: '更新说明',
    draft: false,
    prerelease: false,
    assets: assets,
  );
}

GitHubReleaseAsset _asset(String abi, String? digest) {
  final fileName = 'serialdbg-v1.1.0-$abi.apk';
  return GitHubReleaseAsset(
    name: fileName,
    size: 1024,
    digest: digest == null ? null : 'sha256:$digest',
    downloadUrl:
        'https://github.com/zhao004/flutter_serial_dbg/releases/download/v1.1.0/$fileName',
    contentType: 'application/vnd.android.package-archive',
  );
}

final class _FakeReleaseClient implements GitHubReleaseClient {
  _FakeReleaseClient(this.release);

  final GitHubRelease release;

  @override
  Future<GitHubRelease> fetchLatestStableRelease({
    required String userAgent,
  }) async {
    return release;
  }

  @override
  void close() {}
}

final class _FakeInstalledAppInfoProvider implements InstalledAppInfoProvider {
  const _FakeInstalledAppInfoProvider();

  @override
  Future<InstalledAppInfo> load() async {
    return const InstalledAppInfo(
      version: '1.0.0',
      buildNumber: '1',
      packageName: 'com.zhao.serial.dbg',
    );
  }
}

final class _FakePlatformService implements UpdatePlatformService {
  _FakePlatformService({this.abis = const <String>['arm64-v8a']});

  final List<String> abis;
  int abiCalls = 0;

  @override
  Future<List<String>> supportedAbis() async {
    abiCalls += 1;
    return abis;
  }

  @override
  Future<bool> canRequestPackageInstalls() async => true;

  @override
  Future<bool> openInstallPermissionSettings() async => true;
}

final class _FakeApkInstaller implements ApkInstaller {
  @override
  Stream<ApkInstallEvent> install(AvailableUpdate update) {
    return const Stream<ApkInstallEvent>.empty();
  }

  @override
  Future<void> cancel() async {}
}

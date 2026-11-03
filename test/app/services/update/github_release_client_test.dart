import 'dart:convert';

import 'package:flutter_serial_dbg/app/models/app_update.dart';
import 'package:flutter_serial_dbg/app/services/update/github_release_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('requests and parses the latest stable GitHub release', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode(<String, Object?>{
            'tag_name': 'v1.1.0',
            'body': '修复连接问题',
            'draft': false,
            'prerelease': false,
            'published_at': '2026-11-03T09:32:37Z',
            'assets': <Map<String, Object?>>[
              <String, Object?>{
                'name': 'serialdbg-v1.1.0-arm64-v8a.apk',
                'size': 1024,
                'digest': 'sha256:${'a' * 64}',
                'browser_download_url': 'https://github.com/zhao004/flutter_serial_dbg/releases/download/v1.1.0/serialdbg-v1.1.0-arm64-v8a.apk',
                'content_type': 'application/vnd.android.package-archive',
              },
            ],
          }),
        ),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });
    final releaseClient = HttpGitHubReleaseClient(client: client);
    addTearDown(releaseClient.close);

    final release = await releaseClient.fetchLatestStableRelease(
      userAgent: 'SerialDbg/1.0.0',
    );

    expect(capturedRequest.headers['Accept'], 'application/vnd.github+json');
    expect(capturedRequest.headers['X-GitHub-Api-Version'], '2022-11-28');
    expect(capturedRequest.headers['User-Agent'], 'SerialDbg/1.0.0');
    expect(release.tagName, 'v1.1.0');
    expect(release.body, '修复连接问题');
    expect(release.assets.single.name, 'serialdbg-v1.1.0-arm64-v8a.apk');
    expect(release.publishedAt, DateTime.utc(2026, 11, 3, 9, 32, 37));
  });

  test('reports an exhausted GitHub API quota', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{}',
        403,
        headers: <String, String>{'x-ratelimit-remaining': '0'},
      ),
    );
    final releaseClient = HttpGitHubReleaseClient(client: client);
    addTearDown(releaseClient.close);

    await expectLater(
      releaseClient.fetchLatestStableRelease(userAgent: 'SerialDbg/1.0.0'),
      throwsA(
        isA<AppUpdateException>().having(
          (error) => error.kind,
          'kind',
          AppUpdateFailureKind.rateLimited,
        ),
      ),
    );
  });

  test('rejects malformed release payloads', () async {
    final client = MockClient(
      (_) async => http.Response('{"tag_name": 12}', 200),
    );
    final releaseClient = HttpGitHubReleaseClient(client: client);
    addTearDown(releaseClient.close);

    await expectLater(
      releaseClient.fetchLatestStableRelease(userAgent: 'SerialDbg/1.0.0'),
      throwsA(
        isA<AppUpdateException>().having(
          (error) => error.kind,
          'kind',
          AppUpdateFailureKind.invalidRelease,
        ),
      ),
    );
  });
}

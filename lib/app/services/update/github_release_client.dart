import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/app_update.dart';

/// GitHub Release 中的单个资产。
final class GitHubReleaseAsset {
  const GitHubReleaseAsset({
    required this.name,
    required this.size,
    required this.digest,
    required this.downloadUrl,
    required this.contentType,
  });

  /// 资产文件名。
  final String name;

  /// 资产字节数。
  final int size;

  /// GitHub 提供的摘要，例如 `sha256:...`。
  final String? digest;

  /// 浏览器下载地址。
  final String downloadUrl;

  /// 资产 MIME 类型。
  final String contentType;
}

/// GitHub 最新稳定 Release 的原始数据。
final class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.body,
    required this.draft,
    required this.prerelease,
    required this.assets,
    this.publishedAt,
  });

  /// Git 标签名。
  final String tagName;

  /// Release 正文。
  final String body;

  /// 是否为草稿。
  final bool draft;

  /// 是否为预发布。
  final bool prerelease;

  /// Release 资产。
  final List<GitHubReleaseAsset> assets;

  /// 发布时间。
  final DateTime? publishedAt;
}

/// 获取最新稳定 Release 的数据边界。
abstract interface class GitHubReleaseClient {
  /// 请求固定仓库的最新稳定 Release。
  Future<GitHubRelease> fetchLatestStableRelease({required String userAgent});

  /// 释放 HTTP 连接资源。
  void close();
}

/// 基于 GitHub REST API 的 Release 客户端。
final class HttpGitHubReleaseClient implements GitHubReleaseClient {
  factory HttpGitHubReleaseClient({
    required http.Client client,
    Uri? endpoint,
    Duration timeout = const Duration(seconds: 12),
  }) {
    return HttpGitHubReleaseClient._(
      client,
      endpoint ??
          Uri.parse(
            'https://api.github.com/repos/zhao004/flutter_serial_dbg/releases/latest',
          ),
      timeout,
    );
  }

  HttpGitHubReleaseClient._(this._client, this._endpoint, this.timeout);

  final http.Client _client;
  final Uri _endpoint;

  /// 单次请求的完整超时时间。
  final Duration timeout;

  @override
  Future<GitHubRelease> fetchLatestStableRelease({
    required String userAgent,
  }) async {
    try {
      final response = await _client
          .get(
            _endpoint,
            headers: <String, String>{
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': userAgent,
            },
          )
          .timeout(timeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw const AppUpdateException(
        AppUpdateFailureKind.network,
        '连接 GitHub 超时，请稍后重试',
      );
    } on SocketException {
      throw const AppUpdateException(
        AppUpdateFailureKind.network,
        '无法连接 GitHub，请检查网络',
      );
    } on http.ClientException {
      throw const AppUpdateException(
        AppUpdateFailureKind.network,
        '更新请求失败，请稍后重试',
      );
    }
  }

  GitHubRelease _parseResponse(http.Response response) {
    if (response.statusCode == HttpStatus.forbidden &&
        response.headers['x-ratelimit-remaining'] == '0') {
      throw const AppUpdateException(
        AppUpdateFailureKind.rateLimited,
        'GitHub 更新检查次数已用尽，请稍后重试',
      );
    }
    if (response.statusCode == HttpStatus.notFound) {
      throw const AppUpdateException(AppUpdateFailureKind.noRelease, '暂无可用版本');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AppUpdateException(
        AppUpdateFailureKind.network,
        '读取 GitHub 版本信息失败，请稍后重试',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Release payload must be an object');
      }
      final tagName = decoded['tag_name'];
      final body = decoded['body'];
      final draft = decoded['draft'];
      final prerelease = decoded['prerelease'];
      final rawAssets = decoded['assets'];
      if (tagName is! String ||
          body is! String ||
          draft is! bool ||
          prerelease is! bool ||
          rawAssets is! List<dynamic>) {
        throw const FormatException('Release payload is incomplete');
      }

      final assets = <GitHubReleaseAsset>[];
      for (final rawAsset in rawAssets) {
        if (rawAsset is! Map<String, dynamic>) {
          throw const FormatException('Invalid release asset');
        }
        final name = rawAsset['name'];
        final size = rawAsset['size'];
        final digest = rawAsset['digest'];
        final downloadUrl = rawAsset['browser_download_url'];
        final contentType = rawAsset['content_type'];
        if (name is! String ||
            size is! int ||
            (digest != null && digest is! String) ||
            downloadUrl is! String ||
            contentType is! String) {
          throw const FormatException('Invalid release asset fields');
        }
        assets.add(
          GitHubReleaseAsset(
            name: name,
            size: size,
            digest: digest as String?,
            downloadUrl: downloadUrl,
            contentType: contentType,
          ),
        );
      }

      final publishedAtValue = decoded['published_at'];
      return GitHubRelease(
        tagName: tagName,
        body: body,
        draft: draft,
        prerelease: prerelease,
        assets: List<GitHubReleaseAsset>.unmodifiable(assets),
        publishedAt: publishedAtValue is String
            ? DateTime.tryParse(publishedAtValue)
            : null,
      );
    } on FormatException {
      throw const AppUpdateException(
        AppUpdateFailureKind.invalidRelease,
        'GitHub 返回了无法识别的版本信息',
      );
    }
  }

  @override
  void close() {
    _client.close();
  }
}

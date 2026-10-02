import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

sealed class UpdateResult {}

class UpdateResultUpToDate extends UpdateResult {
  UpdateResultUpToDate({required this.currentVersion});
  final String currentVersion;
}

class UpdateResultAvailable extends UpdateResult {
  UpdateResultAvailable({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkAssetUrl,
    required this.releasePageUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String? apkAssetUrl; // null if no APK asset found in the release
  final String releasePageUrl;
}

class UpdateResultError extends UpdateResult {
  UpdateResultError({required this.message});
  final String message;
}

// ─── GitHub release model ─────────────────────────────────────────────────────

class GitHubRelease {
  GitHubRelease({
    required this.tagName,
    required this.version,
    required this.releaseNotes,
    required this.apkAssetUrl,
    required this.htmlUrl,
  });

  final String tagName;
  final String version; // tagName without leading 'v'
  final String releaseNotes;
  final String? apkAssetUrl;
  final String htmlUrl;

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final rawTag = (json['tag_name'] as String? ?? '').trim();
    final version = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
    final releaseNotes = (json['body'] as String? ?? '').trim();
    final htmlUrl = (json['html_url'] as String? ?? '').trim();

    // APK asset selection:
    // 1. First asset whose name exactly matches AppConfig.apkAssetName.
    // 2. Fallback: first asset whose name ends with '.apk'.
    // 3. Fallback: null (no APK attached).
    String? apkAssetUrl;
    final assets = json['assets'];
    if (assets is List) {
      Map<String, dynamic>? exactMatch;
      Map<String, dynamic>? fallbackMatch;
      for (final raw in assets) {
        if (raw is! Map<String, dynamic>) continue;
        final name = (raw['name'] as String? ?? '');
        if (name == AppConfig.apkAssetName) {
          exactMatch = raw;
          break;
        }
        if (fallbackMatch == null && name.endsWith('.apk')) {
          fallbackMatch = raw;
        }
      }
      final chosen = exactMatch ?? fallbackMatch;
      if (chosen != null) {
        apkAssetUrl = chosen['browser_download_url'] as String?;
      }
    }

    return GitHubRelease(
      tagName: rawTag,
      version: version,
      releaseNotes: releaseNotes,
      apkAssetUrl: apkAssetUrl,
      htmlUrl: htmlUrl,
    );
  }
}

// ─── Semver comparison ────────────────────────────────────────────────────────

/// Returns `true` if [remote] is strictly newer than [local].
/// Compares numeric parts only; strips non-digit chars from each segment.
bool _isNewer(String local, String remote) {
  List<int> parse(String v) => v
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();

  final l = parse(local);
  final r = parse(remote);
  final len = l.length > r.length ? l.length : r.length;
  for (var i = 0; i < len; i++) {
    final lv = i < l.length ? l[i] : 0;
    final rv = i < r.length ? r[i] : 0;
    if (rv > lv) return true;
    if (rv < lv) return false;
  }
  return false;
}

// ─── UpdateService ────────────────────────────────────────────────────────────

class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  // ── Check for updates ─────────────────────────────────────────────────────

  Future<UpdateResult> checkForUpdates() async {
    // 1. Read installed version.
    PackageInfo info;
    try {
      info = await PackageInfo.fromPlatform();
    } catch (_) {
      return UpdateResultError(message: 'Could not read the installed app version.');
    }
    final localVersion = info.version;

    // 2. Fetch latest GitHub release.
    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse(AppConfig.githubReleasesApiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      return UpdateResultError(
        message:
            'Could not connect to GitHub. Check your internet connection.',
      );
    } on TimeoutException {
      return UpdateResultError(
        message: 'Request timed out. Please try again.',
      );
    } catch (_) {
      return UpdateResultError(
        message:
            'Could not reach GitHub. Check your internet connection.',
      );
    }

    // 3. Handle error status codes.
    if (response.statusCode == 403 || response.statusCode == 429) {
      return UpdateResultError(
        message: 'GitHub rate limit reached. Please try again later.',
      );
    }
    if (response.statusCode == 404) {
      return UpdateResultError(
        message: 'No releases published yet. Check back soon!',
      );
    }
    if (response.statusCode != 200) {
      return UpdateResultError(
        message:
            'Unexpected server response (HTTP ${response.statusCode}). Try again.',
      );
    }

    // 4. Parse JSON.
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return UpdateResultError(
        message: 'Could not parse the release data. Try again.',
      );
    }

    // 5. Build model.
    final release = GitHubRelease.fromJson(json);
    if (release.version.isEmpty) {
      return UpdateResultError(message: 'Release has no version tag.');
    }

    // 6. Compare versions.
    if (_isNewer(localVersion, release.version)) {
      return UpdateResultAvailable(
        currentVersion: localVersion,
        latestVersion: release.version,
        releaseNotes: release.releaseNotes.isEmpty
            ? 'No release notes provided.'
            : release.releaseNotes,
        apkAssetUrl: release.apkAssetUrl,
        releasePageUrl: release.htmlUrl,
      );
    }
    return UpdateResultUpToDate(currentVersion: localVersion);
  }

  // ── Download APK ──────────────────────────────────────────────────────────

  /// Downloads the APK from [apkUrl] to local storage.
  ///
  /// [onProgress] receives a value in `[0.0, 1.0]` while the download
  /// progresses, or `-1.0` if the content length is unknown.
  ///
  /// [isCancelled] is polled between chunk writes. If it returns `true`,
  /// the download is aborted and an [Exception] is thrown.
  ///
  /// Prefers [getExternalStorageDirectory] for the save location — files
  /// there are accessible to the Android package installer without a
  /// FileProvider. Falls back to [getApplicationDocumentsDirectory].
  ///
  /// Returns the saved [File] on success.
  Future<File> downloadApk(
    String apkUrl, {
    required void Function(double progress) onProgress,
    bool Function()? isCancelled,
  }) async {
    // Determine save directory.
    Directory? dir;
    try {
      dir = await getExternalStorageDirectory();
    } catch (_) {
      // ignore — fallback below
    }
    dir ??= await getApplicationDocumentsDirectory();

    final dest = File(path.join(dir.path, 'dimi_update.apk'));

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(apkUrl));
      final response = await client.send(request);

      final total = response.contentLength ?? -1;
      var received = 0;

      final sink = dest.openWrite();
      try {
        await for (final chunk in response.stream) {
          if (isCancelled != null && isCancelled()) {
            throw Exception('Download cancelled.');
          }
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress(received / total);
          } else {
            onProgress(-1.0);
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    } finally {
      client.close();
    }

    return dest;
  }
}

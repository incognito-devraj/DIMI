import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
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

    // Only offer in-app installation when the expected production APK is
    // attached to the release. The download itself uses the stable latest URL.
    String? apkAssetUrl;
    final assets = json['assets'];
    if (assets is List) {
      for (final raw in assets) {
        if (raw is! Map<String, dynamic>) continue;
        final name = (raw['name'] as String? ?? '');
        if (name == AppConfig.apkAssetName) {
          apkAssetUrl = raw['browser_download_url'] as String?;
          break;
        }
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

/// A SemVer 2.0.0 value used for release comparison.
class SemanticVersion implements Comparable<SemanticVersion> {
  SemanticVersion._(this.core, this.prerelease);

  final List<int> core;
  final List<String> prerelease;

  static SemanticVersion? tryParse(String raw) {
    final value = raw.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final match = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
      r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
      r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
    ).firstMatch(value);
    if (match == null) return null;

    final prereleaseValue = match.group(4);
    return SemanticVersion._([
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ], prereleaseValue == null ? const [] : prereleaseValue.split('.'));
  }

  @override
  int compareTo(SemanticVersion other) {
    for (var i = 0; i < core.length; i++) {
      final result = core[i].compareTo(other.core[i]);
      if (result != 0) return result;
    }
    if (prerelease.isEmpty && other.prerelease.isNotEmpty) return 1;
    if (prerelease.isNotEmpty && other.prerelease.isEmpty) return -1;
    for (var i = 0; i < prerelease.length && i < other.prerelease.length; i++) {
      final left = prerelease[i];
      final right = other.prerelease[i];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        final result = leftNumber.compareTo(rightNumber);
        if (result != 0) return result;
      } else if (leftNumber != null) {
        return -1;
      } else if (rightNumber != null) {
        return 1;
      } else {
        final result = left.compareTo(right);
        if (result != 0) return result;
      }
    }
    return prerelease.length.compareTo(other.prerelease.length);
  }
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
      return UpdateResultError(
        message: 'Could not read the installed app version.',
      );
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
        message: 'Could not connect to GitHub. Check your internet connection.',
      );
    } on TimeoutException {
      return UpdateResultError(message: 'Request timed out. Please try again.');
    } catch (_) {
      return UpdateResultError(
        message: 'Could not reach GitHub. Check your internet connection.',
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
    final localSemVer = SemanticVersion.tryParse(localVersion);
    final latestSemVer = SemanticVersion.tryParse(release.version);
    if (localSemVer == null || latestSemVer == null) {
      return UpdateResultError(
        message: 'The installed or released version is invalid.',
      );
    }
    if (release.version.isEmpty || release.htmlUrl.isEmpty) {
      return UpdateResultError(message: 'Release information is incomplete.');
    }

    // 6. Compare versions.
    if (latestSemVer.compareTo(localSemVer) > 0) {
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
  Future<File> downloadApk({
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

    final updateDir = Directory(path.join(dir.path, 'updates'));
    await updateDir.create(recursive: true);
    final dest = File(path.join(updateDir.path, 'dimi_update.apk'));

    final client = http.Client();
    try {
      final request = http.Request(
        'GET',
        Uri.parse(AppConfig.githubLatestApkUrl),
      );
      final response = await client.send(request);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Update download failed (HTTP ${response.statusCode}).',
        );
      }

      final total = response.contentLength ?? -1;
      var received = 0;

      final sink = dest.openWrite();
      try {
        await for (final chunk in response.stream) {
          if (isCancelled != null && isCancelled()) {
            throw const UpdateDownloadCancelledException();
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
    } catch (_) {
      if (await dest.exists()) {
        await dest.delete();
      }
      rethrow;
    } finally {
      client.close();
    }

    return dest;
  }

  Future<void> installApk(File apk) async {
    try {
      await const MethodChannel('com.dimi.dimi_app/update_installer')
          .invokeMethod<void>('installApk', {'path': apk.path});
    } on PlatformException catch (error) {
      throw Exception(
        error.message ?? 'Could not open the Android package installer.',
      );
    }
  }
}

class UpdateDownloadCancelledException implements Exception {
  const UpdateDownloadCancelledException();
}

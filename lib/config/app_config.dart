/// Single source of truth for all external URLs, repository identifiers,
/// asset filenames, and contact information used by DIMI.
///
/// Import this wherever you need a GitHub URL, support email, or APK name.
/// Never duplicate these constants inline in other files.
abstract final class AppConfig {
  static const String githubOwner = 'incognito-devraj';
  static const String githubRepo = 'DIMI';
  static const String githubReleasesApiUrl =
      'https://api.github.com/repos/incognito-devraj/DIMI/releases/latest';
  static const String githubLatestApkUrl =
      'https://github.com/incognito-devraj/DIMI/releases/latest/download/DIMI.apk';
  static const String githubRepoUrl =
      'https://github.com/incognito-devraj/DIMI';
  static const String githubIssuesUrl =
      'https://github.com/incognito-devraj/DIMI/issues';
  static const String githubDiscussionsUrl =
      'https://github.com/incognito-devraj/DIMI/discussions';
  static const String supportEmail = 'devrajmukherjee.om@gmail.com';

  /// Expected filename of the Android release APK attached to a GitHub Release.
  static const String apkAssetName = 'DIMI.apk';
}

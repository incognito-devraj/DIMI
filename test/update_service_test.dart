import 'package:flutter_test/flutter_test.dart';

import 'package:dimi_app/services/update_service.dart';

void main() {
  group('SemanticVersion', () {
    test('compares release versions by major, minor, and patch', () {
      final current = SemanticVersion.tryParse('1.0.2')!;
      final next = SemanticVersion.tryParse('1.0.3')!;

      expect(next.compareTo(current), greaterThan(0));
      expect(current.compareTo(next), lessThan(0));
    });

    test('release versions outrank prereleases', () {
      final beta = SemanticVersion.tryParse('1.0.2-beta.1')!;
      final release = SemanticVersion.tryParse('1.0.2')!;

      expect(release.compareTo(beta), greaterThan(0));
    });

    test('accepts a leading v and rejects malformed versions', () {
      expect(SemanticVersion.tryParse('v1.0.2'), isNotNull);
      expect(SemanticVersion.tryParse('1.0'), isNull);
    });
  });

  test('release model selects the exact DIMI APK asset', () {
    final release = GitHubRelease.fromJson({
      'tag_name': 'v1.0.2',
      'html_url': 'https://github.com/incognito-devraj/DIMI/releases/tag/v1.0.2',
      'body': 'Release notes',
      'assets': [
        {
          'name': 'DIMI.apk',
          'browser_download_url':
              'https://github.com/incognito-devraj/DIMI/releases/download/v1.0.2/DIMI.apk',
        },
        {
          'name': 'DIMI.apk.sha256',
          'browser_download_url':
              'https://github.com/incognito-devraj/DIMI/releases/download/v1.0.2/DIMI.apk.sha256',
        },
      ],
    });

    expect(release.version, '1.0.2');
    expect(release.apkAssetUrl, endsWith('/v1.0.2/DIMI.apk'));
  });
}

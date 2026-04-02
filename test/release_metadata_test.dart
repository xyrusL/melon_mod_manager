import 'package:flutter_test/flutter_test.dart';

import '../tool/release_metadata.dart';

void main() {
  group('release metadata', () {
    test('parses semver stable version and matching tag', () {
      final metadata = resolveReleaseMetadata(
        pubspecContent: 'name: melon_mod\nversion: 1.7.2+1\n',
        tagName: 'v1.7.2',
      );

      expect(metadata.appVersion, '1.7.2');
      expect(metadata.tagName, 'v1.7.2');
      expect(metadata.releaseChannel, 'Stable');
      expect(metadata.isPrerelease, isFalse);
      expect(metadata.releaseTitle, 'Melon Mod Manager 1.7.2');
    });

    test('parses stable date release as stable', () {
      final metadata = resolveReleaseMetadata(
        pubspecContent: 'version: 1.7.0-2026.03.30+1\n',
        tagName: 'v1.7.0-2026.03.30',
      );

      expect(metadata.releaseChannel, 'Stable');
      expect(metadata.isPrerelease, isFalse);
    });

    test('marks beta versions as prerelease and appends beta title', () {
      final metadata = resolveReleaseMetadata(
        pubspecContent: 'version: 1.8.0-beta.2+4\n',
        tagName: 'v1.8.0-beta.2',
      );

      expect(metadata.releaseChannel, 'Beta');
      expect(metadata.isPrerelease, isTrue);
      expect(metadata.releaseTitle, 'Melon Mod Manager 1.8.0-beta.2 (Beta)');
    });

    test('rejects tag mismatch for 1.7.2', () {
      expect(
        () => resolveReleaseMetadata(
          pubspecContent: 'version: 1.7.2+1\n',
          tagName: 'v1.7.0',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

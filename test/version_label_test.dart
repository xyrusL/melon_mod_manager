import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/providers.dart';

void main() {
  group('formatAppVersionLabel', () {
    test('keeps semver stable releases plain', () {
      expect(formatAppVersionLabel('1.7.4'), 'v1.7.4');
    });

    test('keeps dated stable releases plain', () {
      expect(
        formatAppVersionLabel('1.7.0-2026.03.30'),
        'v1.7.0-2026.03.30',
      );
    });

    test('marks beta releases clearly', () {
      expect(formatAppVersionLabel('1.8.0-beta.2'), 'v1.8.0-beta.2 (Beta)');
    });

    test('marks other hyphenated versions as pre-release', () {
      expect(formatAppVersionLabel('1.8.0-rc.1'), 'v1.8.0-rc.1 (Pre-release)');
    });
  });
}

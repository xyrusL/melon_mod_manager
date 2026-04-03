import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/safe_file_name.dart';

void main() {
  group('SafeFileName', () {
    test('accepts a normal mod archive name', () {
      expect(
        SafeFileName.validate(
          'sodium-fabric.jar',
          allowedExtensions: const ['.jar'],
        ),
        'sodium-fabric.jar',
      );
    });

    test('rejects traversal sequences', () {
      expect(
        () => SafeFileName.validate(
          '../startup.bat',
          allowedExtensions: const ['.bat'],
        ),
        throwsFormatException,
      );
      expect(
        () => SafeFileName.validate(
          r'..\startup.bat',
          allowedExtensions: const ['.bat'],
        ),
        throwsFormatException,
      );
    });

    test('rejects unexpected extensions', () {
      expect(
        () => SafeFileName.validate(
          'payload.exe',
          allowedExtensions: const ['.jar'],
        ),
        throwsFormatException,
      );
    });
  });
}

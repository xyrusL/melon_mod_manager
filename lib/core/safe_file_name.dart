import 'package:path/path.dart' as p;

class SafeFileName {
  static String validate(
    String raw, {
    List<String>? allowedExtensions,
  }) {
    final candidate = raw.trim();
    if (candidate.isEmpty) {
      throw const FormatException('File name is empty.');
    }
    if (candidate.contains('/') || candidate.contains(r'\')) {
      throw FormatException('Unsafe file name "$raw".');
    }
    if (candidate.contains(':')) {
      throw FormatException('Unsafe file name "$raw".');
    }

    final normalized = p.normalize(candidate);
    if (normalized == '.' ||
        normalized == '..' ||
        p.basename(normalized) != normalized) {
      throw FormatException('Unsafe file name "$raw".');
    }

    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final normalizedExtensions = allowedExtensions
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet();
      final actualExtension = p.extension(normalized).toLowerCase();
      if (!normalizedExtensions.contains(actualExtension)) {
        throw FormatException(
          'Unexpected file type for "$raw". Expected ${normalizedExtensions.join(', ')}.',
        );
      }
    }

    return normalized;
  }

  static String resolveChildPath({
    required String directoryPath,
    required String fileName,
    List<String>? allowedExtensions,
  }) {
    final safeName = validate(
      fileName,
      allowedExtensions: allowedExtensions,
    );
    return p.join(directoryPath, safeName);
  }
}

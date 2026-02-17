import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/entities/content_type.dart';

class ScannedContentFile {
  const ScannedContentFile({
    required this.fileName,
    required this.filePath,
    required this.lastModified,
  });

  final String fileName;
  final String filePath;
  final DateTime lastModified;
}

class ContentScannerService {
  Future<List<ScannedContentFile>> scanFolder(
    String folderPath, {
    required ContentType contentType,
  }) async {
    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      return const [];
    }

    final allowedExtensions = _extensionsFor(contentType);
    final found = <ScannedContentFile>[];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final ext = p.extension(entity.path).toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        continue;
      }
      final stat = await entity.stat();
      found.add(
        ScannedContentFile(
          fileName: p.basename(entity.path),
          filePath: entity.path,
          lastModified: stat.modified,
        ),
      );
    }

    found.sort(
        (a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    return found;
  }

  Set<String> _extensionsFor(ContentType type) {
    return switch (type) {
      ContentType.mod => const {'.jar'},
      ContentType.resourcePack => const {'.zip'},
      ContentType.shaderPack => const {'.zip'},
    };
  }
}

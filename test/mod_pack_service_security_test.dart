import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/services/mod_pack_service.dart';
import 'package:melon_mod/domain/entities/content_type.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ModPackService security', () {
    test('rejects content bundle entries with unsafe file names', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'melon_mod_bundle_security_',
      );
      final contentDir = Directory(p.join(tempDir.path, 'resourcepacks'));
      await contentDir.create(recursive: true);
      final outsideFile = File(p.join(tempDir.path, 'evil.zip'));
      final bundlePath = p.join(tempDir.path, 'bundle.zip');

      final service = ModPackService();
      final embeddedArchive = Archive()
        ..addFile(ArchiveFile('pack.mcmeta', 2, utf8.encode('{}')));
      final embeddedBytes = ZipEncoder().encode(embeddedArchive);

      final bundleArchive = Archive()
        ..addFile(
          ArchiveFile(
            'melon_content_bundle.json',
            0,
            utf8.encode(jsonEncode({
              'type': 'melon_content_bundle',
              'schema_version': 1,
              'content_type': 'resourcePack',
              'entries': [
                {
                  'file_name': '../evil.zip',
                  'source': 'embedded',
                  'archive_path': 'files/../evil.zip',
                },
              ],
            })),
          ),
        )
        ..addFile(
          ArchiveFile('files/../evil.zip', embeddedBytes.length, embeddedBytes),
        );
      await File(bundlePath).writeAsBytes(ZipEncoder().encode(bundleArchive));

      final result = await service.importContentBundleFromZip(
        contentPath: contentDir.path,
        zipPath: bundlePath,
        contentType: ContentType.resourcePack,
      );

      expect(result, isNotNull);
      expect(result!.failed, 1);
      expect(result.touchedFileNames, isEmpty);
      expect(await outsideFile.exists(), isFalse);
    });
  });
}

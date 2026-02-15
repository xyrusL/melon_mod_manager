import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/services/jar_metadata_parser.dart';

void main() {
  test('parses fabric.mod.json and icon from jar bytes', () {
    final archive = Archive();
    final fabricJson = jsonEncode({
      'id': 'sodium',
      'name': 'Sodium',
      'version': '1.2.3',
      'icon': 'assets/icon.png',
    });
    final iconBytes = <int>[137, 80, 78, 71, 0, 1, 2, 3];

    archive
      ..addFile(
        ArchiveFile(
          'fabric.mod.json',
          fabricJson.length,
          utf8.encode(fabricJson),
        ),
      )
      ..addFile(ArchiveFile('assets/icon.png', iconBytes.length, iconBytes));

    final zipBytes = ZipEncoder().encode(archive)!;
    final parsed = JarMetadataParser.parseFromArchiveBytes(
      Uint8List.fromList(zipBytes),
      'sodium.jar',
    );

    expect(parsed.name, 'Sodium');
    expect(parsed.version, '1.2.3');
    expect(parsed.modId, 'sodium');
    expect(parsed.iconBytes, isNotNull);
    expect(parsed.iconBytes, equals(iconBytes));
  });
}

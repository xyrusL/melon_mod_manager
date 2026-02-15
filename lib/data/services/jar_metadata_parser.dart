import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../models/mod_metadata_result.dart';

class JarMetadataParser {
  const JarMetadataParser._();

  static ModMetadataResult parseFromJarPath(String jarPath) {
    final fileName = p.basename(jarPath);
    final bytes = File(jarPath).readAsBytesSync();
    return parseFromArchiveBytes(Uint8List.fromList(bytes), fileName);
  }

  static ModMetadataResult parseFromArchiveBytes(
    Uint8List bytes,
    String fileName,
  ) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);

    String name = fileName;
    String version = 'Unknown';
    String modId = fileName.replaceAll('.jar', '');
    List<int>? iconBytes;

    try {
      final fabricFile = _findFile(archive, 'fabric.mod.json');
      if (fabricFile != null) {
        final parsed = jsonDecode(utf8.decode(fabricFile.content as List<int>));
        if (parsed is Map<String, dynamic>) {
          name = parsed['name'] as String? ?? name;
          version = parsed['version'] as String? ?? version;
          modId = parsed['id'] as String? ?? modId;
          final iconPath = _extractIconPathFromFabric(parsed);
          iconBytes = _readIconBytes(archive, iconPath);
          return ModMetadataResult(
            fileName: fileName,
            filePath: '',
            name: name,
            version: version,
            modId: modId,
            lastModified: DateTime.fromMillisecondsSinceEpoch(0),
            iconBytes: iconBytes,
          );
        }
      }

      final quiltFile = _findFile(archive, 'quilt.mod.json');
      if (quiltFile != null) {
        final parsed = jsonDecode(utf8.decode(quiltFile.content as List<int>));
        if (parsed is Map<String, dynamic>) {
          final quiltLoader = parsed['quilt_loader'];
          if (quiltLoader is Map<String, dynamic>) {
            name = quiltLoader['metadata'] is Map<String, dynamic>
                ? (quiltLoader['metadata'] as Map<String, dynamic>)['name']
                        as String? ??
                    name
                : name;
            version = quiltLoader['version'] as String? ?? version;
            modId = quiltLoader['id'] as String? ?? modId;
            final iconPath = quiltLoader['icon'] as String?;
            iconBytes = _readIconBytes(archive, iconPath);
          }
          return ModMetadataResult(
            fileName: fileName,
            filePath: '',
            name: name,
            version: version,
            modId: modId,
            lastModified: DateTime.fromMillisecondsSinceEpoch(0),
            iconBytes: iconBytes,
          );
        }
      }

      final modsToml = _findFile(archive, 'META-INF/mods.toml');
      if (modsToml != null) {
        final text = utf8.decode(
          modsToml.content as List<int>,
          allowMalformed: true,
        );
        final idMatch = RegExp(r'modId\s*=\s*"([^"]+)"').firstMatch(text);
        final nameMatch = RegExp(
          r'displayName\s*=\s*"([^"]+)"',
        ).firstMatch(text);
        final versionMatch = RegExp(
          r'version\s*=\s*"([^"]+)"',
        ).firstMatch(text);
        modId = idMatch?.group(1) ?? modId;
        name = nameMatch?.group(1) ?? name;
        version = versionMatch?.group(1) ?? version;
      }
    } catch (_) {
      // Best-effort parser, fallback values are returned below.
    }

    return ModMetadataResult(
      fileName: fileName,
      filePath: '',
      name: name,
      version: version,
      modId: modId,
      lastModified: DateTime.fromMillisecondsSinceEpoch(0),
      iconBytes: iconBytes,
    );
  }

  static ArchiveFile? _findFile(Archive archive, String name) {
    for (final file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      if (file.name.toLowerCase() == name.toLowerCase()) {
        return file;
      }
    }
    return null;
  }

  static String? _extractIconPathFromFabric(Map<String, dynamic> parsed) {
    final icon = parsed['icon'];
    if (icon is String) {
      return icon;
    }
    if (icon is Map<String, dynamic> && icon.isNotEmpty) {
      final keys = icon.keys.toList()..sort();
      return icon[keys.last] as String?;
    }
    return null;
  }

  static List<int>? _readIconBytes(Archive archive, String? iconPath) {
    if (iconPath == null || iconPath.trim().isEmpty) {
      return null;
    }

    final normalized = iconPath.replaceAll('\\', '/').toLowerCase();
    for (final file in archive.files) {
      if (!file.isFile) {
        continue;
      }
      if (file.name.replaceAll('\\', '/').toLowerCase() == normalized) {
        return file.content as List<int>;
      }
    }

    return null;
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/mod_metadata_result.dart';
import 'jar_metadata_parser.dart';

class ScanCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }
}

class ModScanUpdate {
  const ModScanUpdate({
    required this.metadata,
    required this.processed,
    required this.total,
  });

  final ModMetadataResult metadata;
  final int processed;
  final int total;
}

class ModScannerService {
  Future<Stream<ModScanUpdate>> scanFolder(
    String modsFolderPath, {
    ScanCancellationToken? cancellationToken,
  }) async {
    final directory = Directory(modsFolderPath);
    if (!await directory.exists()) {
      throw Exception('Mods folder does not exist.');
    }

    final jarFiles = <File>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.jar') {
        jarFiles.add(entity);
      }
    }

    jarFiles.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );

    return _scanFiles(
      jarFiles,
      cancellationToken: cancellationToken,
    );
  }

  Stream<ModScanUpdate> _scanFiles(
    List<File> jarFiles, {
    ScanCancellationToken? cancellationToken,
  }) async* {
    final cache = await _readMetadataCache();
    final nextCache = <String, _MetadataCacheEntry>{};

    final total = jarFiles.length;
    var processed = 0;

    for (final file in jarFiles) {
      if (cancellationToken?.isCancelled ?? false) {
        break;
      }

      final stat = await file.stat();
      final cacheKey = _cacheKey(file.path);
      final cached = cache[cacheKey];

      ModMetadataResult metadata;
      try {
        if (cached != null &&
            cached.lastModifiedMs == stat.modified.millisecondsSinceEpoch &&
            cached.fileSize == stat.size) {
          metadata = cached.toMetadata(file.path);
        } else {
          metadata = await _readMetadataFromFile(file);
        }
      } catch (_) {
        final fileName = p.basename(file.path);
        metadata = ModMetadataResult(
          fileName: fileName,
          filePath: file.path,
          name: fileName,
          version: 'Unknown',
          modId: p.basenameWithoutExtension(fileName),
          lastModified: await file.lastModified(),
        );
      }

      nextCache[cacheKey] = _MetadataCacheEntry.fromMetadata(
        metadata: metadata,
        fileSize: stat.size,
      );

      processed++;
      yield ModScanUpdate(
        metadata: metadata,
        processed: processed,
        total: total,
      );
    }

    if (!(cancellationToken?.isCancelled ?? false)) {
      await _writeMetadataCache(nextCache);
    }
  }

  Future<ModMetadataResult> _readMetadataFromFile(File file) async {
    final parsed = await Isolate.run(
      () => JarMetadataParser.parseFromJarPath(file.path),
    );

    final modifiedAt = await file.lastModified();
    final iconPath = await _cacheIcon(file.path, parsed.iconBytes);

    return ModMetadataResult(
      fileName: parsed.fileName,
      filePath: file.path,
      name: parsed.name,
      version: parsed.version,
      modId: parsed.modId,
      lastModified: modifiedAt,
      iconBytes: parsed.iconBytes,
      iconCachePath: iconPath,
    );
  }

  String _cacheKey(String filePath) => p.normalize(filePath).toLowerCase();

  Future<File> _metadataCacheFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final appDir = Directory(p.join(supportDir.path, 'melon_mod'));
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File(p.join(appDir.path, 'mod_metadata_cache_v1.json'));
  }

  Future<Map<String, _MetadataCacheEntry>> _readMetadataCache() async {
    try {
      final file = await _metadataCacheFile();
      if (!await file.exists()) {
        return <String, _MetadataCacheEntry>{};
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return <String, _MetadataCacheEntry>{};
      }

      final map = <String, _MetadataCacheEntry>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          map[entry.key] = _MetadataCacheEntry.fromJson(value);
        } else if (value is Map) {
          map[entry.key] = _MetadataCacheEntry.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
      return map;
    } catch (_) {
      return <String, _MetadataCacheEntry>{};
    }
  }

  Future<void> _writeMetadataCache(
    Map<String, _MetadataCacheEntry> cache,
  ) async {
    try {
      final file = await _metadataCacheFile();
      final serializable = <String, Map<String, dynamic>>{};
      for (final entry in cache.entries) {
        serializable[entry.key] = entry.value.toJson();
      }
      await file.writeAsString(jsonEncode(serializable), flush: true);
    } catch (_) {
      // Cache writes should never break scanning.
    }
  }

  Future<String?> _cacheIcon(String filePath, List<int>? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final iconDir = Directory(p.join(tempDir.path, 'melon_mod', 'icon_cache'));
    if (!await iconDir.exists()) {
      await iconDir.create(recursive: true);
    }

    final hash = sha1.convert(utf8.encode(filePath)).toString();
    final iconFile = File(p.join(iconDir.path, '$hash.png'));

    if (!await iconFile.exists()) {
      await iconFile.writeAsBytes(bytes, flush: true);
    }

    return iconFile.path;
  }
}

class _MetadataCacheEntry {
  const _MetadataCacheEntry({
    required this.fileName,
    required this.name,
    required this.version,
    required this.modId,
    required this.lastModifiedMs,
    required this.fileSize,
    this.iconCachePath,
  });

  final String fileName;
  final String name;
  final String version;
  final String modId;
  final int lastModifiedMs;
  final int fileSize;
  final String? iconCachePath;

  factory _MetadataCacheEntry.fromMetadata({
    required ModMetadataResult metadata,
    required int fileSize,
  }) {
    return _MetadataCacheEntry(
      fileName: metadata.fileName,
      name: metadata.name,
      version: metadata.version,
      modId: metadata.modId,
      lastModifiedMs: metadata.lastModified.millisecondsSinceEpoch,
      fileSize: fileSize,
      iconCachePath: metadata.iconCachePath,
    );
  }

  factory _MetadataCacheEntry.fromJson(Map<String, dynamic> json) {
    return _MetadataCacheEntry(
      fileName: json['file_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? 'Unknown',
      modId: json['mod_id'] as String? ?? '',
      lastModifiedMs: json['last_modified_ms'] as int? ?? 0,
      fileSize: json['file_size'] as int? ?? 0,
      iconCachePath: json['icon_cache_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'file_name': fileName,
        'name': name,
        'version': version,
        'mod_id': modId,
        'last_modified_ms': lastModifiedMs,
        'file_size': fileSize,
        'icon_cache_path': iconCachePath,
      };

  ModMetadataResult toMetadata(String filePath) {
    return ModMetadataResult(
      fileName: fileName.isEmpty ? p.basename(filePath) : fileName,
      filePath: filePath,
      name: name.isEmpty ? p.basenameWithoutExtension(filePath) : name,
      version: version,
      modId: modId.isEmpty ? p.basenameWithoutExtension(filePath) : modId,
      lastModified: DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      iconCachePath: iconCachePath,
    );
  }
}

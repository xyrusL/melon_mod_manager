import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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

    return _scanFiles(jarFiles, cancellationToken: cancellationToken);
  }

  Stream<ModScanUpdate> _scanFiles(
    List<File> jarFiles, {
    ScanCancellationToken? cancellationToken,
  }) async* {
    final total = jarFiles.length;
    var processed = 0;

    for (final file in jarFiles) {
      if (cancellationToken?.isCancelled ?? false) {
        break;
      }

      ModMetadataResult metadata;
      try {
        metadata = await _readMetadataFromFile(file);
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

      processed++;
      yield ModScanUpdate(
        metadata: metadata,
        processed: processed,
        total: total,
      );
    }
  }

  Future<ModMetadataResult> _readMetadataFromFile(File file) async {
    final fileName = p.basename(file.path);
    final bytes = await file.readAsBytes();

    final parsed = await Isolate.run(
      () => JarMetadataParser.parseFromArchiveBytes(
        Uint8List.fromList(bytes),
        fileName,
      ),
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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'jar_metadata_parser.dart';

class InstalledModSnapshot {
  const InstalledModSnapshot({
    required this.fileName,
    required this.filePath,
    required this.modId,
    required this.version,
  });

  final String fileName;
  final String filePath;
  final String modId;
  final String version;
}

class ModPackExportResult {
  const ModPackExportResult({
    required this.zipPath,
    required this.exportedCount,
  });

  final String zipPath;
  final int exportedCount;
}

class ModPackImportResult {
  const ModPackImportResult({
    required this.zipPath,
    required this.importedFromMelonPack,
    required this.jarEntriesFound,
    required this.installed,
    required this.updated,
    required this.renamed,
    required this.skippedSameVersion,
    required this.skippedOlderVersion,
    required this.skippedIdenticalFile,
    required this.skippedDuplicateEntries,
    required this.failed,
    required this.touchedFileNames,
    required this.removedFileNames,
    required this.notes,
  });

  final String zipPath;
  final bool importedFromMelonPack;
  final int jarEntriesFound;
  final int installed;
  final int updated;
  final int renamed;
  final int skippedSameVersion;
  final int skippedOlderVersion;
  final int skippedIdenticalFile;
  final int skippedDuplicateEntries;
  final int failed;
  final Set<String> touchedFileNames;
  final Set<String> removedFileNames;
  final List<String> notes;
}

class ModPackService {
  static const _manifestName = 'melon_mod_pack.json';

  Future<ModPackExportResult> exportModsToZip({
    required String modsPath,
    required String zipPath,
  }) async {
    final modsDir = Directory(modsPath);
    if (!await modsDir.exists()) {
      throw Exception('Mods folder does not exist.');
    }

    final jarFiles = <File>[];
    await for (final entity in modsDir.list(followLinks: false)) {
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

    final archive = Archive();
    final filesManifest = <Map<String, dynamic>>[];
    for (final file in jarFiles) {
      final fileName = p.basename(file.path);
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile('mods/$fileName', bytes.length, bytes));

      try {
        final metadata = JarMetadataParser.parseFromArchiveBytes(
          Uint8List.fromList(bytes),
          fileName,
        );
        filesManifest.add({
          'file_name': fileName,
          'mod_id': metadata.modId,
          'name': metadata.name,
          'version': metadata.version,
          'size': bytes.length,
        });
      } catch (_) {
        filesManifest.add({
          'file_name': fileName,
          'mod_id': p.basenameWithoutExtension(fileName),
          'name': fileName,
          'version': 'Unknown',
          'size': bytes.length,
        });
      }
    }

    final manifest = {
      'type': 'melon_mod_pack',
      'schema_version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'files': filesManifest,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
        ArchiveFile(_manifestName, manifestBytes.length, manifestBytes));

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null || encoded.isEmpty) {
      throw Exception('Failed to create zip package.');
    }

    final target = File(zipPath);
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }
    await target.writeAsBytes(encoded, flush: true);

    return ModPackExportResult(
      zipPath: target.path,
      exportedCount: jarFiles.length,
    );
  }

  Future<ModPackImportResult> importModsFromZip({
    required String modsPath,
    required String zipPath,
    required List<InstalledModSnapshot> installedMods,
  }) async {
    final targetZip = File(zipPath);
    if (!await targetZip.exists()) {
      throw Exception('Zip file not found.');
    }

    final modsDir = Directory(modsPath);
    if (!await modsDir.exists()) {
      throw Exception('Mods folder does not exist.');
    }

    final bytes = await targetZip.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final importedFromMelonPack = archive.files.any(
      (entry) =>
          entry.isFile &&
          p.basename(entry.name).toLowerCase() == _manifestName.toLowerCase(),
    );

    final jarEntries = archive.files.where((entry) {
      if (!entry.isFile) {
        return false;
      }
      return p.extension(entry.name).toLowerCase() == '.jar';
    }).toList();

    final notes = <String>[];
    if (jarEntries.isEmpty) {
      return ModPackImportResult(
        zipPath: zipPath,
        importedFromMelonPack: importedFromMelonPack,
        jarEntriesFound: 0,
        installed: 0,
        updated: 0,
        renamed: 0,
        skippedSameVersion: 0,
        skippedOlderVersion: 0,
        skippedIdenticalFile: 0,
        skippedDuplicateEntries: 0,
        failed: 0,
        touchedFileNames: const <String>{},
        removedFileNames: const <String>{},
        notes: const ['No .jar files found in the selected zip file.'],
      );
    }

    var installed = 0;
    var updated = 0;
    var renamed = 0;
    var skippedSameVersion = 0;
    var skippedOlderVersion = 0;
    var skippedIdenticalFile = 0;
    var skippedDuplicateEntries = 0;
    var failed = 0;

    final touchedFileNames = <String>{};
    final removedFileNames = <String>{};
    final seenEntryKeys = <String>{};

    final currentByFileName = <String, InstalledModSnapshot>{};
    final currentByModId = <String, List<InstalledModSnapshot>>{};
    for (final mod in installedMods) {
      currentByFileName[mod.fileName] = mod;
      final key = _canonical(mod.modId);
      if (key.isNotEmpty) {
        currentByModId.putIfAbsent(key, () => []).add(mod);
      }
    }

    for (final entry in jarEntries) {
      try {
        final rawName = p.basename(entry.name);
        if (rawName.isEmpty) {
          continue;
        }

        final entryBytes = _asBytes(entry.content);
        if (entryBytes == null || entryBytes.isEmpty) {
          failed++;
          if (notes.length < 8) {
            notes.add('$rawName: empty or invalid jar entry.');
          }
          continue;
        }

        final parsed = JarMetadataParser.parseFromArchiveBytes(
          Uint8List.fromList(entryBytes),
          rawName,
        );
        final modKey = _canonical(parsed.modId);
        final dedupeKey = '$modKey|${parsed.version}|${rawName.toLowerCase()}';
        if (seenEntryKeys.contains(dedupeKey)) {
          skippedDuplicateEntries++;
          continue;
        }
        seenEntryKeys.add(dedupeKey);

        final installedWithSameModId = modKey.isEmpty
            ? const <InstalledModSnapshot>[]
            : (currentByModId[modKey] ?? const <InstalledModSnapshot>[]);

        if (installedWithSameModId.isNotEmpty) {
          final sameVersion = installedWithSameModId.any(
            (mod) => mod.version.trim() == parsed.version.trim(),
          );
          if (sameVersion) {
            skippedSameVersion++;
            continue;
          }

          final replaceTarget = installedWithSameModId.firstWhere(
            (mod) => mod.fileName.toLowerCase() == rawName.toLowerCase(),
            orElse: () => installedWithSameModId.first,
          );
          final versionOrder = _compareLooseVersions(
            replaceTarget.version,
            parsed.version,
          );
          if (versionOrder != null && versionOrder > 0) {
            skippedOlderVersion++;
            continue;
          }

          final replaceFile = File(replaceTarget.filePath);
          if (await replaceFile.exists()) {
            await replaceFile.delete();
          }
          removedFileNames.add(replaceTarget.fileName);
          currentByFileName.remove(replaceTarget.fileName);
          currentByModId[modKey] = currentByModId[modKey]!
              .where((mod) => mod.fileName != replaceTarget.fileName)
              .toList();

          var targetName = rawName;
          var targetPath = p.join(modsPath, targetName);
          if (currentByFileName.containsKey(targetName)) {
            targetName = _buildRenamedFileName(targetName);
            targetPath = p.join(modsPath, targetName);
            renamed++;
          }

          await _writeBytesAtomic(targetPath, entryBytes);
          updated++;
          touchedFileNames.add(targetName);

          final next = InstalledModSnapshot(
            fileName: targetName,
            filePath: targetPath,
            modId: parsed.modId,
            version: parsed.version,
          );
          currentByFileName[targetName] = next;
          if (modKey.isNotEmpty) {
            currentByModId.putIfAbsent(modKey, () => []).add(next);
          }
          continue;
        }

        var targetName = rawName;
        var targetPath = p.join(modsPath, targetName);
        if (currentByFileName.containsKey(targetName)) {
          final existingFile = File(targetPath);
          if (await existingFile.exists()) {
            final sameBytes = await _hasSameBytes(existingFile, entryBytes);
            if (sameBytes) {
              skippedIdenticalFile++;
              continue;
            }
          }

          targetName = _buildRenamedFileName(targetName);
          targetPath = p.join(modsPath, targetName);
          renamed++;
        }

        await _writeBytesAtomic(targetPath, entryBytes);
        installed++;
        touchedFileNames.add(targetName);

        final next = InstalledModSnapshot(
          fileName: targetName,
          filePath: targetPath,
          modId: parsed.modId,
          version: parsed.version,
        );
        currentByFileName[targetName] = next;
        if (modKey.isNotEmpty) {
          currentByModId.putIfAbsent(modKey, () => []).add(next);
        }
      } catch (error) {
        failed++;
        if (notes.length < 8) {
          notes.add('${p.basename(entry.name)}: $error');
        }
      }
    }

    return ModPackImportResult(
      zipPath: zipPath,
      importedFromMelonPack: importedFromMelonPack,
      jarEntriesFound: jarEntries.length,
      installed: installed,
      updated: updated,
      renamed: renamed,
      skippedSameVersion: skippedSameVersion,
      skippedOlderVersion: skippedOlderVersion,
      skippedIdenticalFile: skippedIdenticalFile,
      skippedDuplicateEntries: skippedDuplicateEntries,
      failed: failed,
      touchedFileNames: touchedFileNames,
      removedFileNames: removedFileNames,
      notes: notes,
    );
  }

  List<int>? _asBytes(Object? content) {
    if (content is List<int>) {
      return content;
    }
    if (content is Uint8List) {
      return content;
    }
    return null;
  }

  String _buildRenamedFileName(String fileName) {
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);
    return '${base}_imported_${DateTime.now().millisecondsSinceEpoch}$ext';
  }

  String _canonical(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<bool> _hasSameBytes(File existingFile, List<int> incomingBytes) async {
    final existingBytes = await existingFile.readAsBytes();
    final existingHash = sha1.convert(existingBytes).toString();
    final incomingHash = sha1.convert(incomingBytes).toString();
    return existingHash == incomingHash;
  }

  Future<void> _writeBytesAtomic(String targetPath, List<int> bytes) async {
    final target = File(targetPath);
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }
    final temp = File('$targetPath.part');
    await temp.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
  }

  int? _compareLooseVersions(String current, String incoming) {
    final currentParts = RegExp(r'\d+')
        .allMatches(current)
        .map((m) => int.tryParse(m.group(0) ?? ''))
        .whereType<int>()
        .toList();
    final incomingParts = RegExp(r'\d+')
        .allMatches(incoming)
        .map((m) => int.tryParse(m.group(0) ?? ''))
        .whereType<int>()
        .toList();
    if (currentParts.isEmpty || incomingParts.isEmpty) {
      return null;
    }

    final maxLen = currentParts.length > incomingParts.length
        ? currentParts.length
        : incomingParts.length;
    for (var i = 0; i < maxLen; i++) {
      final a = i < currentParts.length ? currentParts[i] : 0;
      final b = i < incomingParts.length ? incomingParts[i] : 0;
      if (a != b) {
        return a > b ? 1 : -1;
      }
    }
    return 0;
  }
}

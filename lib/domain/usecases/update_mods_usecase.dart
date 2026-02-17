import 'dart:io';

import 'package:path/path.dart' as p;

import '../entities/mod_item.dart';
import '../entities/modrinth_mapping.dart';
import '../repositories/modrinth_mapping_repository.dart';
import '../repositories/modrinth_repository.dart';

class UpdateModsUsecase {
  UpdateModsUsecase({
    required ModrinthRepository modrinthRepository,
    required ModrinthMappingRepository mappingRepository,
  })  : _modrinthRepository = modrinthRepository,
        _mappingRepository = mappingRepository;

  final ModrinthRepository _modrinthRepository;
  final ModrinthMappingRepository _mappingRepository;

  Future<UpdateSummary> execute({
    required String modsPath,
    required List<ModItem> mods,
    String loader = 'fabric',
    String? gameVersion,
  }) async {
    var updated = 0;
    var alreadyLatest = 0;
    var externalSkipped = 0;
    var failed = 0;
    final notes = <String>[];
    final updatedMods = <String>[];
    final alreadyLatestMods = <String>[];
    final externalSkippedMods = <String>[];
    final failedMods = <String>[];
    await _cleanupLegacyModsTempDir(modsPath);

    try {
      for (final mod in mods) {
        if (mod.provider == ModProviderType.external) {
          externalSkipped++;
          externalSkippedMods.add(mod.displayName);
          if (notes.length < 5) {
            notes.add('${mod.displayName}: Cannot update (not from Modrinth).');
          }
          continue;
        }

        final mapping = await _mappingRepository.getByFileName(mod.fileName);
        if (mapping == null) {
          externalSkipped++;
          externalSkippedMods.add(mod.displayName);
          if (notes.length < 5) {
            notes.add('${mod.displayName}: Cannot update (not from Modrinth).');
          }
          continue;
        }

        try {
          final latest = await _modrinthRepository.getLatestVersion(
            mapping.projectId,
            loader: loader,
            gameVersion: gameVersion,
          );

          if (latest == null) {
            alreadyLatest++;
            alreadyLatestMods.add(mod.displayName);
            continue;
          }

          if (latest.id == mapping.versionId) {
            alreadyLatest++;
            alreadyLatestMods.add(mod.displayName);
            continue;
          }

          final file = latest.primaryJarFile;
          if (file == null) {
            notes.add('No .jar update file found for ${mod.displayName}.');
            failed++;
            failedMods.add(mod.displayName);
            continue;
          }

          final stagingPath = await _createStagingPath(fileName: file.fileName);
          final downloaded = await _modrinthRepository.downloadVersionFile(
            file: file,
            targetPath: stagingPath,
          );

          if (!await downloaded.exists() || await downloaded.length() <= 0) {
            notes.add('Failed to update ${mod.displayName}: empty download.');
            failed++;
            failedMods.add(mod.displayName);
            continue;
          }

          final targetPath = p.join(modsPath, file.fileName);
          await _commitStagedFile(
            stagedFile: downloaded,
            targetPath: targetPath,
          );

          await _cleanupOldMappedFiles(
            modsPath: modsPath,
            projectId: mapping.projectId,
            incomingFileName: file.fileName,
          );

          await _mappingRepository.put(
            ModrinthMapping(
              jarFileName: file.fileName,
              projectId: mapping.projectId,
              versionId: latest.id,
              installedAt: DateTime.now(),
              versionNumber: latest.versionNumber,
              sha1: file.sha1,
              sha512: file.sha512,
            ),
          );
          updated++;
          updatedMods.add(mod.displayName);
        } catch (error) {
          failed++;
          failedMods.add(mod.displayName);
          notes.add('Update failed for ${mod.displayName}: $error');
        }
      }
    } finally {
      await _cleanupLegacyModsTempDir(modsPath);
    }

    return UpdateSummary(
      totalChecked: mods.length,
      updated: updated,
      alreadyLatest: alreadyLatest,
      externalSkipped: externalSkipped,
      failed: failed,
      notes: notes,
      updatedMods: updatedMods,
      alreadyLatestMods: alreadyLatestMods,
      externalSkippedMods: externalSkippedMods,
      failedMods: failedMods,
    );
  }

  Future<String> _createStagingPath({required String fileName}) async {
    final stagingDir = Directory(
      p.join(Directory.systemTemp.path, 'melon_mod', 'staging'),
    );
    if (!await stagingDir.exists()) {
      await stagingDir.create(recursive: true);
    }
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(stagingDir.path, '${timestamp}_$fileName');
  }

  Future<void> _cleanupLegacyModsTempDir(String modsPath) async {
    final legacy = Directory(p.join(modsPath, '.melon_tmp'));
    if (!await legacy.exists()) {
      return;
    }
    try {
      await legacy.delete(recursive: true);
    } catch (_) {
      // Keep update flow resilient if legacy cleanup fails.
    }
  }

  Future<void> _cleanupOldMappedFiles({
    required String modsPath,
    required String projectId,
    required String incomingFileName,
  }) async {
    final allMappings = await _mappingRepository.getAll();
    for (final mapping in allMappings.values) {
      if (mapping.projectId != projectId) {
        continue;
      }
      if (mapping.jarFileName == incomingFileName) {
        continue;
      }

      final oldPath = p.join(modsPath, mapping.jarFileName);
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
      await _mappingRepository.remove(mapping.jarFileName);
    }
  }

  Future<void> _commitStagedFile({
    required File stagedFile,
    required String targetPath,
  }) async {
    final target = File(targetPath);
    final backup = File('$targetPath.bak');

    if (await backup.exists()) {
      await backup.delete();
    }

    try {
      if (await target.exists()) {
        await target.rename(backup.path);
      }

      try {
        await _moveFile(stagedFile, target);
        if (await backup.exists()) {
          await backup.delete();
        }
      } catch (_) {
        if (await target.exists()) {
          await target.delete();
        }
        if (await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }
    } finally {
      if (await stagedFile.exists()) {
        await stagedFile.delete();
      }
    }
  }

  Future<void> _moveFile(File source, File destination) async {
    if (!await destination.parent.exists()) {
      await destination.parent.create(recursive: true);
    }

    try {
      await source.rename(destination.path);
    } on FileSystemException {
      await source.copy(destination.path);
      await source.delete();
    }
  }
}

class UpdateSummary {
  const UpdateSummary({
    required this.totalChecked,
    required this.updated,
    required this.alreadyLatest,
    required this.externalSkipped,
    required this.failed,
    required this.notes,
    required this.updatedMods,
    required this.alreadyLatestMods,
    required this.externalSkippedMods,
    required this.failedMods,
  });

  final int totalChecked;
  final int updated;
  final int alreadyLatest;
  final int externalSkipped;
  final int failed;
  final List<String> notes;
  final List<String> updatedMods;
  final List<String> alreadyLatestMods;
  final List<String> externalSkippedMods;
  final List<String> failedMods;
}

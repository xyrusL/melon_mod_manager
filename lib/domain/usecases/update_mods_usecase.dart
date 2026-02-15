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

    for (final mod in mods) {
      if (mod.provider == ModProviderType.external) {
        externalSkipped++;
        if (notes.length < 5) {
          notes.add('${mod.displayName}: Cannot update (not from Modrinth).');
        }
        continue;
      }

      final mapping = await _mappingRepository.getByFileName(mod.fileName);
      if (mapping == null) {
        externalSkipped++;
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
          continue;
        }

        if (latest.id == mapping.versionId) {
          alreadyLatest++;
          continue;
        }

        final file = latest.primaryJarFile;
        if (file == null) {
          notes.add('No .jar update file found for ${mod.displayName}.');
          failed++;
          continue;
        }

        final newTarget = p.join(modsPath, file.fileName);
        final downloaded = await _modrinthRepository.downloadVersionFile(
          file: file,
          targetPath: newTarget,
        );

        if (downloaded.lengthSync() <= 0) {
          notes.add('Failed to update ${mod.displayName}: empty download.');
          failed++;
          continue;
        }

        if (file.fileName != mapping.jarFileName) {
          final oldPath = p.join(modsPath, mapping.jarFileName);
          final oldFile = File(oldPath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
          await _mappingRepository.remove(mapping.jarFileName);
        }

        await _mappingRepository.put(
          ModrinthMapping(
            jarFileName: file.fileName,
            projectId: mapping.projectId,
            versionId: latest.id,
            installedAt: DateTime.now(),
            sha1: file.sha1,
            sha512: file.sha512,
          ),
        );
        updated++;
      } catch (error) {
        failed++;
        notes.add('Update failed for ${mod.displayName}: $error');
      }
    }

    return UpdateSummary(
      totalChecked: mods.length,
      updated: updated,
      alreadyLatest: alreadyLatest,
      externalSkipped: externalSkipped,
      failed: failed,
      notes: notes,
    );
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
  });

  final int totalChecked;
  final int updated;
  final int alreadyLatest;
  final int externalSkipped;
  final int failed;
  final List<String> notes;
}

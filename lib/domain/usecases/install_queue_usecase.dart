import 'dart:io';

import 'package:path/path.dart' as p;

import '../entities/modrinth_mapping.dart';
import '../repositories/modrinth_mapping_repository.dart';
import '../repositories/modrinth_repository.dart';
import '../services/dependency_resolver_service.dart';

typedef ProgressCallback = Future<void> Function(InstallProgress progress);

class InstallQueueUsecase {
  InstallQueueUsecase({
    required ModrinthRepository modrinthRepository,
    required ModrinthMappingRepository mappingRepository,
  })  : _modrinthRepository = modrinthRepository,
        _mappingRepository = mappingRepository;

  final ModrinthRepository _modrinthRepository;
  final ModrinthMappingRepository _mappingRepository;

  Future<void> executeInstallQueue(
    DependencyPlan plan, {
    required String modsPath,
    required ProgressCallback onProgress,
  }) async {
    final total = plan.installQueueInOrder.length;
    await _cleanupLegacyModsTempDir(modsPath);

    try {
      for (var index = 0; index < total; index++) {
        final item = plan.installQueueInOrder[index];
        final file = item.version.primaryJarFile;
        if (file == null) {
          throw Exception('No .jar file available for ${item.version.name}.');
        }

        final step = index + 1;
        await onProgress(
          InstallProgress(
            stage: InstallProgressStage.downloading,
            current: step,
            total: total,
            modName: item.displayName,
            message: 'Downloading $step/$total: ${item.displayName}',
          ),
        );

        final stagingPath = await _createStagingPath(fileName: file.fileName);
        final downloaded = await _modrinthRepository.downloadVersionFile(
          file: file,
          targetPath: stagingPath,
        );

        if (!await downloaded.exists() || await downloaded.length() <= 0) {
          throw Exception('Download failed for ${item.displayName}.');
        }

        await onProgress(
          InstallProgress(
            stage: InstallProgressStage.installing,
            current: step,
            total: total,
            modName: item.displayName,
            message: 'Installing $step/$total: ${item.displayName}',
          ),
        );

        await _cleanupOldMappedFiles(
          modsPath: modsPath,
          projectId: item.projectId,
          incomingFileName: file.fileName,
        );

        final targetPath = p.join(modsPath, file.fileName);
        await _commitStagedFile(
          stagedFile: downloaded,
          targetPath: targetPath,
        );

        await _mappingRepository.put(
          ModrinthMapping(
            jarFileName: file.fileName,
            projectId: item.projectId,
            versionId: item.version.id,
            installedAt: DateTime.now(),
            sha1: file.sha1,
            sha512: file.sha512,
          ),
        );
      }

      await onProgress(
        InstallProgress(
          stage: InstallProgressStage.done,
          current: total,
          total: total,
          modName: null,
          message: 'Installation completed.',
        ),
      );
    } finally {
      await _cleanupLegacyModsTempDir(modsPath);
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
      // Keep install flow resilient if legacy cleanup fails.
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

enum InstallProgressStage { resolving, downloading, installing, done, error }

class InstallProgress {
  const InstallProgress({
    required this.stage,
    required this.current,
    required this.total,
    required this.message,
    this.modName,
  });

  final InstallProgressStage stage;
  final int current;
  final int total;
  final String message;
  final String? modName;
}

import 'dart:io';

import 'package:path/path.dart' as p;

enum ConflictResolution { overwrite, rename, skip }

class FileInstallService {
  Future<List<FileInstallResult>> installJarFiles({
    required String modsFolderPath,
    required List<String> sourcePaths,
    required Future<ConflictResolution> Function(String fileName) onConflict,
  }) async {
    final results = <FileInstallResult>[];

    for (final sourcePath in sourcePaths) {
      final source = File(sourcePath);
      if (!await source.exists()) {
        results.add(
          FileInstallResult(
            sourcePath: sourcePath,
            success: false,
            message: 'Source file not found.',
          ),
        );
        continue;
      }

      var fileName = p.basename(sourcePath);
      var destination = File(p.join(modsFolderPath, fileName));

      if (await destination.exists()) {
        final resolution = await onConflict(fileName);
        if (resolution == ConflictResolution.skip) {
          results.add(
            FileInstallResult(
              sourcePath: sourcePath,
              success: false,
              message: 'Skipped by user.',
            ),
          );
          continue;
        }

        if (resolution == ConflictResolution.rename) {
          fileName = _buildRenamedFileName(fileName);
          destination = File(p.join(modsFolderPath, fileName));
        }
      }

      await source.copy(destination.path);
      results.add(
        FileInstallResult(
          sourcePath: sourcePath,
          success: true,
          installedFileName: fileName,
          message: 'Installed.',
        ),
      );
    }

    return results;
  }

  String _buildRenamedFileName(String fileName) {
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);
    return '${base}_${DateTime.now().millisecondsSinceEpoch}$ext';
  }
}

class FileInstallResult {
  const FileInstallResult({
    required this.sourcePath,
    required this.success,
    required this.message,
    this.installedFileName,
  });

  final String sourcePath;
  final bool success;
  final String message;
  final String? installedFileName;
}

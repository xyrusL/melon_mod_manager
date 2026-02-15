import 'dart:io';

import '../entities/modrinth_project.dart';
import '../entities/modrinth_version.dart';

abstract class ModrinthRepository {
  Future<List<ModrinthProject>> searchProjects(
    String query, {
    String loader = 'fabric',
    String? gameVersion,
    int limit = 20,
  });

  Future<ModrinthVersion?> getLatestVersion(
    String projectId, {
    String loader = 'fabric',
    String? gameVersion,
  });

  Future<ModrinthVersion?> getVersionById(String versionId);

  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String loader = 'fabric',
    String? gameVersion,
  });

  Future<File> downloadVersionFile({
    required ModrinthFile file,
    required String targetPath,
  });
}

import 'dart:io';

import '../entities/modrinth_project.dart';
import '../entities/modrinth_version.dart';

abstract class ModrinthRepository {
  Future<List<ModrinthProject>> searchProjects(
    String query, {
    String? loader,
    String projectType = 'mod',
    String? gameVersion,
    int limit = 20,
    int offset = 0,
    String index = 'relevance',
  });

  Future<ModrinthVersion?> getLatestVersion(
    String projectId, {
    String? loader,
    String? gameVersion,
  });

  Future<ModrinthVersion?> getVersionById(String versionId);
  Future<ModrinthVersion?> getVersionByFileHash(String sha1Hash);
  Future<ModrinthProject?> getProjectById(String projectId);

  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String? loader,
    String? gameVersion,
  });

  Future<File> downloadVersionFile({
    required ModrinthFile file,
    required String targetPath,
  });
}

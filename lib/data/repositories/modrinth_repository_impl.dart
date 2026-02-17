import 'dart:io';

import '../../domain/entities/modrinth_project.dart';
import '../../domain/entities/modrinth_version.dart';
import '../../domain/repositories/modrinth_repository.dart';
import '../services/modrinth_api_client.dart';

class ModrinthRepositoryImpl implements ModrinthRepository {
  ModrinthRepositoryImpl(this._apiClient);

  final ModrinthApiClient _apiClient;
  final Map<String, ModrinthProject?> _projectCache = {};

  @override
  Future<File> downloadVersionFile({
    required ModrinthFile file,
    required String targetPath,
  }) {
    return _apiClient.downloadFile(url: file.url, targetPath: targetPath);
  }

  @override
  Future<ModrinthVersion?> getLatestVersion(
    String projectId, {
    String? loader,
    String? gameVersion,
  }) async {
    final versions = await _apiClient.getProjectVersions(
      projectId,
      loader: loader,
      gameVersion: gameVersion,
    );

    if (versions.isEmpty) {
      return null;
    }

    versions.sort((a, b) => b.datePublished.compareTo(a.datePublished));
    return versions.first.toEntity();
  }

  @override
  Future<ModrinthVersion?> getVersionById(String versionId) async {
    final model = await _apiClient.getVersionById(versionId);
    return model.toEntity();
  }

  @override
  Future<ModrinthVersion?> getVersionByFileHash(String sha1Hash) async {
    final model = await _apiClient.getVersionByFileHash(sha1Hash);
    return model?.toEntity();
  }

  @override
  Future<ModrinthProject?> getProjectById(String projectId) async {
    if (_projectCache.containsKey(projectId)) {
      return _projectCache[projectId];
    }
    final model = await _apiClient.getProjectById(projectId);
    final entity = model?.toEntity();
    _projectCache[projectId] = entity;
    return entity;
  }

  @override
  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String? loader,
    String? gameVersion,
  }) async {
    final models = await _apiClient.getProjectVersions(
      projectId,
      loader: loader,
      gameVersion: gameVersion,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ModrinthProject>> searchProjects(
    String query, {
    String? loader,
    String projectType = 'mod',
    String? gameVersion,
    int limit = 20,
    int offset = 0,
    String index = 'relevance',
  }) async {
    final result = await _apiClient.searchProjects(
      query,
      loader: loader,
      projectType: projectType,
      gameVersion: gameVersion,
      limit: limit,
      offset: offset,
      index: index,
    );

    return result.map((m) => m.toEntity()).toList();
  }
}

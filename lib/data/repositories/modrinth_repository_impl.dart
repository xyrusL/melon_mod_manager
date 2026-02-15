import 'dart:io';

import '../../domain/entities/modrinth_project.dart';
import '../../domain/entities/modrinth_version.dart';
import '../../domain/repositories/modrinth_repository.dart';
import '../services/modrinth_api_client.dart';

class ModrinthRepositoryImpl implements ModrinthRepository {
  ModrinthRepositoryImpl(this._apiClient);

  final ModrinthApiClient _apiClient;

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
    String loader = 'fabric',
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
  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String loader = 'fabric',
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
    String loader = 'fabric',
    String? gameVersion,
    int limit = 20,
  }) async {
    final result = await _apiClient.searchProjects(
      query,
      loader: loader,
      gameVersion: gameVersion,
      limit: limit,
    );

    return result.map((m) => m.toEntity()).toList();
  }
}

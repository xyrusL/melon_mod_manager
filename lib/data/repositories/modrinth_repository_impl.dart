import 'dart:io';

import 'package:crypto/crypto.dart';

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
  }) async {
    final downloaded =
        await _apiClient.downloadFile(url: file.url, targetPath: targetPath);
    await _verifyFileIntegrity(downloaded, file);
    return downloaded;
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

  Future<void> _verifyFileIntegrity(File downloaded, ModrinthFile file) async {
    final expectedSha1 = file.sha1?.trim().toLowerCase();
    if (expectedSha1 != null && expectedSha1.isNotEmpty) {
      final actual = (await sha1.bind(downloaded.openRead()).first).toString();
      if (actual.toLowerCase() != expectedSha1) {
        await _safeDelete(downloaded);
        throw const FileSystemException('Downloaded file failed SHA-1 verification.');
      }
      return;
    }

    final expectedSha512 = file.sha512?.trim().toLowerCase();
    if (expectedSha512 != null && expectedSha512.isNotEmpty) {
      final actual = (await sha512.bind(downloaded.openRead()).first).toString();
      if (actual.toLowerCase() != expectedSha512) {
        await _safeDelete(downloaded);
        throw const FileSystemException('Downloaded file failed SHA-512 verification.');
      }
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup only.
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/modrinth_search_model.dart';
import '../models/modrinth_version_model.dart';

class ModrinthApiClient {
  ModrinthApiClient({
    required http.Client client,
    String baseUrl = 'https://api.modrinth.com/v2',
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Map<String, String> get _headers => const {
        'User-Agent': 'melon-mod-manager/1.0.0 (windows; flutter)',
      };

  Future<List<ModrinthSearchHitModel>> searchProjects(
    String query, {
    String? loader,
    String projectType = 'mod',
    String? gameVersion,
    int limit = 20,
    int offset = 0,
    String index = 'relevance',
  }) async {
    final facets = <List<String>>[
      ['project_type:$projectType'],
      if (loader != null && loader.isNotEmpty) ['categories:$loader'],
      if (gameVersion != null && gameVersion.isNotEmpty)
        ['versions:$gameVersion'],
    ];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'query': query,
        'limit': '$limit',
        'offset': '$offset',
        'index': index,
        'facets': jsonEncode(facets),
      },
    );

    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException('Modrinth search failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final hits = decoded['hits'] as List<dynamic>? ?? const [];
    return hits
        .whereType<Map<String, dynamic>>()
        .map(ModrinthSearchHitModel.fromJson)
        .toList();
  }

  Future<List<ModrinthVersionModel>> getProjectVersions(
    String projectId, {
    String? loader,
    String? gameVersion,
  }) async {
    final uri = Uri.parse('$_baseUrl/project/$projectId/version').replace(
      queryParameters: {
        if (loader != null && loader.isNotEmpty)
          'loaders': jsonEncode([loader]),
        if (gameVersion != null && gameVersion.isNotEmpty)
          'game_versions': jsonEncode([gameVersion]),
      },
    );

    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException('Modrinth versions failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ModrinthVersionModel.fromJson)
        .toList();
  }

  Future<ModrinthVersionModel> getVersionById(String versionId) async {
    final uri = Uri.parse('$_baseUrl/version/$versionId');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException(
          'Modrinth version lookup failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid version response.');
    }
    return ModrinthVersionModel.fromJson(decoded);
  }

  Future<ModrinthVersionModel?> getVersionByFileHash(
    String hash, {
    String algorithm = 'sha1',
  }) async {
    final uri = Uri.parse('$_baseUrl/version_file/$hash').replace(
      queryParameters: {'algorithm': algorithm},
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw HttpException(
          'Modrinth hash lookup failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return ModrinthVersionModel.fromJson(decoded);
  }

  Future<ModrinthSearchHitModel?> getProjectById(String projectId) async {
    final uri = Uri.parse('$_baseUrl/project/$projectId');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw HttpException(
          'Modrinth project lookup failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return ModrinthSearchHitModel.fromProjectJson(decoded);
  }

  Future<File> downloadFile({
    required String url,
    required String targetPath,
  }) async {
    final request = http.Request('GET', Uri.parse(url))
      ..headers.addAll(_headers);
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw HttpException('Failed to download file: ${response.statusCode}');
    }

    final target = File(targetPath);
    final temp = File('$targetPath.part');
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }

    IOSink? sink;
    var totalBytes = 0;
    try {
      sink = temp.openWrite();
      await for (final chunk in response.stream) {
        if (chunk.isEmpty) {
          continue;
        }
        sink.add(chunk);
        totalBytes += chunk.length;
      }
      await sink.flush();
      await sink.close();
      sink = null;
    } catch (_) {
      if (sink != null) {
        await sink.flush();
        await sink.close();
      }
      if (await temp.exists()) {
        await temp.delete();
      }
      rethrow;
    }

    if (totalBytes <= 0) {
      if (await temp.exists()) {
        await temp.delete();
      }
      throw const FileSystemException('Downloaded file is empty.');
    }

    if (await target.exists()) {
      final backup = File('$targetPath.bak');
      if (await backup.exists()) {
        await backup.delete();
      }
      await target.rename(backup.path);
      try {
        await temp.rename(target.path);
        if (await backup.exists()) {
          await backup.delete();
        }
      } catch (_) {
        if (await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }
    } else {
      await temp.rename(target.path);
    }

    return target;
  }
}

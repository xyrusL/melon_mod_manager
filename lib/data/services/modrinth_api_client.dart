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
    String loader = 'fabric',
    String? gameVersion,
    int limit = 20,
  }) async {
    final facets = <List<String>>[
      ['categories:$loader'],
      if (gameVersion != null && gameVersion.isNotEmpty)
        ['versions:$gameVersion'],
    ];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'query': query,
        'limit': '$limit',
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
    String loader = 'fabric',
    String? gameVersion,
  }) async {
    final uri = Uri.parse('$_baseUrl/project/$projectId/version').replace(
      queryParameters: {
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

  Future<File> downloadFile({
    required String url,
    required String targetPath,
  }) async {
    final response = await _client.get(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException('Failed to download file: ${response.statusCode}');
    }

    if (response.bodyBytes.isEmpty) {
      throw const FileSystemException('Downloaded file is empty.');
    }

    final target = File(targetPath);
    final temp = File('$targetPath.part');
    await temp.writeAsBytes(response.bodyBytes, flush: true);

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

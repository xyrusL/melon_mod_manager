import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/github_profile_model.dart';
import '../models/github_repository_model.dart';

class GitHubApiClient {
  GitHubApiClient({
    required http.Client client,
    this.baseUrl = 'https://api.github.com',
  }) : _client = client;

  final http.Client _client;
  final String baseUrl;

  Map<String, String> get _headers => const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'melon-mod-manager/1.0.0 (windows; flutter)',
      };

  Future<GitHubProfileModel> getUserProfile(String username) async {
    final uri = Uri.parse('$baseUrl/users/$username');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException(
        'GitHub user profile failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid GitHub profile response.');
    }
    return GitHubProfileModel.fromJson(decoded);
  }

  Future<GitHubRepositoryModel> getRepository(
    String owner,
    String repository,
  ) async {
    final uri = Uri.parse('$baseUrl/repos/$owner/$repository');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException(
        'GitHub repository failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid GitHub repository response.');
    }
    return GitHubRepositoryModel.fromJson(decoded);
  }
}

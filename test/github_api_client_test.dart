import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melon_mod/data/services/github_api_client.dart';

void main() {
  test('parses GitHub user profile response', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/users/xyrusL') {
        return http.Response(
          jsonEncode({
            'login': 'xyrusL',
            'name': 'Xyrus',
            'avatar_url': 'https://avatars.githubusercontent.com/u/1234',
            'html_url': 'https://github.com/xyrusL',
            'bio': 'Flutter developer',
            'followers': 10,
            'public_repos': 5,
            'updated_at': '2026-02-10T10:00:00Z',
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = GitHubApiClient(client: client);
    final profile = await api.getUserProfile('xyrusL');

    expect(profile.login, 'xyrusL');
    expect(profile.name, 'Xyrus');
    expect(profile.followers, 10);
  });

  test('parses GitHub repository response', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/repos/xyrusL/melon_mod_manager') {
        return http.Response(
          jsonEncode({
            'name': 'melon_mod_manager',
            'full_name': 'xyrusL/melon_mod_manager',
            'description': 'Mod manager app',
            'html_url': 'https://github.com/xyrusL/melon_mod_manager',
            'stargazers_count': 7,
            'forks_count': 2,
            'updated_at': '2026-02-11T10:00:00Z',
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = GitHubApiClient(client: client);
    final repo = await api.getRepository('xyrusL', 'melon_mod_manager');

    expect(repo.fullName, 'xyrusL/melon_mod_manager');
    expect(repo.stars, 7);
    expect(repo.forks, 2);
  });
}

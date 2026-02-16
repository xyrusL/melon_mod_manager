import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melon_mod/data/services/app_update_service.dart';
import 'package:melon_mod/data/services/github_api_client.dart';

void main() {
  test('returns update available when GitHub release is newer', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/repos/xyrusL/melon_mod_manager/releases/latest') {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.0.1',
            'name': 'v1.0.1',
            'html_url': 'https://github.com/xyrusL/melon_mod_manager/releases/tag/v1.0.1',
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final service = AppUpdateService(
      apiClient: GitHubApiClient(client: client),
      owner: 'xyrusL',
      repository: 'melon_mod_manager',
      currentVersionProvider: () async => '1.0.0',
    );

    final result = await service.checkForUpdate();

    expect(result.hasUpdate, isTrue);
    expect(result.latestRelease.tagName, 'v1.0.1');
  });

  test('treats stable release as newer than prerelease build', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/repos/xyrusL/melon_mod_manager/releases/latest') {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.0.0',
            'name': 'v1.0.0',
            'html_url': 'https://github.com/xyrusL/melon_mod_manager/releases/tag/v1.0.0',
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final service = AppUpdateService(
      apiClient: GitHubApiClient(client: client),
      owner: 'xyrusL',
      repository: 'melon_mod_manager',
      currentVersionProvider: () async => '1.0.0-beta.1',
    );

    final result = await service.checkForUpdate();

    expect(result.hasUpdate, isTrue);
  });
}

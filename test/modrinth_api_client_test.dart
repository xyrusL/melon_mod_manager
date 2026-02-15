import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melon_mod/data/services/modrinth_api_client.dart';

void main() {
  test('parses Modrinth search response hits', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/search')) {
        return http.Response(
          jsonEncode({
            'hits': [
              {
                'project_id': 'AANobbMI',
                'slug': 'sodium',
                'title': 'Sodium',
                'description': 'Modern rendering engine',
                'icon_url': 'https://cdn.modrinth.com/icon.png',
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ModrinthApiClient(client: mockClient);
    final result = await api.searchProjects('sodium');

    expect(result.length, 1);
    expect(result.first.projectId, 'AANobbMI');
    expect(result.first.title, 'Sodium');
  });

  test('parses Modrinth version response files', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/project/abc/version')) {
        return http.Response(
          jsonEncode([
            {
              'id': 'ver_1',
              'name': 'Sodium 1.2.3',
              'version_number': '1.2.3',
              'date_published': '2025-01-01T00:00:00.000Z',
              'loaders': ['fabric'],
              'game_versions': ['1.21.1'],
              'files': [
                {
                  'filename': 'sodium-1.2.3.jar',
                  'url': 'https://cdn.modrinth.com/sodium.jar',
                  'size': 12345,
                  'primary': true,
                  'hashes': {'sha1': 'sha1v', 'sha512': 'sha512v'},
                },
              ],
            },
          ]),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final api = ModrinthApiClient(client: mockClient);
    final versions = await api.getProjectVersions('abc');

    expect(versions.length, 1);
    expect(versions.first.id, 'ver_1');
    expect(versions.first.files.first.fileName, 'sodium-1.2.3.jar');
    expect(versions.first.files.first.primary, isTrue);
  });
}

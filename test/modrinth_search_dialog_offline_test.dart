import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/network_exceptions.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/data/services/minecraft_loader_service.dart';
import 'package:melon_mod/data/services/minecraft_version_service.dart';
import 'package:melon_mod/domain/entities/content_type.dart';
import 'package:melon_mod/domain/entities/modrinth_mapping.dart';
import 'package:melon_mod/domain/entities/modrinth_project.dart';
import 'package:melon_mod/domain/entities/modrinth_version.dart';
import 'package:melon_mod/domain/repositories/modrinth_mapping_repository.dart';
import 'package:melon_mod/domain/repositories/modrinth_repository.dart';
import 'package:melon_mod/presentation/dialogs/modrinth_search_dialog.dart';

void main() {
  group('ModrinthSearchDialog offline handling', () {
    testWidgets('shows offline prompt on initial open and exit closes dialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _FakeModrinthRepository(
        onSearch: ({
          required query,
          required loader,
          required projectType,
          required gameVersion,
          required limit,
          required offset,
          required index,
        }) async {
          throw const NetworkUnavailableException();
        },
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository),
      );
      await tester.tap(find.text('Open Download'));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);

      await tester.tap(find.text('Exit'));
      await tester.pumpAndSettle();

      expect(find.text('Open Download'), findsOneWidget);
      expect(find.text('No internet connection'), findsNothing);
    });

    testWidgets('retry reruns same search query and clears prompt on success',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var attempts = 0;
      final queries = <String>[];
      final repository = _FakeModrinthRepository(
        onSearch: ({
          required query,
          required loader,
          required projectType,
          required gameVersion,
          required limit,
          required offset,
          required index,
        }) async {
          attempts++;
          queries.add(query);
          if (attempts == 1) {
            throw const NetworkUnavailableException();
          }
          return [
            const ModrinthProject(
              id: 'sodium',
              slug: 'sodium',
              title: 'Sodium',
              description: 'Rendering mod',
              iconUrl: '',
            ),
          ];
        },
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository),
      );
      await tester.tap(find.text('Open Download'));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsNothing);
      expect(find.text('Sodium'), findsOneWidget);
      expect(queries, equals(['', '']));
    });

    testWidgets('retry preserves query after offline search failure',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final queries = <String>[];
      var attempt = 0;
      final repository = _FakeModrinthRepository(
        onSearch: ({
          required query,
          required loader,
          required projectType,
          required gameVersion,
          required limit,
          required offset,
          required index,
        }) async {
          queries.add(query);
          if (query == '') {
            return const [];
          }
          attempt++;
          if (attempt == 1) {
            throw const NetworkUnavailableException();
          }
          return [
            const ModrinthProject(
              id: 'iris',
              slug: 'iris',
              title: 'Iris',
              description: 'Shaders mod',
              iconUrl: '',
            ),
          ];
        },
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository),
      );
      await tester.tap(find.text('Open Download'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'iris');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('No internet connection'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Iris'), findsOneWidget);
      expect(queries, containsAllInOrder(['', 'iris', 'iris']));
    });
  });
}

Widget _buildTestApp({
  required ModrinthRepository repository,
}) {
  return ProviderScope(
    overrides: [
      modrinthRepositoryProvider.overrideWithValue(repository),
      mappingRepositoryProvider.overrideWithValue(_FakeMappingRepository()),
      minecraftVersionServiceProvider.overrideWithValue(
        _StubMinecraftVersionService(),
      ),
      minecraftLoaderServiceProvider.overrideWithValue(
        _StubMinecraftLoaderService(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (context) => const ModrinthSearchDialog(
                      modsPath: r'C:\offline-test\mods',
                      targetPath: r'C:\offline-test\mods',
                      contentType: ContentType.mod,
                    ),
                  );
                },
                child: const Text('Open Download'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _FakeModrinthRepository implements ModrinthRepository {
  _FakeModrinthRepository({
    required this.onSearch,
  });

  final Future<List<ModrinthProject>> Function({
    required String query,
    required String? loader,
    required String projectType,
    required String? gameVersion,
    required int limit,
    required int offset,
    required String index,
  }) onSearch;

  @override
  Future<File> downloadVersionFile({
    required ModrinthFile file,
    required String targetPath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ModrinthVersion?> getLatestVersion(
    String projectId, {
    String? loader,
    String? gameVersion,
  }) async {
    return null;
  }

  @override
  Future<ModrinthProject?> getProjectById(String projectId) async {
    return null;
  }

  @override
  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String? loader,
    String? gameVersion,
  }) async {
    return const [];
  }

  @override
  Future<ModrinthVersion?> getVersionByFileHash(String sha1Hash) async {
    return null;
  }

  @override
  Future<ModrinthVersion?> getVersionById(String versionId) async {
    return null;
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
  }) {
    return onSearch(
      query: query,
      loader: loader,
      projectType: projectType,
      gameVersion: gameVersion,
      limit: limit,
      offset: offset,
      index: index,
    );
  }
}

class _FakeMappingRepository implements ModrinthMappingRepository {
  @override
  Future<Map<String, ModrinthMapping>> getAll() async => const {};

  @override
  Future<ModrinthMapping?> getByFileName(String fileName) async => null;

  @override
  Future<void> put(ModrinthMapping mapping) async {}

  @override
  Future<void> remove(String fileName) async {}
}

class _StubMinecraftVersionService extends MinecraftVersionService {
  @override
  Future<String?> detectVersionFromModsPath(String modsPath) async => '1.21.1';
}

class _StubMinecraftLoaderService extends MinecraftLoaderService {
  @override
  Future<DetectedLoader?> detectLoaderFromModsPath(String modsPath) async {
    return const DetectedLoader(loader: 'fabric', version: '0.16.0');
  }
}

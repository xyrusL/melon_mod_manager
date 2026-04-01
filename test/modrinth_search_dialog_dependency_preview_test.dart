import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  group('ModrinthSearchDialog dependency preview', () {
    testWidgets('shows required dependency section and total install CTA',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootProject = const ModrinthProject(
        id: 'root_project',
        slug: 'sodium',
        title: 'Sodium',
        description: 'Renderer',
      );
      final depVersion = _version(
        id: 'v_dep',
        projectId: 'dep_project',
        name: 'Fabric API',
      );
      final rootVersion = _version(
        id: 'v_root',
        projectId: 'root_project',
        name: 'Sodium',
        dependencies: const [
          ModrinthDependency(
            type: ModrinthDependencyType.required,
            projectId: 'dep_project',
          ),
        ],
      );
      final repository = _PreviewFakeModrinthRepository(
        searchResults: [rootProject],
        byVersionId: {'v_root': rootVersion},
        byProjectId: {
          'root_project': [rootVersion],
          'dep_project': [depVersion],
        },
      );

      await tester.pumpWidget(_buildDependencyTestApp(repository: repository));
      await tester.tap(find.text('Open Download'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review & Install'));
      await tester.pumpAndSettle();

      expect(
          find.text('Required mods to install automatically:'), findsOneWidget);
      expect(find.text('Fabric API'), findsOneWidget);
      expect(find.text('Install 1 + 1 Required'), findsOneWidget);
    });

    testWidgets(
        'hides required dependency section when nothing extra is needed',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootProject = const ModrinthProject(
        id: 'root_project',
        slug: 'sodium',
        title: 'Sodium',
        description: 'Renderer',
      );
      final rootVersion = _version(
        id: 'v_root',
        projectId: 'root_project',
        name: 'Sodium',
      );
      final repository = _PreviewFakeModrinthRepository(
        searchResults: [rootProject],
        byVersionId: {'v_root': rootVersion},
        byProjectId: {
          'root_project': [rootVersion],
        },
      );

      await tester.pumpWidget(_buildDependencyTestApp(repository: repository));
      await tester.tap(find.text('Open Download'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review & Install'));
      await tester.pumpAndSettle();

      expect(
        find.text('Required mods to install automatically:'),
        findsNothing,
      );
      expect(find.text('Install 1 Mod'), findsOneWidget);
    });

    testWidgets('shows blocking dependency issues and disables install',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final rootProject = const ModrinthProject(
        id: 'root_project',
        slug: 'sodium',
        title: 'Sodium',
        description: 'Renderer',
      );
      final rootVersion = _version(
        id: 'v_root',
        projectId: 'root_project',
        name: 'Sodium',
        dependencies: const [
          ModrinthDependency(type: ModrinthDependencyType.required),
        ],
      );
      final repository = _PreviewFakeModrinthRepository(
        searchResults: [rootProject],
        byVersionId: {'v_root': rootVersion},
        byProjectId: {
          'root_project': [rootVersion],
        },
      );

      await tester.pumpWidget(_buildDependencyTestApp(repository: repository));
      await tester.tap(find.text('Open Download'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review & Install'));
      await tester.pumpAndSettle();

      expect(find.text('Cannot install yet'), findsOneWidget);
      final installButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Install 1 Mod'),
      );
      expect(installButton.onPressed, isNull);
    });
  });
}

Widget _buildDependencyTestApp({
  required ModrinthRepository repository,
}) {
  return ProviderScope(
    overrides: [
      modrinthRepositoryProvider.overrideWithValue(repository),
      mappingRepositoryProvider
          .overrideWithValue(_PreviewFakeMappingRepository()),
      minecraftVersionServiceProvider.overrideWithValue(
        _PreviewStubMinecraftVersionService(),
      ),
      minecraftLoaderServiceProvider.overrideWithValue(
        _PreviewStubMinecraftLoaderService(),
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
                      modsPath: r'C:\dependency-test\mods',
                      targetPath: r'C:\dependency-test\mods',
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

ModrinthVersion _version({
  required String id,
  required String projectId,
  required String name,
  List<ModrinthDependency> dependencies = const [],
}) {
  return ModrinthVersion(
    id: id,
    projectId: projectId,
    name: name,
    versionNumber: '1.0.0',
    datePublished: DateTime(2025, 1, 1),
    loaders: const ['fabric'],
    gameVersions: const ['1.21.1'],
    files: const [
      ModrinthFile(
        fileName: 'mod.jar',
        url: 'https://cdn.modrinth.com/mod.jar',
        size: 123,
        primary: true,
      ),
    ],
    dependencies: dependencies,
  );
}

class _PreviewFakeModrinthRepository implements ModrinthRepository {
  _PreviewFakeModrinthRepository({
    required this.searchResults,
    required this.byVersionId,
    required this.byProjectId,
  });

  final List<ModrinthProject> searchResults;
  final Map<String, ModrinthVersion> byVersionId;
  final Map<String, List<ModrinthVersion>> byProjectId;

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
    final versions = byProjectId[projectId] ?? const [];
    return versions.isEmpty ? null : versions.first;
  }

  @override
  Future<ModrinthProject?> getProjectById(String projectId) async {
    for (final project in searchResults) {
      if (project.id == projectId) {
        return project;
      }
    }
    return null;
  }

  @override
  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String? loader,
    String? gameVersion,
  }) async {
    return byProjectId[projectId] ?? const [];
  }

  @override
  Future<ModrinthVersion?> getVersionByFileHash(String sha1Hash) async => null;

  @override
  Future<ModrinthVersion?> getVersionById(String versionId) async {
    return byVersionId[versionId];
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
    return searchResults;
  }
}

class _PreviewFakeMappingRepository implements ModrinthMappingRepository {
  @override
  Future<Map<String, ModrinthMapping>> getAll() async => const {};

  @override
  Future<ModrinthMapping?> getByFileName(String fileName) async => null;

  @override
  Future<void> put(ModrinthMapping mapping) async {}

  @override
  Future<void> remove(String fileName) async {}
}

class _PreviewStubMinecraftVersionService extends MinecraftVersionService {
  @override
  Future<String?> detectVersionFromModsPath(String modsPath) async => '1.21.1';
}

class _PreviewStubMinecraftLoaderService extends MinecraftLoaderService {
  @override
  Future<DetectedLoader?> detectLoaderFromModsPath(String modsPath) async {
    return const DetectedLoader(loader: 'fabric', version: '0.16.0');
  }
}

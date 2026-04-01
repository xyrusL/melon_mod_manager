import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/domain/entities/modrinth_mapping.dart';
import 'package:melon_mod/domain/entities/modrinth_project.dart';
import 'package:melon_mod/domain/entities/modrinth_version.dart';
import 'package:melon_mod/domain/repositories/modrinth_mapping_repository.dart';
import 'package:melon_mod/domain/repositories/modrinth_repository.dart';
import 'package:melon_mod/domain/services/dependency_resolver_service.dart';

void main() {
  group('DependencyResolverService', () {
    test('resolves required dependency and orders deps first', () async {
      final dep = _version(
        id: 'v_dep',
        projectId: 'dep_project',
        name: 'Fabric API',
      );
      final root = _version(
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

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_root': root},
          byProjectId: {
            'dep_project': [dep]
          },
        ),
        mappingRepository: _FakeMappingRepository(),
      );

      final plan = await service.resolveRequired(mainVersionId: 'v_root');

      expect(plan.hasBlockingIssues, isFalse);
      expect(plan.installQueueInOrder.map((m) => m.projectId).toList(), [
        'dep_project',
        'root_project',
      ]);
    });

    test('recursive dependency resolution deduplicates by project id',
        () async {
      final c = _version(id: 'v_c', projectId: 'c', name: 'C');
      final a = _version(
        id: 'v_a',
        projectId: 'a',
        name: 'A',
        dependencies: const [
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'c'),
        ],
      );
      final b = _version(
        id: 'v_b',
        projectId: 'b',
        name: 'B',
        dependencies: const [
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'c'),
        ],
      );
      final root = _version(
        id: 'v_root',
        projectId: 'root',
        name: 'Root',
        dependencies: const [
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'a'),
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'b'),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_root': root},
          byProjectId: {
            'a': [a],
            'b': [b],
            'c': [c],
          },
        ),
        mappingRepository: _FakeMappingRepository(),
      );

      final plan = await service.resolveRequired(mainVersionId: 'v_root');

      final queueIds =
          plan.installQueueInOrder.map((e) => e.projectId).toList();
      expect(queueIds.where((id) => id == 'c').length, 1);
      expect(queueIds.last, 'root');
      expect(queueIds.indexOf('c') < queueIds.indexOf('a'), isTrue);
      expect(queueIds.indexOf('c') < queueIds.indexOf('b'), isTrue);
    });

    test('cycle detection prevents infinite loop', () async {
      final a = _version(
        id: 'v_a',
        projectId: 'a',
        name: 'A',
        dependencies: const [
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'b'),
        ],
      );
      final b = _version(
        id: 'v_b',
        projectId: 'b',
        name: 'B',
        dependencies: const [
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'a'),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_a': a},
          byProjectId: {
            'b': [b],
          },
        ),
        mappingRepository: _FakeMappingRepository(),
      );

      final plan = await service.resolveRequired(mainVersionId: 'v_a');
      final queueIds = plan.installQueueInOrder.map((e) => e.projectId).toSet();
      expect(queueIds, {'a', 'b'});
    });

    test('blocks install on incompatible dependency', () async {
      final root = _version(
        id: 'v_root',
        projectId: 'root',
        name: 'Root',
        dependencies: const [
          ModrinthDependency(
            type: ModrinthDependencyType.incompatible,
            projectId: 'bad_dep',
          ),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository:
            _FakeModrinthRepository(byVersionId: {'v_root': root}),
        mappingRepository: _FakeMappingRepository(),
      );

      final plan = await service.resolveRequired(mainVersionId: 'v_root');
      expect(plan.hasBlockingIssues, isTrue);
      expect(plan.incompatibleReasons, isNotEmpty);
    });

    test('blocks install on required dependency missing project_id', () async {
      final root = _version(
        id: 'v_root',
        projectId: 'root',
        name: 'Root',
        dependencies: const [
          ModrinthDependency(type: ModrinthDependencyType.required)
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository:
            _FakeModrinthRepository(byVersionId: {'v_root': root}),
        mappingRepository: _FakeMappingRepository(),
      );

      final plan = await service.resolveRequired(mainVersionId: 'v_root');
      expect(plan.hasBlockingIssues, isTrue);
      expect(plan.unavailableRequired, isNotEmpty);
    });

    test('skips dependency already installed from mapping db', () async {
      final dep = _version(id: 'v_dep', projectId: 'dep', name: 'Dep');
      final root = _version(
        id: 'v_root',
        projectId: 'root',
        name: 'Root',
        dependencies: const [
          ModrinthDependency(
              type: ModrinthDependencyType.required, projectId: 'dep'),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_root': root},
          byProjectId: {
            'dep': [dep]
          },
        ),
        mappingRepository: _FakeMappingRepository(
          mappings: {
            'dep.jar': ModrinthMapping(
              jarFileName: 'dep.jar',
              projectId: 'dep',
              versionId: 'v_dep',
              installedAt: DateTime(2025),
            ),
          },
        ),
      );

      final plan = await service.resolveRequired(mainVersionId: 'v_root');
      expect(
          plan.installQueueInOrder.map((e) => e.projectId).toList(), ['root']);
    });

    test('preview lists one required dependency for selected project',
        () async {
      final dep = _version(
        id: 'v_dep',
        projectId: 'dep_project',
        name: 'Fabric API',
      );
      final root = _version(
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

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_root': root},
          byProjectId: {
            'root_project': [root],
            'dep_project': [dep],
          },
        ),
        mappingRepository: _FakeMappingRepository(),
      );

      final preview = await service.previewRequiredForProjects(
        projects: const [
          SelectedProjectPreview(id: 'root_project', title: 'Sodium'),
        ],
        loader: 'fabric',
        gameVersion: '1.21.1',
      );

      expect(preview.hasBlockingIssues, isFalse);
      expect(preview.requiredDependencies.map((item) => item.projectId), [
        'dep_project',
      ]);
    });

    test('preview deduplicates shared dependencies across selected mods',
        () async {
      final dep = _version(id: 'v_dep', projectId: 'dep_project', name: 'API');
      final a = _version(
        id: 'v_a',
        projectId: 'a_project',
        name: 'A',
        dependencies: const [
          ModrinthDependency(
            type: ModrinthDependencyType.required,
            projectId: 'dep_project',
          ),
        ],
      );
      final b = _version(
        id: 'v_b',
        projectId: 'b_project',
        name: 'B',
        dependencies: const [
          ModrinthDependency(
            type: ModrinthDependencyType.required,
            projectId: 'dep_project',
          ),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {
            'v_a': a,
            'v_b': b,
          },
          byProjectId: {
            'a_project': [a],
            'b_project': [b],
            'dep_project': [dep],
          },
        ),
        mappingRepository: _FakeMappingRepository(),
      );

      final preview = await service.previewRequiredForProjects(
        projects: const [
          SelectedProjectPreview(id: 'a_project', title: 'A'),
          SelectedProjectPreview(id: 'b_project', title: 'B'),
        ],
        loader: 'fabric',
        gameVersion: '1.21.1',
      );

      expect(preview.requiredDependencies.length, 1);
      expect(preview.requiredDependencies.first.projectId, 'dep_project');
    });

    test('preview excludes dependencies already installed', () async {
      final dep = _version(id: 'v_dep', projectId: 'dep_project', name: 'API');
      final root = _version(
        id: 'v_root',
        projectId: 'root_project',
        name: 'Root',
        dependencies: const [
          ModrinthDependency(
            type: ModrinthDependencyType.required,
            projectId: 'dep_project',
          ),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_root': root},
          byProjectId: {
            'root_project': [root],
            'dep_project': [dep],
          },
        ),
        mappingRepository: _FakeMappingRepository(
          mappings: {
            'dep.jar': ModrinthMapping(
              jarFileName: 'dep.jar',
              projectId: 'dep_project',
              versionId: 'v_dep',
              installedAt: DateTime(2025),
            ),
          },
        ),
      );

      final preview = await service.previewRequiredForProjects(
        projects: const [
          SelectedProjectPreview(id: 'root_project', title: 'Root'),
        ],
        loader: 'fabric',
        gameVersion: '1.21.1',
      );

      expect(preview.requiredDependencies, isEmpty);
    });

    test('preview surfaces blocking dependency issues before install',
        () async {
      final root = _version(
        id: 'v_root',
        projectId: 'root_project',
        name: 'Root',
        dependencies: const [
          ModrinthDependency(type: ModrinthDependencyType.required),
        ],
      );

      final service = DependencyResolverService(
        modrinthRepository: _FakeModrinthRepository(
          byVersionId: {'v_root': root},
          byProjectId: {
            'root_project': [root],
          },
        ),
        mappingRepository: _FakeMappingRepository(),
      );

      final preview = await service.previewRequiredForProjects(
        projects: const [
          SelectedProjectPreview(id: 'root_project', title: 'Root'),
        ],
        loader: 'fabric',
        gameVersion: '1.21.1',
      );

      expect(preview.hasBlockingIssues, isTrue);
      expect(preview.blockingIssues.first, contains('Root:'));
    });
  });
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

class _FakeModrinthRepository implements ModrinthRepository {
  _FakeModrinthRepository({
    this.byVersionId = const {},
    this.byProjectId = const {},
  });

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
    String? loader = 'fabric',
    String? gameVersion,
  }) async {
    final versions = byProjectId[projectId] ?? const [];
    if (versions.isEmpty) {
      return null;
    }
    return versions.first;
  }

  @override
  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String? loader = 'fabric',
    String? gameVersion,
  }) async {
    return byProjectId[projectId] ?? const [];
  }

  @override
  Future<List<ModrinthProject>> searchProjects(
    String query, {
    String? loader = 'fabric',
    String projectType = 'mod',
    String? gameVersion,
    int limit = 20,
    int offset = 0,
    String index = 'relevance',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ModrinthVersion?> getVersionById(String versionId) async {
    return byVersionId[versionId];
  }

  @override
  Future<ModrinthVersion?> getVersionByFileHash(String sha1Hash) {
    throw UnimplementedError();
  }

  @override
  Future<ModrinthProject?> getProjectById(String projectId) {
    throw UnimplementedError();
  }
}

class _FakeMappingRepository implements ModrinthMappingRepository {
  _FakeMappingRepository({this.mappings = const {}});

  final Map<String, ModrinthMapping> mappings;

  @override
  Future<Map<String, ModrinthMapping>> getAll() async => mappings;

  @override
  Future<ModrinthMapping?> getByFileName(String fileName) async =>
      mappings[fileName];

  @override
  Future<void> put(ModrinthMapping mapping) async {}

  @override
  Future<void> remove(String fileName) async {}
}

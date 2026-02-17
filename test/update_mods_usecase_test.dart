import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/domain/entities/mod_item.dart';
import 'package:melon_mod/domain/entities/modrinth_mapping.dart';
import 'package:melon_mod/domain/entities/modrinth_project.dart';
import 'package:melon_mod/domain/entities/modrinth_version.dart';
import 'package:melon_mod/domain/repositories/modrinth_mapping_repository.dart';
import 'package:melon_mod/domain/repositories/modrinth_repository.dart';
import 'package:melon_mod/domain/usecases/update_mods_usecase.dart';
import 'package:path/path.dart' as p;

void main() {
  group('UpdateModsUsecase', () {
    test('replaces old mapped jar and mapping when filename changes', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('melon_update_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final oldJar = File(p.join(tempDir.path, 'fabric-api-old.jar'));
      await oldJar.writeAsString('old');

      final latest = ModrinthVersion(
        id: 'v2',
        projectId: 'project_fabric_api',
        name: 'Fabric API',
        versionNumber: '2.0.0',
        datePublished: DateTime(2026, 2, 1),
        loaders: const ['fabric'],
        gameVersions: const ['1.21.1'],
        files: const [
          ModrinthFile(
            fileName: 'fabric-api-2.0.0.jar',
            url: 'https://cdn.modrinth.com/fabric-api-2.0.0.jar',
            size: 10,
            primary: true,
          ),
        ],
        dependencies: const [],
      );

      final mappingRepository = _FakeMappingRepository(
        initial: {
          'fabric-api-old.jar': ModrinthMapping(
            jarFileName: 'fabric-api-old.jar',
            projectId: 'project_fabric_api',
            versionId: 'v1',
            installedAt: DateTime(2025, 1, 1),
          ),
        },
      );
      final modrinthRepository = _FakeModrinthRepository(
        latestByProject: {'project_fabric_api': latest},
      );

      final usecase = UpdateModsUsecase(
        modrinthRepository: modrinthRepository,
        mappingRepository: mappingRepository,
      );

      final summary = await usecase.execute(
        modsPath: tempDir.path,
        mods: [
          ModItem(
            fileName: 'fabric-api-old.jar',
            filePath: oldJar.path,
            displayName: 'Fabric API',
            version: '1.0.0',
            modId: 'fabric-api',
            provider: ModProviderType.modrinth,
            lastModified: DateTime.now(),
            modrinthProjectId: 'project_fabric_api',
            modrinthVersionId: 'v1',
          ),
        ],
      );

      expect(summary.updated, 1);
      expect(summary.failed, 0);
      expect(await oldJar.exists(), isFalse);

      final newJar = File(p.join(tempDir.path, 'fabric-api-2.0.0.jar'));
      expect(await newJar.exists(), isTrue);

      final mappings = await mappingRepository.getAll();
      expect(mappings.containsKey('fabric-api-old.jar'), isFalse);
      expect(mappings.containsKey('fabric-api-2.0.0.jar'), isTrue);
      expect(mappings['fabric-api-2.0.0.jar']?.versionId, 'v2');

      final jars = await tempDir
          .list()
          .where(
              (e) => e is File && p.extension(e.path).toLowerCase() == '.jar')
          .cast<File>()
          .map((f) => p.basename(f.path))
          .toList();
      expect(jars, ['fabric-api-2.0.0.jar']);
    });

    test('overwrites existing filename without creating duplicate', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('melon_update_test_same_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final jarPath = p.join(tempDir.path, 'sodium.jar');
      final jar = File(jarPath);
      await jar.writeAsString('old-content');

      final latest = ModrinthVersion(
        id: 'v2',
        projectId: 'project_sodium',
        name: 'Sodium',
        versionNumber: '2.0.0',
        datePublished: DateTime(2026, 2, 1),
        loaders: const ['fabric'],
        gameVersions: const ['1.21.1'],
        files: const [
          ModrinthFile(
            fileName: 'sodium.jar',
            url: 'https://cdn.modrinth.com/sodium.jar',
            size: 10,
            primary: true,
          ),
        ],
        dependencies: const [],
      );

      final mappingRepository = _FakeMappingRepository(
        initial: {
          'sodium.jar': ModrinthMapping(
            jarFileName: 'sodium.jar',
            projectId: 'project_sodium',
            versionId: 'v1',
            installedAt: DateTime(2025, 1, 1),
          ),
        },
      );
      final modrinthRepository = _FakeModrinthRepository(
        latestByProject: {'project_sodium': latest},
      );

      final usecase = UpdateModsUsecase(
        modrinthRepository: modrinthRepository,
        mappingRepository: mappingRepository,
      );

      final summary = await usecase.execute(
        modsPath: tempDir.path,
        mods: [
          ModItem(
            fileName: 'sodium.jar',
            filePath: jar.path,
            displayName: 'Sodium',
            version: '1.0.0',
            modId: 'sodium',
            provider: ModProviderType.modrinth,
            lastModified: DateTime.now(),
            modrinthProjectId: 'project_sodium',
            modrinthVersionId: 'v1',
          ),
        ],
      );

      expect(summary.updated, 1);
      expect(summary.failed, 0);

      final contents = await jar.readAsString();
      expect(contents, contains('downloaded:sodium.jar'));

      final jars = await tempDir
          .list()
          .where(
              (e) => e is File && p.extension(e.path).toLowerCase() == '.jar')
          .cast<File>()
          .map((f) => p.basename(f.path))
          .toList();
      expect(jars, ['sodium.jar']);
    });
  });
}

class _FakeModrinthRepository implements ModrinthRepository {
  _FakeModrinthRepository({this.latestByProject = const {}});

  final Map<String, ModrinthVersion> latestByProject;

  @override
  Future<File> downloadVersionFile({
    required ModrinthFile file,
    required String targetPath,
  }) async {
    final out = File(targetPath);
    if (!await out.parent.exists()) {
      await out.parent.create(recursive: true);
    }
    await out.writeAsBytes(utf8.encode('downloaded:${file.fileName}'));
    return out;
  }

  @override
  Future<ModrinthVersion?> getLatestVersion(
    String projectId, {
    String? loader = 'fabric',
    String? gameVersion,
  }) async {
    return latestByProject[projectId];
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
  Future<ModrinthVersion?> getVersionById(String versionId) {
    throw UnimplementedError();
  }

  @override
  Future<ModrinthVersion?> getVersionByFileHash(String sha1Hash) {
    throw UnimplementedError();
  }

  @override
  Future<ModrinthProject?> getProjectById(String projectId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ModrinthVersion>> getProjectVersions(
    String projectId, {
    String? loader = 'fabric',
    String? gameVersion,
  }) {
    throw UnimplementedError();
  }
}

class _FakeMappingRepository implements ModrinthMappingRepository {
  _FakeMappingRepository({Map<String, ModrinthMapping> initial = const {}})
      : _mappings = Map<String, ModrinthMapping>.from(initial);

  final Map<String, ModrinthMapping> _mappings;

  @override
  Future<Map<String, ModrinthMapping>> getAll() async =>
      Map<String, ModrinthMapping>.from(_mappings);

  @override
  Future<ModrinthMapping?> getByFileName(String fileName) async =>
      _mappings[fileName];

  @override
  Future<void> put(ModrinthMapping mapping) async {
    _mappings[mapping.jarFileName] = mapping;
  }

  @override
  Future<void> remove(String fileName) async {
    _mappings.remove(fileName);
  }
}

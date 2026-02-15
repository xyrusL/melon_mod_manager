import '../entities/modrinth_version.dart';
import '../repositories/modrinth_mapping_repository.dart';
import '../repositories/modrinth_repository.dart';

class DependencyResolverService {
  DependencyResolverService({
    required ModrinthRepository modrinthRepository,
    required ModrinthMappingRepository mappingRepository,
  })  : _modrinthRepository = modrinthRepository,
        _mappingRepository = mappingRepository;

  final ModrinthRepository _modrinthRepository;
  final ModrinthMappingRepository _mappingRepository;

  Future<DependencyPlan> resolveRequired({
    required String mainVersionId,
    String? loader,
    String? gameVersion,
  }) async {
    final root = await _modrinthRepository.getVersionById(mainVersionId);
    if (root == null) {
      return const DependencyPlan(
        installQueueInOrder: [],
        optionalInfo: [],
        incompatibleReasons: ['Selected version no longer exists on Modrinth.'],
        unavailableRequired: [],
      );
    }

    final resolvedLoader =
        loader ?? (root.loaders.isNotEmpty ? root.loaders.first : 'fabric');
    final resolvedGameVersion = gameVersion ??
        (root.gameVersions.isNotEmpty ? root.gameVersions.first : null);

    final mappings = await _mappingRepository.getAll();
    final installedProjectIds = mappings.values.map((m) => m.projectId).toSet();

    final optionalInfo = <String>[];
    final incompatibleReasons = <String>[];
    final unavailableRequired = <String>[];
    final installQueue = <ResolvedMod>[];

    final visitedProjectIds = <String>{};
    final visitingProjectIds = <String>{};
    final queuedProjectIds = <String>{};

    Future<void> dfs(ModrinthVersion version, {required bool isMain}) async {
      final projectId = version.projectId;
      if (projectId.isEmpty) {
        incompatibleReasons.add('Version ${version.id} is missing project_id.');
        return;
      }

      if (visitingProjectIds.contains(projectId)) {
        return;
      }
      if (visitedProjectIds.contains(projectId)) {
        return;
      }

      visitingProjectIds.add(projectId);

      for (final dependency in version.dependencies) {
        switch (dependency.type) {
          case ModrinthDependencyType.optional:
            optionalInfo.add(
                _displayDependency('Optional dependency found', dependency));
            continue;
          case ModrinthDependencyType.incompatible:
            incompatibleReasons.add(
              _displayDependency(
                  'Incompatible dependency detected', dependency),
            );
            continue;
          case ModrinthDependencyType.embedded:
            continue;
          case ModrinthDependencyType.required:
            break;
        }

        final requiredProjectId = dependency.projectId;
        if (requiredProjectId == null || requiredProjectId.trim().isEmpty) {
          unavailableRequired.add(
              _displayDependency('Missing Modrinth dependency', dependency));
          continue;
        }

        if (installedProjectIds.contains(requiredProjectId)) {
          continue;
        }

        final selected = await _selectDependencyVersion(
          dependency,
          loader: resolvedLoader,
          gameVersion: resolvedGameVersion,
        );

        if (selected == null) {
          unavailableRequired.add(
            'No compatible version found for dependency project: $requiredProjectId',
          );
          continue;
        }

        await dfs(selected, isMain: false);
      }

      visitingProjectIds.remove(projectId);
      visitedProjectIds.add(projectId);

      if (isMain || !installedProjectIds.contains(projectId)) {
        if (!queuedProjectIds.contains(projectId)) {
          installQueue.add(
            ResolvedMod(projectId: projectId, version: version, isMain: isMain),
          );
          queuedProjectIds.add(projectId);
        }
      }
    }

    await dfs(root, isMain: true);

    return DependencyPlan(
      installQueueInOrder: installQueue,
      optionalInfo: optionalInfo,
      incompatibleReasons: incompatibleReasons,
      unavailableRequired: unavailableRequired,
    );
  }

  Future<List<ModrinthVersion>> resolveMainProjectVersions(
    String projectId, {
    required String loader,
    String? gameVersion,
  }) async {
    final versions = await _modrinthRepository.getProjectVersions(
      projectId,
      loader: loader,
      gameVersion: gameVersion,
    );
    versions.sort((a, b) => b.datePublished.compareTo(a.datePublished));
    return versions;
  }

  Future<ModrinthVersion?> _selectDependencyVersion(
    ModrinthDependency dependency, {
    required String loader,
    String? gameVersion,
  }) async {
    if (dependency.versionId != null && dependency.versionId!.isNotEmpty) {
      final exact =
          await _modrinthRepository.getVersionById(dependency.versionId!);
      if (exact != null &&
          _isCompatible(exact, loader: loader, gameVersion: gameVersion)) {
        return exact;
      }
    }

    final projectId = dependency.projectId;
    if (projectId == null || projectId.isEmpty) {
      return null;
    }

    final versions = await _modrinthRepository.getProjectVersions(
      projectId,
      loader: loader,
      gameVersion: gameVersion,
    );

    if (versions.isEmpty) {
      return null;
    }

    versions.sort((a, b) => b.datePublished.compareTo(a.datePublished));
    for (final version in versions) {
      if (_isCompatible(version, loader: loader, gameVersion: gameVersion)) {
        return version;
      }
    }

    return null;
  }

  bool _isCompatible(
    ModrinthVersion version, {
    required String loader,
    String? gameVersion,
  }) {
    final loaderMatches =
        version.loaders.isEmpty || version.loaders.contains(loader);
    final gameMatches = gameVersion == null ||
        gameVersion.isEmpty ||
        version.gameVersions.isEmpty ||
        version.gameVersions.contains(gameVersion);
    return loaderMatches && gameMatches;
  }

  String _displayDependency(String prefix, ModrinthDependency dependency) {
    final id = dependency.projectId ??
        dependency.versionId ??
        dependency.fileName ??
        'unknown';
    return '$prefix: $id';
  }
}

class DependencyPlan {
  const DependencyPlan({
    required this.installQueueInOrder,
    required this.optionalInfo,
    required this.incompatibleReasons,
    required this.unavailableRequired,
  });

  final List<ResolvedMod> installQueueInOrder;
  final List<String> optionalInfo;
  final List<String> incompatibleReasons;
  final List<String> unavailableRequired;

  bool get hasBlockingIssues =>
      incompatibleReasons.isNotEmpty || unavailableRequired.isNotEmpty;
}

class ResolvedMod {
  const ResolvedMod({
    required this.projectId,
    required this.version,
    required this.isMain,
  });

  final String projectId;
  final ModrinthVersion version;
  final bool isMain;

  String get displayName => version.name;
}

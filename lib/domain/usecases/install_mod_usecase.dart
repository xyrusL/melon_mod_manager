import '../entities/modrinth_project.dart';
import '../services/dependency_resolver_service.dart';
import 'install_queue_usecase.dart';

class InstallModUsecase {
  InstallModUsecase({
    required DependencyResolverService dependencyResolverService,
    required InstallQueueUsecase installQueueUsecase,
  })  : _dependencyResolverService = dependencyResolverService,
        _installQueueUsecase = installQueueUsecase;

  final DependencyResolverService _dependencyResolverService;
  final InstallQueueUsecase _installQueueUsecase;

  Future<InstallModResult> installFromProject({
    required ModrinthProject project,
    required String modsPath,
    required String loader,
    String? gameVersion,
    required ProgressCallback onProgress,
  }) async {
    await onProgress(
      const InstallProgress(
        stage: InstallProgressStage.resolving,
        current: 0,
        total: 0,
        message: 'Resolving dependencies...',
      ),
    );

    final latest = await _dependencyResolverService.resolveRequired(
      mainVersionId: await _resolveMainVersionId(
        project.id,
        loader: loader,
        gameVersion: gameVersion,
      ),
      loader: loader,
      gameVersion: gameVersion,
    );

    if (latest.hasBlockingIssues) {
      final blockingMessage = _buildBlockingMessage(latest);
      return InstallModResult(
        installed: false,
        message: blockingMessage,
        optionalInfo: latest.optionalInfo,
        installQueue: latest.installQueueInOrder,
      );
    }

    final plannedNames =
        latest.installQueueInOrder.map((e) => e.displayName).toList();
    await onProgress(
      InstallProgress(
        stage: InstallProgressStage.resolving,
        current: 0,
        total: plannedNames.length,
        message: plannedNames.isEmpty
            ? 'No installable files found.'
            : 'This mod requires additional mods. We will install automatically: '
                '${plannedNames.join(', ')}',
      ),
    );

    await _installQueueUsecase.executeInstallQueue(
      latest,
      modsPath: modsPath,
      onProgress: onProgress,
    );

    return InstallModResult(
      installed: true,
      message: 'Installed ${project.title} with required dependencies.',
      optionalInfo: latest.optionalInfo,
      installQueue: latest.installQueueInOrder,
    );
  }

  Future<String> _resolveMainVersionId(
    String projectId, {
    required String loader,
    String? gameVersion,
  }) async {
    final versions =
        await _dependencyResolverService.resolveMainProjectVersions(
      projectId,
      loader: loader,
      gameVersion: gameVersion,
    );
    if (versions.isEmpty) {
      throw Exception('No compatible version found for this project.');
    }
    return versions.first.id;
  }

  String _buildBlockingMessage(DependencyPlan plan) {
    if (plan.incompatibleReasons.isNotEmpty) {
      return 'Installation blocked by incompatible dependencies:\n${plan.incompatibleReasons.join('\n')}';
    }
    if (plan.unavailableRequired.isNotEmpty) {
      return 'This mod requires dependencies that are not available on Modrinth. '
          'Please install manually:\n${plan.unavailableRequired.join('\n')}';
    }
    return 'Installation blocked due to dependency resolution errors.';
  }
}

class InstallModResult {
  const InstallModResult({
    required this.installed,
    required this.message,
    required this.optionalInfo,
    required this.installQueue,
  });

  final bool installed;
  final String message;
  final List<String> optionalInfo;
  final List<ResolvedMod> installQueue;
}

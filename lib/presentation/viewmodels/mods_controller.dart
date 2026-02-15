import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/error_reporter.dart';
import '../../core/providers.dart';
import '../../data/models/mod_metadata_result.dart';
import '../../data/services/file_install_service.dart';
import '../../data/services/mod_scanner_service.dart';
import '../../domain/entities/mod_item.dart';
import '../../domain/entities/modrinth_mapping.dart';
import '../../domain/entities/modrinth_project.dart';
import '../../domain/repositories/modrinth_mapping_repository.dart';
import '../../domain/repositories/modrinth_repository.dart';
import '../../domain/usecases/install_mod_usecase.dart';
import '../../domain/usecases/install_queue_usecase.dart';
import '../../domain/usecases/update_mods_usecase.dart';

enum ModFilter { all, modrinth, external, updatable }

enum ProjectInstallState {
  notInstalled,
  installed,
  updateAvailable,
  installedUntracked,
}

class ProjectInstallInfo {
  const ProjectInstallInfo({
    required this.state,
    this.installedVersionId,
    this.latestVersionId,
    this.installedVersionNumber,
    this.latestVersionNumber,
  });

  final ProjectInstallState state;
  final String? installedVersionId;
  final String? latestVersionId;
  final String? installedVersionNumber;
  final String? latestVersionNumber;
}

class ModsState {
  const ModsState({
    this.mods = const [],
    this.isScanning = false,
    this.isBusy = false,
    this.filter = ModFilter.all,
    this.selectedFiles = const <String>{},
    this.scanProcessed = 0,
    this.scanTotal = 0,
    this.infoMessage,
    this.errorMessage,
  });

  final List<ModItem> mods;
  final bool isScanning;
  final bool isBusy;
  final ModFilter filter;
  final Set<String> selectedFiles;
  final int scanProcessed;
  final int scanTotal;
  final String? infoMessage;
  final String? errorMessage;

  List<ModItem> filteredMods() {
    return mods.where((mod) {
      final matchesFilter = switch (filter) {
        ModFilter.all => true,
        ModFilter.modrinth => mod.provider == ModProviderType.modrinth,
        ModFilter.external => mod.provider == ModProviderType.external,
        ModFilter.updatable => mod.isUpdatable,
      };

      return matchesFilter;
    }).toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
  }

  ModsState copyWith({
    List<ModItem>? mods,
    bool? isScanning,
    bool? isBusy,
    ModFilter? filter,
    Set<String>? selectedFiles,
    int? scanProcessed,
    int? scanTotal,
    String? infoMessage,
    String? errorMessage,
  }) {
    return ModsState(
      mods: mods ?? this.mods,
      isScanning: isScanning ?? this.isScanning,
      isBusy: isBusy ?? this.isBusy,
      filter: filter ?? this.filter,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      scanProcessed: scanProcessed ?? this.scanProcessed,
      scanTotal: scanTotal ?? this.scanTotal,
      infoMessage: infoMessage,
      errorMessage: errorMessage,
    );
  }
}

final modsControllerProvider = StateNotifierProvider<ModsController, ModsState>(
  (ref) {
    return ModsController(
      scanner: ref.watch(modScannerServiceProvider),
      mappingRepository: ref.watch(mappingRepositoryProvider),
      modrinthRepository: ref.watch(modrinthRepositoryProvider),
      installModUsecase: ref.watch(installModUsecaseProvider),
      updateModsUsecase: ref.watch(updateModsUsecaseProvider),
      fileInstallService: ref.watch(fileInstallServiceProvider),
      errorReporter: ErrorReporter(),
    );
  },
);

class ModsController extends StateNotifier<ModsState> {
  ModsController({
    required ModScannerService scanner,
    required ModrinthMappingRepository mappingRepository,
    required ModrinthRepository modrinthRepository,
    required InstallModUsecase installModUsecase,
    required UpdateModsUsecase updateModsUsecase,
    required FileInstallService fileInstallService,
    required ErrorReporter errorReporter,
  })  : _scanner = scanner,
        _mappingRepository = mappingRepository,
        _modrinthRepository = modrinthRepository,
        _installModUsecase = installModUsecase,
        _updateModsUsecase = updateModsUsecase,
        _fileInstallService = fileInstallService,
        _errorReporter = errorReporter,
        super(const ModsState());

  final ModScannerService _scanner;
  final ModrinthMappingRepository _mappingRepository;
  final ModrinthRepository _modrinthRepository;
  final InstallModUsecase _installModUsecase;
  final UpdateModsUsecase _updateModsUsecase;
  final FileInstallService _fileInstallService;
  final ErrorReporter _errorReporter;

  ScanCancellationToken? _scanToken;

  Future<void> loadMods(String modsPath) async {
    _scanToken?.cancel();
    final token = ScanCancellationToken();
    _scanToken = token;

    state = state.copyWith(
      isScanning: true,
      scanProcessed: 0,
      scanTotal: 0,
      selectedFiles: const <String>{},
      errorMessage: null,
      infoMessage: null,
      mods: const [],
    );

    try {
      final stream = await _scanner.scanFolder(
        modsPath,
        cancellationToken: token,
      );
      final loaded = <ModItem>[];

      await for (final update in stream) {
        final mod = await _toModItem(update.metadata);
        loaded.add(mod);

        if (update.processed % 8 == 0 || update.processed == update.total) {
          state = state.copyWith(
            mods: List<ModItem>.unmodifiable(loaded),
            scanProcessed: update.processed,
            scanTotal: update.total,
            isScanning: update.processed != update.total,
          );
        }
      }

      state = state.copyWith(
        mods: List<ModItem>.unmodifiable(loaded),
        isScanning: false,
      );
    } catch (error) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  void setFilter(ModFilter filter) {
    state = state.copyWith(
      filter: filter,
      errorMessage: null,
      infoMessage: null,
    );
  }

  void toggleModSelection(String fileName, bool selected) {
    final next = Set<String>.from(state.selectedFiles);
    if (selected) {
      next.add(fileName);
    } else {
      next.remove(fileName);
    }
    state = state.copyWith(selectedFiles: next);
  }

  void toggleSelectAllVisible(List<ModItem> visibleMods, bool selected) {
    final next = Set<String>.from(state.selectedFiles);
    for (final mod in visibleMods) {
      if (selected) {
        next.add(mod.fileName);
      } else {
        next.remove(mod.fileName);
      }
    }
    state = state.copyWith(selectedFiles: next);
  }

  void clearMessages() {
    state = state.copyWith(infoMessage: null, errorMessage: null);
  }

  Future<List<ModrinthProject>> searchModrinth(
    String query, {
    String loader = 'fabric',
    String? gameVersion,
    int limit = 20,
    int offset = 0,
    String index = 'relevance',
  }) {
    return _modrinthRepository.searchProjects(
      query,
      loader: loader,
      gameVersion: gameVersion,
      limit: limit,
      offset: offset,
      index: index,
    );
  }

  Future<List<ModrinthProject>> loadPopularClientMods({
    String loader = 'fabric',
    String? gameVersion,
    int limit = 30,
    int offset = 0,
  }) {
    return _modrinthRepository.searchProjects(
      '',
      loader: loader,
      gameVersion: gameVersion,
      limit: limit,
      offset: offset,
      index: 'downloads',
    );
  }

  Future<InstallModResult> installFromModrinth({
    required String modsPath,
    required ModrinthProject project,
    required String loader,
    String? gameVersion,
    required ProgressCallback onProgress,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final result = await _installModUsecase.installFromProject(
        project: project,
        modsPath: modsPath,
        loader: loader,
        gameVersion: gameVersion,
        onProgress: onProgress,
      );
      final optional = result.optionalInfo.isEmpty
          ? ''
          : '\n${result.optionalInfo.take(3).join('\n')}';
      state = state.copyWith(
        isBusy: false,
        infoMessage: '${result.message}$optional',
      );
      if (!result.installed) {
        await onProgress(
          InstallProgress(
            stage: InstallProgressStage.error,
            current: 0,
            total: 0,
            message: result.message,
          ),
        );
        return result;
      }
      await loadMods(modsPath);
      return result;
    } catch (error) {
      final message = _errorReporter.toUserMessage(error);
      await onProgress(
        InstallProgress(
          stage: InstallProgressStage.error,
          current: 0,
          total: 0,
          message: message,
        ),
      );
      state = state.copyWith(
        isBusy: false,
        errorMessage: message,
      );
      return const InstallModResult(
        installed: false,
        message: 'Install failed due to an unexpected error.',
        optionalInfo: [],
        installQueue: [],
      );
    }
  }

  Future<Map<String, ProjectInstallInfo>> loadProjectInstallInfo({
    required List<ModrinthProject> projects,
    required String loader,
    String? gameVersion,
  }) async {
    final mappings = await _mappingRepository.getAll();

    final byProjectId = <String, List<ModrinthMapping>>{};
    for (final mapping in mappings.values) {
      byProjectId.putIfAbsent(mapping.projectId, () => []).add(mapping);
    }

    final result = <String, ProjectInstallInfo>{};
    final futures = projects.map((project) async {
      final projectMappings = byProjectId[project.id];
      if (projectMappings == null || projectMappings.isEmpty) {
        final untrackedInstalled = _isLikelyInstalledLocally(project);
        if (untrackedInstalled) {
          result[project.id] = const ProjectInstallInfo(
            state: ProjectInstallState.installedUntracked,
          );
          return;
        }
        result[project.id] = const ProjectInstallInfo(
          state: ProjectInstallState.notInstalled,
        );
        return;
      }

      projectMappings.sort((a, b) => b.installedAt.compareTo(a.installedAt));
      final latestInstalled = projectMappings.first;
      final installedVersion =
          await _modrinthRepository.getVersionById(latestInstalled.versionId);

      final latestVersion = await _modrinthRepository.getLatestVersion(
        project.id,
        loader: loader,
        gameVersion: gameVersion,
      );

      if (latestVersion == null ||
          latestVersion.id == latestInstalled.versionId) {
        result[project.id] = ProjectInstallInfo(
          state: ProjectInstallState.installed,
          installedVersionId: latestInstalled.versionId,
          latestVersionId: latestVersion?.id,
          installedVersionNumber: installedVersion?.versionNumber,
          latestVersionNumber: latestVersion?.versionNumber,
        );
      } else {
        result[project.id] = ProjectInstallInfo(
          state: ProjectInstallState.updateAvailable,
          installedVersionId: latestInstalled.versionId,
          latestVersionId: latestVersion.id,
          installedVersionNumber: installedVersion?.versionNumber,
          latestVersionNumber: latestVersion.versionNumber,
        );
      }
    });

    await Future.wait(futures);
    return result;
  }

  bool _isLikelyInstalledLocally(ModrinthProject project) {
    final projectSlug = _canonical(project.slug);
    final projectTitle = _canonical(project.title);

    for (final mod in state.mods) {
      final modId = _canonical(mod.modId);
      final modName = _canonical(mod.displayName);
      final fileName = _canonical(mod.fileName.replaceAll('.jar', ''));

      final slugMatch = projectSlug.isNotEmpty &&
          (modId == projectSlug ||
              modName == projectSlug ||
              fileName == projectSlug);
      final titleMatch = projectTitle.isNotEmpty &&
          (modName == projectTitle || modId == projectTitle);

      if (slugMatch || titleMatch) {
        return true;
      }
    }
    return false;
  }

  String _canonical(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> installExternalFiles({
    required String modsPath,
    required List<String> sourcePaths,
    required Future<ConflictResolution> Function(String fileName) onConflict,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final results = await _fileInstallService.installJarFiles(
        modsFolderPath: modsPath,
        sourcePaths: sourcePaths,
        onConflict: onConflict,
      );

      var installedCount = 0;
      for (final result in results) {
        if (result.success) {
          installedCount++;
          if (result.installedFileName != null) {
            await _mappingRepository.remove(result.installedFileName!);
          }
        }
      }

      state = state.copyWith(
        isBusy: false,
        infoMessage: 'Installed $installedCount external mod(s).',
      );
      await loadMods(modsPath);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<void> checkForUpdates(String modsPath) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final modsToCheck = state.mods;
      if (modsToCheck.isEmpty) {
        state = state.copyWith(
          isBusy: false,
          infoMessage: 'No mods available for update.',
        );
        return;
      }

      final summary = await _updateModsUsecase.execute(
        modsPath: modsPath,
        mods: modsToCheck,
      );
      final message = _buildUpdateMessage(summary);
      state = state.copyWith(isBusy: false, infoMessage: message);
      await loadMods(modsPath);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<void> deleteSelectedMods(String modsPath) async {
    final selected = state.mods
        .where((mod) => state.selectedFiles.contains(mod.fileName))
        .toList();

    if (selected.isEmpty) {
      state = state.copyWith(infoMessage: 'No mods selected for deletion.');
      return;
    }

    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    var deleted = 0;
    var failed = 0;

    for (final mod in selected) {
      try {
        final file = File(mod.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _mappingRepository.remove(mod.fileName);
        deleted++;
      } catch (_) {
        failed++;
      }
    }

    final message = failed == 0
        ? 'Deleted $deleted mod(s).'
        : 'Deleted $deleted mod(s), failed to delete $failed.';

    state = state.copyWith(
      isBusy: false,
      infoMessage: message,
      selectedFiles: const <String>{},
    );

    await loadMods(modsPath);
  }

  String _buildUpdateMessage(UpdateSummary summary) {
    final parts = <String>[
      'Checked ${summary.totalChecked} mod(s)',
      '${summary.updated} updated',
      '${summary.alreadyLatest} up to date',
      '${summary.externalSkipped} not from Modrinth',
      '${summary.failed} failed',
    ];

    final base = parts.join(' | ');
    if (summary.notes.isEmpty) {
      return base;
    }
    return '$base\n${summary.notes.first}';
  }

  Future<ModItem> _toModItem(ModMetadataResult metadata) async {
    final mapping = await _mappingRepository.getByFileName(metadata.fileName);
    return ModItem(
      fileName: metadata.fileName,
      filePath: metadata.filePath,
      displayName: metadata.name,
      version: metadata.version,
      modId: metadata.modId,
      provider:
          mapping == null ? ModProviderType.external : ModProviderType.modrinth,
      lastModified: metadata.lastModified,
      iconCachePath: metadata.iconCachePath,
      modrinthProjectId: mapping?.projectId,
      modrinthVersionId: mapping?.versionId,
    );
  }
}

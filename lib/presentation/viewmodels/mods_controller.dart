import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../core/error_reporter.dart';
import '../../core/providers.dart';
import '../../data/models/mod_metadata_result.dart';
import '../../data/services/file_install_service.dart';
import '../../data/services/minecraft_loader_service.dart';
import '../../data/services/mod_pack_service.dart';
import '../../data/services/minecraft_version_service.dart';
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

typedef UpdateCheckProgressCallback = void Function(
  int processed,
  int total,
  String message,
);

class PendingModUpdate {
  const PendingModUpdate({
    required this.mod,
    this.currentVersion,
    this.latestVersion,
  });

  final ModItem mod;
  final String? currentVersion;
  final String? latestVersion;
}

class UpdateCheckPreview {
  const UpdateCheckPreview({
    required this.selectedOnly,
    required this.totalChecked,
    required this.updates,
    required this.alreadyLatest,
    required this.externalOrUnknown,
    required this.failed,
    required this.notes,
  });

  final bool selectedOnly;
  final int totalChecked;
  final List<PendingModUpdate> updates;
  final int alreadyLatest;
  final int externalOrUnknown;
  final int failed;
  final List<String> notes;
}

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
      modPackService: ref.watch(modPackServiceProvider),
      minecraftVersionService: ref.watch(minecraftVersionServiceProvider),
      minecraftLoaderService: ref.watch(minecraftLoaderServiceProvider),
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
    required ModPackService modPackService,
    required MinecraftVersionService minecraftVersionService,
    required MinecraftLoaderService minecraftLoaderService,
    required ErrorReporter errorReporter,
  })  : _scanner = scanner,
        _mappingRepository = mappingRepository,
        _modrinthRepository = modrinthRepository,
        _installModUsecase = installModUsecase,
        _updateModsUsecase = updateModsUsecase,
        _fileInstallService = fileInstallService,
        _modPackService = modPackService,
        _minecraftVersionService = minecraftVersionService,
        _minecraftLoaderService = minecraftLoaderService,
        _errorReporter = errorReporter,
        super(const ModsState());

  final ModScannerService _scanner;
  final ModrinthMappingRepository _mappingRepository;
  final ModrinthRepository _modrinthRepository;
  final InstallModUsecase _installModUsecase;
  final UpdateModsUsecase _updateModsUsecase;
  final FileInstallService _fileInstallService;
  final ModPackService _modPackService;
  final MinecraftVersionService _minecraftVersionService;
  final MinecraftLoaderService _minecraftLoaderService;
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
    final currentModFiles = state.mods.map((mod) => mod.fileName).toSet();

    final byProjectId = <String, List<ModrinthMapping>>{};
    for (final mapping in mappings.values) {
      if (!currentModFiles.contains(mapping.jarFileName)) {
        continue;
      }
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

  Future<void> exportModsToZip({
    required String modsPath,
    required String zipPath,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final result = await _modPackService.exportModsToZip(
        modsPath: modsPath,
        zipPath: zipPath,
      );
      state = state.copyWith(
        isBusy: false,
        infoMessage:
            'Exported ${result.exportedCount} mod(s) to ${result.zipPath}.',
      );
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<void> importModsFromZip({
    required String modsPath,
    required String zipPath,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final installedSnapshot = state.mods
          .map(
            (mod) => InstalledModSnapshot(
              fileName: mod.fileName,
              filePath: mod.filePath,
              modId: mod.modId,
              version: mod.version,
            ),
          )
          .toList();

      final result = await _modPackService.importModsFromZip(
        modsPath: modsPath,
        zipPath: zipPath,
        installedMods: installedSnapshot,
      );

      final mappingRemovals = <String>{
        ...result.touchedFileNames,
        ...result.removedFileNames,
      };
      for (final fileName in mappingRemovals) {
        await _mappingRepository.remove(fileName);
      }

      final sourceLabel =
          result.importedFromMelonPack ? 'Melon mod pack' : 'Zip archive';
      final summary =
          '$sourceLabel import: ${result.jarEntriesFound} jar(s) scanned | '
          '${result.installed} installed | ${result.updated} updated | '
          '${result.renamed} renamed | ${result.skippedSameVersion} same-version skipped | '
          '${result.skippedOlderVersion} older-version skipped | '
          '${result.skippedIdenticalFile} identical skipped | ${result.failed} failed';
      final message =
          result.notes.isEmpty ? summary : '$summary\n${result.notes.first}';

      state = state.copyWith(
        isBusy: false,
        infoMessage: message,
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
      final selectedMods = state.mods
          .where((mod) => state.selectedFiles.contains(mod.fileName))
          .toList();
      final checkSelectedOnly = selectedMods.isNotEmpty;
      final modsToCheck = checkSelectedOnly ? selectedMods : state.mods;
      if (modsToCheck.isEmpty) {
        state = state.copyWith(
          isBusy: false,
          infoMessage: 'No mods available for update.',
        );
        return;
      }

      final context = await _resolveUpdateContext(modsPath);
      final summary = await _updateModsUsecase.execute(
        modsPath: modsPath,
        mods: modsToCheck,
        loader: context.loader,
        gameVersion: context.gameVersion,
      );
      final message = _buildUpdateMessage(
        summary,
        selectedOnly: checkSelectedOnly,
      );
      state = state.copyWith(isBusy: false, infoMessage: message);
      await loadMods(modsPath);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<UpdateCheckPreview> checkForUpdatesPreview({
    required String modsPath,
    UpdateCheckProgressCallback? onProgress,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final selectedMods = state.mods
          .where((mod) => state.selectedFiles.contains(mod.fileName))
          .toList();
      final selectedOnly = selectedMods.isNotEmpty;
      final modsToCheck = selectedOnly ? selectedMods : state.mods;

      if (modsToCheck.isEmpty) {
        return const UpdateCheckPreview(
          selectedOnly: false,
          totalChecked: 0,
          updates: [],
          alreadyLatest: 0,
          externalOrUnknown: 0,
          failed: 0,
          notes: [],
        );
      }

      final updates = <PendingModUpdate>[];
      final notes = <String>[];
      var alreadyLatest = 0;
      var externalOrUnknown = 0;
      var failed = 0;
      final total = modsToCheck.length;
      final context = await _resolveUpdateContext(modsPath);

      for (var i = 0; i < modsToCheck.length; i++) {
        final mod = modsToCheck[i];
        onProgress?.call(
          i + 1,
          total,
          'Checking ${mod.displayName}...',
        );
        // Keep progress readable for users (avoid big visual jumps like 1 -> 7).
        await Future<void>.delayed(const Duration(milliseconds: 28));

        if (mod.provider != ModProviderType.modrinth) {
          externalOrUnknown++;
          if (notes.length < 6) {
            notes.add('${mod.displayName}: not from Modrinth.');
          }
          continue;
        }

        final mapping = await _mappingRepository.getByFileName(mod.fileName);
        if (mapping == null) {
          externalOrUnknown++;
          if (notes.length < 6) {
            notes.add('${mod.displayName}: no Modrinth mapping found.');
          }
          continue;
        }

        try {
          final current = await _modrinthRepository.getVersionById(
            mapping.versionId,
          );
          final latest = await _modrinthRepository.getLatestVersion(
            mapping.projectId,
            loader: context.loader,
            gameVersion: context.gameVersion,
          );

          if (latest == null || latest.id == mapping.versionId) {
            alreadyLatest++;
            continue;
          }

          updates.add(
            PendingModUpdate(
              mod: mod,
              currentVersion: current?.versionNumber,
              latestVersion: latest.versionNumber,
            ),
          );
        } catch (error) {
          failed++;
          if (notes.length < 6) {
            notes.add('${mod.displayName}: $error');
          }
        }
      }

      return UpdateCheckPreview(
        selectedOnly: selectedOnly,
        totalChecked: total,
        updates: List<PendingModUpdate>.unmodifiable(updates),
        alreadyLatest: alreadyLatest,
        externalOrUnknown: externalOrUnknown,
        failed: failed,
        notes: List<String>.unmodifiable(notes),
      );
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<UpdateSummary> runUpdatesForMods({
    required String modsPath,
    required List<ModItem> mods,
    required bool selectedOnly,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final context = await _resolveUpdateContext(modsPath);
      final summary = await _updateModsUsecase.execute(
        modsPath: modsPath,
        mods: mods,
        loader: context.loader,
        gameVersion: context.gameVersion,
      );
      final message = _buildUpdateMessage(
        summary,
        selectedOnly: selectedOnly,
      );
      state = state.copyWith(isBusy: false, infoMessage: message);
      await loadMods(modsPath);
      return summary;
    } catch (error) {
      final message = _errorReporter.toUserMessage(error);
      state = state.copyWith(isBusy: false, errorMessage: message);
      rethrow;
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

  String _buildUpdateMessage(
    UpdateSummary summary, {
    required bool selectedOnly,
  }) {
    if (selectedOnly && summary.totalChecked == 1) {
      final modName = _firstOrNull(summary.updatedMods) ??
          _firstOrNull(summary.alreadyLatestMods) ??
          _firstOrNull(summary.externalSkippedMods) ??
          _firstOrNull(summary.failedMods) ??
          'Selected mod';

      if (summary.updated == 1) {
        return '$modName was updated successfully.';
      }
      if (summary.alreadyLatest == 1) {
        return '$modName is already on the latest compatible version.';
      }
      if (summary.externalSkipped == 1) {
        return '$modName cannot be updated automatically because it is not from Modrinth.';
      }
      if (summary.failed == 1) {
        final detail = summary.notes.isEmpty ? '' : '\n${summary.notes.first}';
        return 'Failed to update $modName.$detail';
      }
    }

    final parts = <String>[
      'Checked ${summary.totalChecked} mod(s)',
      '${summary.updated} updated',
      '${summary.alreadyLatest} up to date',
      '${summary.externalSkipped} not from Modrinth',
      '${summary.failed} failed',
    ];

    final scope = selectedOnly ? 'Selected mods' : 'All mods';
    final base = '$scope: ${parts.join(' | ')}';
    if (summary.notes.isEmpty) {
      return base;
    }
    return '$base\n${summary.notes.first}';
  }

  String? _firstOrNull(List<String> values) {
    if (values.isEmpty) {
      return null;
    }
    return values.first;
  }

  Future<_UpdateContext> _resolveUpdateContext(String modsPath) async {
    final detectedVersion =
        await _minecraftVersionService.detectVersionFromModsPath(modsPath);
    final detectedLoader =
        await _minecraftLoaderService.detectLoaderFromModsPath(modsPath);
    return _UpdateContext(
      loader: detectedLoader?.loader ?? 'fabric',
      gameVersion: detectedVersion,
    );
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

class _UpdateContext {
  const _UpdateContext({
    required this.loader,
    required this.gameVersion,
  });

  final String loader;
  final String? gameVersion;
}

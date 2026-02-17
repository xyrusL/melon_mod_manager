import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../core/error_reporter.dart';
import '../../core/providers.dart';
import '../../data/models/mod_metadata_result.dart';
import '../../data/services/content_icon_service.dart';
import '../../data/services/content_path_service.dart';
import '../../data/services/content_scanner_service.dart';
import '../../data/services/file_install_service.dart';
import '../../data/services/file_hash_service.dart';
import '../../data/services/minecraft_loader_service.dart';
import '../../data/services/mod_pack_service.dart';
import '../../data/services/minecraft_version_service.dart';
import '../../data/services/mod_scanner_service.dart';
import '../../domain/entities/content_type.dart';
import '../../domain/entities/mod_item.dart';
import '../../domain/entities/modrinth_mapping.dart';
import '../../domain/entities/modrinth_project.dart';
import '../../domain/entities/modrinth_version.dart';
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
    this.contentType = ContentType.mod,
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
  final ContentType contentType;
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
    ContentType? contentType,
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
      contentType: contentType ?? this.contentType,
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
      contentScanner: ref.watch(contentScannerServiceProvider),
      contentIconService: ref.watch(contentIconServiceProvider),
      fileHashService: ref.watch(fileHashServiceProvider),
      contentPathService: ref.watch(contentPathServiceProvider),
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
    required ContentScannerService contentScanner,
    required ContentIconService contentIconService,
    required FileHashService fileHashService,
    required ContentPathService contentPathService,
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
        _contentScanner = contentScanner,
        _contentIconService = contentIconService,
        _fileHashService = fileHashService,
        _contentPathService = contentPathService,
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
  final ContentScannerService _contentScanner;
  final ContentIconService _contentIconService;
  final FileHashService _fileHashService;
  final ContentPathService _contentPathService;
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
  final Map<String, List<ModItem>> _contentCache = {};

  Future<void> loadContent({
    required String modsPath,
    required ContentType contentType,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(contentType: contentType);
    final key = _cacheKey(modsPath, contentType);
    if (!forceRefresh) {
      final cached = _contentCache[key];
      if (cached != null) {
        state = state.copyWith(
          mods: List<ModItem>.unmodifiable(cached),
          isScanning: false,
          scanProcessed: cached.length,
          scanTotal: cached.length,
          selectedFiles: const <String>{},
          errorMessage: null,
        );
        return;
      }
    }
    if (contentType == ContentType.mod) {
      await loadMods(modsPath);
      return;
    }
    await _loadPackContent(
      modsPath: modsPath,
      contentType: contentType,
    );
  }

  Future<void> warmUpContentCaches(String modsPath) async {
    for (final type in ContentType.values) {
      final key = _cacheKey(modsPath, type);
      if (_contentCache.containsKey(key)) {
        continue;
      }

      try {
        if (type == ContentType.mod) {
          final mods = await _scanModsContent(modsPath);
          _contentCache[key] = List<ModItem>.unmodifiable(mods);
          continue;
        }
        final packs = await _scanPackContent(
          modsPath: modsPath,
          contentType: type,
        );
        _contentCache[key] = List<ModItem>.unmodifiable(packs);
      } catch (_) {
        // Silent warm-up only; ignore failures.
      }
    }
  }

  Future<void> loadMods(String modsPath) async {
    _scanToken?.cancel();
    final token = ScanCancellationToken();
    _scanToken = token;

    state = state.copyWith(
      contentType: ContentType.mod,
      isScanning: true,
      scanProcessed: 0,
      scanTotal: 0,
      selectedFiles: const <String>{},
      errorMessage: null,
      infoMessage: null,
      mods: const [],
    );

    try {
      final loaded = await _scanModsContent(
        modsPath,
        cancellationToken: token,
        onProgress: (processed, total) {
          if (processed % 8 == 0 || processed == total) {
            state = state.copyWith(
              scanProcessed: processed,
              scanTotal: total,
              isScanning: processed != total,
            );
          }
        },
      );

      state = state.copyWith(
        mods: List<ModItem>.unmodifiable(loaded),
        isScanning: false,
      );
      _contentCache[_cacheKey(modsPath, ContentType.mod)] =
          List<ModItem>.unmodifiable(loaded);
    } catch (error) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<void> _loadPackContent({
    required String modsPath,
    required ContentType contentType,
  }) async {
    _scanToken?.cancel();
    _scanToken = null;
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
      final loaded = await _scanPackContent(
        modsPath: modsPath,
        contentType: contentType,
      );
      state = state.copyWith(
        mods: List<ModItem>.unmodifiable(loaded),
        isScanning: false,
      );
      _contentCache[_cacheKey(modsPath, contentType)] =
          List<ModItem>.unmodifiable(loaded);
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
    String? loader = 'fabric',
    String projectType = 'mod',
    String? gameVersion,
    int limit = 20,
    int offset = 0,
    String index = 'relevance',
  }) {
    return _modrinthRepository.searchProjects(
      query,
      loader: loader,
      projectType: projectType,
      gameVersion: gameVersion,
      limit: limit,
      offset: offset,
      index: index,
    );
  }

  Future<List<ModrinthProject>> loadPopularClientMods({
    String? loader = 'fabric',
    String projectType = 'mod',
    String? gameVersion,
    int limit = 30,
    int offset = 0,
  }) {
    return _modrinthRepository.searchProjects(
      '',
      loader: loader,
      projectType: projectType,
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
      await _reloadCurrentContent(modsPath);
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

  Future<void> installProjectFileFromModrinth({
    required String targetPath,
    required ModrinthProject project,
    String? loader,
    String? gameVersion,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final latest = await _modrinthRepository.getLatestVersion(
        project.id,
        loader: loader,
        gameVersion: gameVersion,
      );
      if (latest == null || latest.files.isEmpty) {
        throw Exception('No compatible downloadable file found.');
      }

      ModrinthFile selected = latest.files.first;
      for (final file in latest.files) {
        if (file.primary) {
          selected = file;
          break;
        }
      }

      final fileName = selected.fileName;
      final destination = p.join(targetPath, fileName);
      await _modrinthRepository.downloadVersionFile(
        file: selected,
        targetPath: destination,
      );
      await _mappingRepository.put(
        ModrinthMapping(
          jarFileName: fileName,
          projectId: project.id,
          versionId: latest.id,
          installedAt: DateTime.now(),
          sha1: selected.sha1,
          sha512: selected.sha512,
        ),
      );

      state = state.copyWith(
        isBusy: false,
        infoMessage: 'Installed ${project.title}: $fileName',
      );
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
      rethrow;
    }
  }

  Future<Map<String, ProjectInstallInfo>> loadProjectInstallInfo({
    required List<ModrinthProject> projects,
    String? loader,
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
    final projectKeys = _projectMatchKeys(project);
    for (final mod in state.mods) {
      final localKeys = _localMatchKeys(mod);
      for (final pk in projectKeys) {
        for (final lk in localKeys) {
          if (_matchesLoosely(pk, lk)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  String _canonical(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Set<String> _projectMatchKeys(ModrinthProject project) {
    final keys = <String>{};
    final candidates = <String>[
      project.slug,
      project.title,
      project.description,
    ];
    for (final value in candidates) {
      final normalized = _normalizeForMatching(value);
      if (normalized.length >= 3) {
        keys.add(normalized);
      }
    }
    return keys;
  }

  Set<String> _localMatchKeys(ModItem item) {
    final keys = <String>{};
    final baseFile = p.basenameWithoutExtension(item.fileName);
    final candidates = <String>[
      item.modId,
      item.displayName,
      baseFile,
      item.fileName,
    ];
    for (final value in candidates) {
      final normalized = _normalizeForMatching(value);
      if (normalized.length >= 3) {
        keys.add(normalized);
      }
    }
    return keys;
  }

  String _normalizeForMatching(String input) {
    var value = _canonical(input);
    if (value.isEmpty) {
      return value;
    }

    value = value
        .replaceAll('shaderpack', '')
        .replaceAll('resourcepack', '')
        .replaceAll('resources', '')
        .replaceAll('resource', '')
        .replaceAll('shaders', '')
        .replaceAll('shader', '')
        .replaceAll('pack', '');
    value = value.replaceAll(RegExp(r'v\d+[a-z0-9]*$'), '');
    value = value.replaceAll(RegExp(r'r\d+[a-z0-9]*$'), '');
    value = value.replaceAll(RegExp(r'\d+$'), '');
    return value;
  }

  bool _matchesLoosely(String a, String b) {
    if (a.isEmpty || b.isEmpty) {
      return false;
    }
    if (a == b) {
      return true;
    }
    if (a.length >= 4 && b.length >= 4) {
      return a.contains(b) || b.contains(a);
    }
    return false;
  }

  Future<void> installExternalFiles({
    required String targetPath,
    required List<String> sourcePaths,
    required Future<ConflictResolution> Function(String fileName) onConflict,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final results = await _fileInstallService.installFiles(
        destinationFolderPath: targetPath,
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
        infoMessage:
            'Installed $installedCount external ${state.contentType.singularLabel.toLowerCase()} file(s).',
      );
      await _reloadCurrentContent(targetPath);
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
      await _reloadCurrentContent(modsPath);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<void> exportContentToZip({
    required String modsPath,
    required String zipPath,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final exportItems = state.mods
          .map(
            (item) => ContentBundleExportItem(
              fileName: item.fileName,
              filePath: item.filePath,
              provider: item.provider.name,
              projectId: item.modrinthProjectId,
              versionId: item.modrinthVersionId,
            ),
          )
          .toList();
      final result = await _modPackService.exportContentBundleToZip(
        zipPath: zipPath,
        contentType: state.contentType,
        items: exportItems,
      );
      state = state.copyWith(
        isBusy: false,
        infoMessage:
            'Exported ${result.totalEntries} ${state.contentType.singularLabel.toLowerCase()} entr${result.totalEntries == 1 ? 'y' : 'ies'} to ${result.zipPath} '
            '(${result.modrinthEntries} Modrinth reference${result.modrinthEntries == 1 ? '' : 's'}, ${result.embeddedEntries} embedded).',
      );
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  Future<void> importContentFromZip({
    required String modsPath,
    required String zipPath,
  }) async {
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final contentPath = _contentPathService.resolveContentPath(
        modsPath: modsPath,
        contentType: state.contentType,
      );

      final bundleResult = await _modPackService.importContentBundleFromZip(
        contentPath: contentPath,
        zipPath: zipPath,
        contentType: state.contentType,
      );
      if (bundleResult == null) {
        if (state.contentType == ContentType.mod) {
          await importModsFromZip(modsPath: modsPath, zipPath: zipPath);
        } else {
          final fallback = await _modPackService.importPackContentFromZip(
            contentPath: contentPath,
            zipPath: zipPath,
            contentType: state.contentType,
          );
          for (final fileName in fallback.touchedFileNames) {
            await _mappingRepository.remove(fileName);
          }
          final summary =
              '${state.contentType.label} import: ${fallback.entriesFound} zip entr${fallback.entriesFound == 1 ? 'y' : 'ies'} scanned | '
              '${fallback.imported} imported | ${fallback.renamed} renamed | '
              '${fallback.skippedIdenticalFile} identical skipped | ${fallback.failed} failed';
          final message =
              fallback.notes.isEmpty ? summary : '$summary\n${fallback.notes.first}';
          state = state.copyWith(
            isBusy: false,
            infoMessage: message,
          );
          await _reloadCurrentContent(modsPath);
        }
        return;
      }

      for (final fileName in bundleResult.touchedFileNames) {
        await _mappingRepository.remove(fileName);
      }

      var downloaded = 0;
      var downloadedRenamed = 0;
      var downloadedSkippedIdentical = 0;
      var downloadedFailed = 0;
      final notes = <String>[...bundleResult.notes];

      for (final ref in bundleResult.modrinthReferences) {
        try {
          final version = await _modrinthRepository.getVersionById(ref.versionId);
          if (version == null) {
            downloadedFailed++;
            if (notes.length < 8) {
              notes.add('${ref.fileName}: Modrinth version not found.');
            }
            continue;
          }

          final selectedFile = _selectFileForContentType(
            version: version,
            contentType: state.contentType,
            preferredFileName: ref.fileName,
          );
          if (selectedFile == null) {
            downloadedFailed++;
            if (notes.length < 8) {
              notes.add('${ref.fileName}: no downloadable file for ${state.contentType.singularLabel}.');
            }
            continue;
          }

          final targetName = selectedFile.fileName;
          final destinationPath = p.join(contentPath, targetName);
          final existing = File(destinationPath);
          if (await existing.exists() && selectedFile.sha1 != null) {
            final existingSha1 = await _fileHashService.computeSha1(existing.path);
            if (existingSha1 != null &&
                existingSha1.toLowerCase() == selectedFile.sha1!.toLowerCase()) {
              downloadedSkippedIdentical++;
              continue;
            }
          }

          final tempDir =
              Directory(p.join(Directory.systemTemp.path, 'melon_mod', 'bundle_import'));
          if (!await tempDir.exists()) {
            await tempDir.create(recursive: true);
          }
          final tempPath = p.join(
            tempDir.path,
            '${DateTime.now().microsecondsSinceEpoch}_$targetName',
          );
          final staged = await _modrinthRepository.downloadVersionFile(
            file: selectedFile,
            targetPath: tempPath,
          );
          if (!await staged.exists()) {
            downloadedFailed++;
            if (notes.length < 8) {
              notes.add('$targetName: download failed.');
            }
            continue;
          }

          var finalName = targetName;
          var finalPath = p.join(contentPath, finalName);
          final finalExisting = File(finalPath);
          if (await finalExisting.exists()) {
            finalName = '${p.basenameWithoutExtension(finalName)}_imported_${DateTime.now().millisecondsSinceEpoch}${p.extension(finalName)}';
            finalPath = p.join(contentPath, finalName);
            downloadedRenamed++;
          }

          await _moveFile(staged, finalPath);
          downloaded++;
          await _mappingRepository.put(
            ModrinthMapping(
              jarFileName: finalName,
              projectId: ref.projectId,
              versionId: ref.versionId,
              installedAt: DateTime.now(),
              sha1: selectedFile.sha1,
              sha512: selectedFile.sha512,
            ),
          );
        } catch (error) {
          downloadedFailed++;
          if (notes.length < 8) {
            notes.add('${ref.fileName}: $error');
          }
        }
      }

      final summary =
          '${state.contentType.label} bundle import: ${bundleResult.entriesFound} entr${bundleResult.entriesFound == 1 ? 'y' : 'ies'} scanned | '
          '${bundleResult.embeddedImported} embedded imported | '
          '${bundleResult.modrinthReferences.length} Modrinth reference${bundleResult.modrinthReferences.length == 1 ? '' : 's'} | '
          '$downloaded downloaded | ${bundleResult.renamed + downloadedRenamed} renamed | '
          '${bundleResult.skippedIdenticalFile + downloadedSkippedIdentical} identical skipped | '
          '${bundleResult.failed + downloadedFailed} failed';
      final message =
          notes.isEmpty ? summary : '$summary\n${notes.first}';

      state = state.copyWith(
        isBusy: false,
        infoMessage: message,
      );
      await _reloadCurrentContent(modsPath);
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        errorMessage: _errorReporter.toUserMessage(error),
      );
    }
  }

  ModrinthFile? _selectFileForContentType({
    required ModrinthVersion version,
    required ContentType contentType,
    String? preferredFileName,
  }) {
    final expectedExt = contentType == ContentType.mod ? '.jar' : '.zip';
    final files = version.files.where((file) {
      return file.fileName.toLowerCase().endsWith(expectedExt);
    }).toList();
    if (files.isEmpty) {
      return null;
    }

    final preferred = preferredFileName?.toLowerCase();
    if (preferred != null && preferred.isNotEmpty) {
      for (final file in files) {
        if (file.fileName.toLowerCase() == preferred) {
          return file;
        }
      }
    }

    for (final file in files) {
      if (file.primary) {
        return file;
      }
    }
    return files.first;
  }

  Future<void> _moveFile(File source, String targetPath) async {
    final target = File(targetPath);
    if (!await target.parent.exists()) {
      await target.parent.create(recursive: true);
    }
    try {
      await source.rename(target.path);
    } on FileSystemException {
      await source.copy(target.path);
      await source.delete();
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
          infoMessage:
              'No ${state.contentType.label.toLowerCase()} available for update.',
        );
        return;
      }

      final summary = state.contentType == ContentType.mod
          ? await (() async {
              final context = await _resolveUpdateContext(modsPath);
              return _updateModsUsecase.execute(
                modsPath: modsPath,
                mods: modsToCheck,
                loader: context.loader,
                gameVersion: context.gameVersion,
              );
            })()
          : await _runPackUpdates(
              modsPath: modsPath,
              mods: modsToCheck,
            );
      final message = _buildUpdateMessage(
        summary,
        selectedOnly: checkSelectedOnly,
      );
      state = state.copyWith(isBusy: false, infoMessage: message);
      await _reloadCurrentContent(modsPath);
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
      if (state.contentType != ContentType.mod) {
        return _checkPackUpdatesPreview(
          modsPath: modsPath,
          onProgress: onProgress,
        );
      }

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
      final summary = state.contentType == ContentType.mod
          ? await (() async {
              final context = await _resolveUpdateContext(modsPath);
              return _updateModsUsecase.execute(
                modsPath: modsPath,
                mods: mods,
                loader: context.loader,
                gameVersion: context.gameVersion,
              );
            })()
          : await _runPackUpdates(
              modsPath: modsPath,
              mods: mods,
            );
      final message = _buildUpdateMessage(
        summary,
        selectedOnly: selectedOnly,
      );
      state = state.copyWith(isBusy: false, infoMessage: message);
      await _reloadCurrentContent(modsPath);
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
      state = state.copyWith(
        infoMessage:
            'No ${state.contentType.label.toLowerCase()} selected for deletion.',
      );
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

    final kind = state.contentType.singularLabel.toLowerCase();
    final message = failed == 0
        ? 'Deleted $deleted $kind file(s).'
        : 'Deleted $deleted $kind file(s), failed to delete $failed.';

    state = state.copyWith(
      isBusy: false,
      infoMessage: message,
      selectedFiles: const <String>{},
    );

    await _reloadCurrentContent(modsPath);
  }

  String _buildUpdateMessage(
    UpdateSummary summary, {
    required bool selectedOnly,
  }) {
    if (selectedOnly && summary.totalChecked == 1) {
      final itemName = _firstOrNull(summary.updatedMods) ??
          _firstOrNull(summary.alreadyLatestMods) ??
          _firstOrNull(summary.externalSkippedMods) ??
          _firstOrNull(summary.failedMods) ??
          'Selected item';

      if (summary.updated == 1) {
        return '$itemName was updated successfully.';
      }
      if (summary.alreadyLatest == 1) {
        return '$itemName is already on the latest compatible version.';
      }
      if (summary.externalSkipped == 1) {
        return '$itemName cannot be updated automatically because it is not from Modrinth.';
      }
      if (summary.failed == 1) {
        final detail = summary.notes.isEmpty ? '' : '\n${summary.notes.first}';
        return 'Failed to update $itemName.$detail';
      }
    }

    final parts = <String>[
      'Checked ${summary.totalChecked} item(s)',
      '${summary.updated} updated',
      '${summary.alreadyLatest} up to date',
      '${summary.externalSkipped} not from Modrinth',
      '${summary.failed} failed',
    ];

    final scope = selectedOnly ? 'Selected items' : 'All items';
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

  Future<void> _reloadCurrentContent(String modsPath) async {
    await loadContent(
      modsPath: modsPath,
      contentType: state.contentType,
      forceRefresh: true,
    );
  }

  Future<List<ModItem>> _scanModsContent(
    String modsPath, {
    ScanCancellationToken? cancellationToken,
    void Function(int processed, int total)? onProgress,
  }) async {
    final stream = await _scanner.scanFolder(
      modsPath,
      cancellationToken: cancellationToken,
    );
    final loaded = <ModItem>[];

    await for (final update in stream) {
      final mod = await _toModItem(update.metadata);
      loaded.add(mod);
      onProgress?.call(update.processed, update.total);
    }

    return loaded;
  }

  Future<List<ModItem>> _scanPackContent({
    required String modsPath,
    required ContentType contentType,
  }) async {
    final contentPath = _contentPathService.resolveContentPath(
      modsPath: modsPath,
      contentType: contentType,
    );
    final files = await _contentScanner.scanFolder(
      contentPath,
      contentType: contentType,
    );
    final loaded = <ModItem>[];
    for (final file in files) {
      final mapping = await _mappingRepository.getByFileName(file.fileName);
      final localIcon =
          await _contentIconService.extractPackIcon(file.filePath);
      final resolved = await _resolveMatchFromFile(
        fileName: file.fileName,
        filePath: file.filePath,
      );
      final project = resolved?.project;
      final version = resolved?.version;
      final effectiveMapping = resolved?.mapping ?? mapping;
      loaded.add(
        ModItem(
          fileName: file.fileName,
          filePath: file.filePath,
          displayName:
              project?.title ?? p.basenameWithoutExtension(file.fileName),
          version: version?.versionNumber ?? 'Unknown',
          modId: p.basenameWithoutExtension(file.fileName),
          provider: effectiveMapping == null
              ? ModProviderType.external
              : ModProviderType.modrinth,
          lastModified: file.lastModified,
          iconCachePath: localIcon,
          modrinthProjectId: effectiveMapping?.projectId,
          modrinthVersionId: effectiveMapping?.versionId,
        ),
      );
    }
    return loaded;
  }

  String _cacheKey(String modsPath, ContentType type) {
    return '${p.normalize(modsPath)}::${type.name}';
  }

  Future<UpdateCheckPreview> _checkPackUpdatesPreview({
    required String modsPath,
    UpdateCheckProgressCallback? onProgress,
  }) async {
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

    for (var i = 0; i < modsToCheck.length; i++) {
      final mod = modsToCheck[i];
      onProgress?.call(i + 1, total, 'Checking ${mod.displayName}...');
      final mapping = await _mappingRepository.getByFileName(mod.fileName);
      if (mapping == null) {
        externalOrUnknown++;
        if (notes.length < 6) {
          notes.add('${mod.displayName}: no Modrinth mapping found.');
        }
        continue;
      }
      try {
        final current =
            await _modrinthRepository.getVersionById(mapping.versionId);
        final latest = await _modrinthRepository.getLatestVersion(
          mapping.projectId,
          loader: null,
          gameVersion: null,
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
  }

  Future<UpdateSummary> _runPackUpdates({
    required String modsPath,
    required List<ModItem> mods,
  }) async {
    var updated = 0;
    var alreadyLatest = 0;
    var externalSkipped = 0;
    var failed = 0;
    final notes = <String>[];
    final updatedMods = <String>[];
    final alreadyLatestMods = <String>[];
    final externalSkippedMods = <String>[];
    final failedMods = <String>[];
    final targetPath = _contentPathService.resolveContentPath(
      modsPath: modsPath,
      contentType: state.contentType,
    );

    for (final mod in mods) {
      final mapping = await _mappingRepository.getByFileName(mod.fileName);
      if (mapping == null) {
        externalSkipped++;
        externalSkippedMods.add(mod.displayName);
        if (notes.length < 5) {
          notes.add('${mod.displayName}: Cannot update (not from Modrinth).');
        }
        continue;
      }

      try {
        final latest = await _modrinthRepository.getLatestVersion(
          mapping.projectId,
          loader: null,
          gameVersion: null,
        );
        if (latest == null || latest.id == mapping.versionId) {
          alreadyLatest++;
          alreadyLatestMods.add(mod.displayName);
          continue;
        }

        ModrinthFile selectedFile = latest.files.first;
        for (final file in latest.files) {
          if (file.primary) {
            selectedFile = file;
            break;
          }
        }

        final destination = p.join(targetPath, selectedFile.fileName);
        await _modrinthRepository.downloadVersionFile(
          file: selectedFile,
          targetPath: destination,
        );

        if (selectedFile.fileName != mod.fileName) {
          final old = File(mod.filePath);
          if (await old.exists()) {
            await old.delete();
          }
          await _mappingRepository.remove(mod.fileName);
        }

        await _mappingRepository.put(
          ModrinthMapping(
            jarFileName: selectedFile.fileName,
            projectId: mapping.projectId,
            versionId: latest.id,
            installedAt: DateTime.now(),
            sha1: selectedFile.sha1,
            sha512: selectedFile.sha512,
          ),
        );

        updated++;
        updatedMods.add(mod.displayName);
      } catch (error) {
        failed++;
        failedMods.add(mod.displayName);
        if (notes.length < 5) {
          notes.add('Update failed for ${mod.displayName}: $error');
        }
      }
    }

    return UpdateSummary(
      totalChecked: mods.length,
      updated: updated,
      alreadyLatest: alreadyLatest,
      externalSkipped: externalSkipped,
      failed: failed,
      notes: notes,
      updatedMods: updatedMods,
      alreadyLatestMods: alreadyLatestMods,
      externalSkippedMods: externalSkippedMods,
      failedMods: failedMods,
    );
  }

  Future<ModItem> _toModItem(ModMetadataResult metadata) async {
    final resolved = await _resolveMatchFromFile(
      fileName: metadata.fileName,
      filePath: metadata.filePath,
    );
    final mapping = resolved?.mapping ??
        await _mappingRepository.getByFileName(metadata.fileName);
    final project = resolved?.project;
    final version = resolved?.version;
    return ModItem(
      fileName: metadata.fileName,
      filePath: metadata.filePath,
      displayName: project?.title ?? metadata.name,
      version: version?.versionNumber ?? metadata.version,
      modId: metadata.modId,
      provider:
          mapping == null ? ModProviderType.external : ModProviderType.modrinth,
      lastModified: metadata.lastModified,
      iconCachePath: metadata.iconCachePath,
      modrinthProjectId: mapping?.projectId,
      modrinthVersionId: mapping?.versionId,
    );
  }

  Future<_ResolvedModrinthMatch?> _resolveMatchFromFile({
    required String fileName,
    required String filePath,
  }) async {
    try {
      final existing = await _mappingRepository.getByFileName(fileName);
      if (existing != null) {
        final project =
            await _modrinthRepository.getProjectById(existing.projectId);
        final version =
            await _modrinthRepository.getVersionById(existing.versionId);
        if (version != null) {
          return _ResolvedModrinthMatch(
            mapping: existing,
            project: project,
            version: version,
          );
        }
      }

      final sha1 = await _fileHashService.computeSha1(filePath);
      if (sha1 == null || sha1.isEmpty) {
        return null;
      }

      final matchedVersion =
          await _modrinthRepository.getVersionByFileHash(sha1);
      if (matchedVersion == null) {
        return null;
      }
      final matchedProject =
          await _modrinthRepository.getProjectById(matchedVersion.projectId);

      final inferredSha512 = _extractSha512ForFile(
        matchedVersion: matchedVersion,
        fileName: fileName,
      );
      final mapping = ModrinthMapping(
        jarFileName: fileName,
        projectId: matchedVersion.projectId,
        versionId: matchedVersion.id,
        installedAt: DateTime.now(),
        sha1: sha1,
        sha512: inferredSha512,
      );
      await _mappingRepository.put(mapping);

      return _ResolvedModrinthMatch(
        mapping: mapping,
        project: matchedProject,
        version: matchedVersion,
      );
    } catch (_) {
      return null;
    }
  }

  String? _extractSha512ForFile({
    required ModrinthVersion matchedVersion,
    required String fileName,
  }) {
    final localName = fileName.toLowerCase();
    for (final file in matchedVersion.files) {
      if (file.fileName.toLowerCase() == localName) {
        return file.sha512;
      }
    }
    for (final file in matchedVersion.files) {
      if (file.primary) {
        return file.sha512;
      }
    }
    if (matchedVersion.files.isEmpty) {
      return null;
    }
    return matchedVersion.files.first.sha512;
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

class _ResolvedModrinthMatch {
  const _ResolvedModrinthMatch({
    required this.mapping,
    required this.project,
    required this.version,
  });

  final ModrinthMapping mapping;
  final ModrinthProject? project;
  final ModrinthVersion version;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
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
  static final Expando<List<ModItem>> _filteredModsCache = Expando();

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
    final cached = _filteredModsCache[this];
    if (cached != null) {
      return cached;
    }
    final computed = _buildFilteredMods();
    _filteredModsCache[this] = computed;
    return computed;
  }

  List<ModItem> _buildFilteredMods() {
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
    required ContentType contentType,
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

      final selected = _selectFileForContentType(
        version: latest,
        contentType: contentType,
      );
      if (selected == null) {
        throw Exception(
          'No compatible downloadable ${contentType.singularLabel.toLowerCase()} file found.',
        );
      }

      final fileName = selected.fileName;
      final stagingPath = await _createStagingPath(
        fileName: fileName,
        folder: 'pack_install',
      );
      final staged = await _modrinthRepository.downloadVersionFile(
        file: selected,
        targetPath: stagingPath,
      );
      if (!await staged.exists() || await staged.length() <= 0) {
        throw Exception('Downloaded file is empty.');
      }

      final destination = p.join(targetPath, fileName);
      await _commitStagedFile(
        stagedFile: staged,
        targetPath: destination,
      );
      await _cleanupOldMappedContentFiles(
        contentPath: targetPath,
        projectId: project.id,
        incomingFileName: fileName,
      );
      await _mappingRepository.put(
        ModrinthMapping(
          jarFileName: fileName,
          projectId: project.id,
          versionId: latest.id,
          installedAt: DateTime.now(),
          versionNumber: latest.versionNumber,
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
    if (a.length < 6 || b.length < 6) {
      return false;
    }
    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    final lengthGap = longer.length - shorter.length;
    if (lengthGap > 4) {
      return false;
    }
    return longer.startsWith(shorter) || longer.endsWith(shorter);
  }

  Future<void> installExternalFiles({
    required String modsPath,
    required String targetPath,
    required List<String> sourcePaths,
    required Future<ConflictResolution> Function(String fileName) onConflict,
  }) async {
    final contentType = state.contentType;
    state = state.copyWith(isBusy: true, errorMessage: null, infoMessage: null);
    try {
      final results = await _fileInstallService.installFiles(
        destinationFolderPath: targetPath,
        sourcePaths: sourcePaths,
        onConflict: onConflict,
      );

      var installedCount = 0;
      final installedFileNames = <String>{};
      for (final result in results) {
        if (result.success) {
          installedCount++;
          if (result.installedFileName != null) {
            final fileName = result.installedFileName!;
            installedFileNames.add(fileName);
            await _mappingRepository.remove(fileName);
          }
        }
      }

      state = state.copyWith(
        isBusy: false,
        infoMessage:
            'Installed $installedCount external ${state.contentType.singularLabel.toLowerCase()} file(s).',
      );
      await _reloadCurrentContent(modsPath);
      unawaited(
        _resolveExternalMappingsSilently(
          modsPath: modsPath,
          contentType: contentType,
          fileNames: installedFileNames,
        ),
      );
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
          final message = fallback.notes.isEmpty
              ? summary
              : '$summary\n${fallback.notes.first}';
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
      var downloadedSkippedIdentical = 0;
      var downloadedFailed = 0;
      final notes = <String>[...bundleResult.notes];

      for (final ref in bundleResult.modrinthReferences) {
        try {
          final version =
              await _modrinthRepository.getVersionById(ref.versionId);
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
              notes.add(
                  '${ref.fileName}: no downloadable file for ${state.contentType.singularLabel}.');
            }
            continue;
          }

          final targetName = selectedFile.fileName;
          final destinationPath = p.join(contentPath, targetName);
          final existing = File(destinationPath);
          if (await existing.exists() && selectedFile.sha1 != null) {
            final existingSha1 =
                await _fileHashService.computeSha1(existing.path);
            if (existingSha1 != null &&
                existingSha1.toLowerCase() ==
                    selectedFile.sha1!.toLowerCase()) {
              downloadedSkippedIdentical++;
              continue;
            }
          }

          final tempDir = Directory(
              p.join(Directory.systemTemp.path, 'melon_mod', 'bundle_import'));
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

          await _commitStagedFile(
            stagedFile: staged,
            targetPath: destinationPath,
          );
          await _cleanupOldMappedContentFiles(
            contentPath: contentPath,
            projectId: ref.projectId,
            incomingFileName: targetName,
          );
          downloaded++;
          await _mappingRepository.put(
            ModrinthMapping(
              jarFileName: targetName,
              projectId: ref.projectId,
              versionId: ref.versionId,
              installedAt: DateTime.now(),
              versionNumber: version.versionNumber,
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
          '$downloaded downloaded | ${bundleResult.renamed} renamed | '
          '${bundleResult.skippedIdenticalFile + downloadedSkippedIdentical} identical skipped | '
          '${bundleResult.failed + downloadedFailed} failed';
      final message = notes.isEmpty ? summary : '$summary\n${notes.first}';

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

  Future<void> _commitStagedFile({
    required File stagedFile,
    required String targetPath,
  }) async {
    final target = File(targetPath);
    final backup = File('$targetPath.bak');

    if (await backup.exists()) {
      await backup.delete();
    }

    try {
      if (await target.exists()) {
        await target.rename(backup.path);
      }

      try {
        await _moveFile(stagedFile, target.path);
        if (await backup.exists()) {
          await backup.delete();
        }
      } catch (_) {
        if (await target.exists()) {
          await target.delete();
        }
        if (await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }
    } finally {
      if (await stagedFile.exists()) {
        await stagedFile.delete();
      }
    }
  }

  Future<void> _cleanupOldMappedContentFiles({
    required String contentPath,
    required String projectId,
    required String incomingFileName,
  }) async {
    final mappings = await _mappingRepository.getAll();
    for (final mapping in mappings.values) {
      if (mapping.projectId != projectId) {
        continue;
      }
      if (mapping.jarFileName == incomingFileName) {
        continue;
      }
      try {
        final oldPath = p.join(contentPath, mapping.jarFileName);
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
        await _mappingRepository.remove(mapping.jarFileName);
      } catch (_) {
        // Keep update/install flow resilient if stale file cleanup fails.
      }
    }
  }

  Future<String> _createStagingPath({
    required String fileName,
    required String folder,
  }) async {
    final stagingDir = Directory(
      p.join(Directory.systemTemp.path, 'melon_mod', folder),
    );
    if (!await stagingDir.exists()) {
      await stagingDir.create(recursive: true);
    }
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(stagingDir.path, '${timestamp}_$fileName');
  }

  Future<String> _resolvePackVersion(ModrinthMapping? mapping) async {
    if (mapping == null) {
      return 'Unknown';
    }
    final cached = mapping.versionNumber?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    try {
      final version =
          await _modrinthRepository.getVersionById(mapping.versionId);
      if (version == null) {
        return 'Unknown';
      }
      await _mappingRepository.put(
        ModrinthMapping(
          jarFileName: mapping.jarFileName,
          projectId: mapping.projectId,
          versionId: mapping.versionId,
          installedAt: mapping.installedAt,
          versionNumber: version.versionNumber,
          sha1: mapping.sha1,
          sha512: mapping.sha512,
        ),
      );
      return version.versionNumber;
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _resolveExternalMappingsSilently({
    required String modsPath,
    required ContentType contentType,
    required Set<String> fileNames,
  }) async {
    if (fileNames.isEmpty) {
      return;
    }

    final contentPath = _contentPathService.resolveContentPath(
      modsPath: modsPath,
      contentType: contentType,
    );
    final resolved = <String, ModrinthMapping>{};

    for (final fileName in fileNames) {
      final existing = await _mappingRepository.getByFileName(fileName);
      if (existing != null) {
        continue;
      }

      final filePath = p.join(contentPath, fileName);
      final file = File(filePath);
      if (!await file.exists()) {
        continue;
      }

      final sha1 = await _fileHashService.computeSha1(filePath);
      if (sha1 == null || sha1.isEmpty) {
        continue;
      }

      try {
        final matchedVersion = await _modrinthRepository.getVersionByFileHash(
          sha1,
        );
        if (matchedVersion == null) {
          continue;
        }
        final matchedFile = _selectMatchedFileBySha1(
          version: matchedVersion,
          sha1: sha1,
        );
        final mapping = ModrinthMapping(
          jarFileName: fileName,
          projectId: matchedVersion.projectId,
          versionId: matchedVersion.id,
          installedAt: DateTime.now(),
          versionNumber: matchedVersion.versionNumber,
          sha1: sha1,
          sha512: matchedFile?.sha512,
        );
        await _mappingRepository.put(mapping);
        resolved[fileName] = mapping;
      } catch (_) {
        // Silent background resolution should never surface errors to UI.
      }
    }

    if (resolved.isEmpty) {
      return;
    }

    _applyResolvedMappingsToCache(
      modsPath: modsPath,
      contentType: contentType,
      resolved: resolved,
    );
  }

  ModrinthFile? _selectMatchedFileBySha1({
    required ModrinthVersion version,
    required String sha1,
  }) {
    final target = sha1.toLowerCase();
    for (final file in version.files) {
      final fileSha1 = file.sha1;
      if (fileSha1 != null && fileSha1.toLowerCase() == target) {
        return file;
      }
    }
    for (final file in version.files) {
      if (file.primary) {
        return file;
      }
    }
    if (version.files.isEmpty) {
      return null;
    }
    return version.files.first;
  }

  void _applyResolvedMappingsToCache({
    required String modsPath,
    required ContentType contentType,
    required Map<String, ModrinthMapping> resolved,
  }) {
    final key = _cacheKey(modsPath, contentType);
    final cached = _contentCache[key];
    if (cached != null) {
      _contentCache[key] = List<ModItem>.unmodifiable(
        _applyResolvedMappingsToItems(cached, resolved),
      );
    }

    if (state.contentType != contentType) {
      return;
    }

    final nextItems = _applyResolvedMappingsToItems(state.mods, resolved);
    state = state.copyWith(mods: List<ModItem>.unmodifiable(nextItems));
  }

  List<ModItem> _applyResolvedMappingsToItems(
    List<ModItem> items,
    Map<String, ModrinthMapping> resolved,
  ) {
    return items.map((item) {
      final mapping = resolved[item.fileName];
      if (mapping == null) {
        return item;
      }
      return item.copyWith(
        provider: ModProviderType.modrinth,
        version: mapping.versionNumber ?? item.version,
        modrinthProjectId: mapping.projectId,
        modrinthVersionId: mapping.versionId,
      );
    }).toList();
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
    const batchSize = 4;
    for (var start = 0; start < files.length; start += batchSize) {
      final end =
          (start + batchSize) < files.length ? start + batchSize : files.length;
      final batch = files.sublist(start, end);
      final mapped = await Future.wait(
        batch.map((file) async {
          final mapping = await _mappingRepository.getByFileName(file.fileName);
          final localIcon =
              await _contentIconService.extractPackIcon(file.filePath);
          final version = await _resolvePackVersion(mapping);
          return ModItem(
            fileName: file.fileName,
            filePath: file.filePath,
            displayName: p.basenameWithoutExtension(file.fileName),
            version: version,
            modId: p.basenameWithoutExtension(file.fileName),
            provider: mapping == null
                ? ModProviderType.external
                : ModProviderType.modrinth,
            lastModified: file.lastModified,
            iconCachePath: localIcon,
            modrinthProjectId: mapping?.projectId,
            modrinthVersionId: mapping?.versionId,
          );
        }),
      );
      loaded.addAll(mapped);
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

        final selectedFile = _selectFileForContentType(
          version: latest,
          contentType: state.contentType,
          preferredFileName: mod.fileName,
        );
        if (selectedFile == null) {
          failed++;
          failedMods.add(mod.displayName);
          if (notes.length < 5) {
            notes.add(
              'Update failed for ${mod.displayName}: no compatible downloadable file.',
            );
          }
          continue;
        }

        final stagingPath = await _createStagingPath(
          fileName: selectedFile.fileName,
          folder: 'pack_update',
        );
        final staged = await _modrinthRepository.downloadVersionFile(
          file: selectedFile,
          targetPath: stagingPath,
        );
        if (!await staged.exists() || await staged.length() <= 0) {
          throw Exception('Downloaded file is empty.');
        }
        final destination = p.join(targetPath, selectedFile.fileName);
        await _commitStagedFile(
          stagedFile: staged,
          targetPath: destination,
        );
        await _cleanupOldMappedContentFiles(
          contentPath: targetPath,
          projectId: mapping.projectId,
          incomingFileName: selectedFile.fileName,
        );

        await _mappingRepository.put(
          ModrinthMapping(
            jarFileName: selectedFile.fileName,
            projectId: mapping.projectId,
            versionId: latest.id,
            installedAt: DateTime.now(),
            versionNumber: latest.versionNumber,
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

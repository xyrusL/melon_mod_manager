import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;

typedef DirectoryExistsFn = Future<bool> Function(String path);
typedef ListDirectoriesFn = Future<List<String>> Function(String path);
typedef ReadFileFn = Future<String> Function(String path);

enum AutoDetectModsPathStatus {
  foundReady,
  foundNeedsCreation,
  noLoaderInstance,
  notFound,
}

class AutoDetectModsPathResult {
  const AutoDetectModsPathResult({
    required this.status,
    this.path,
    required this.message,
  });

  final AutoDetectModsPathStatus status;
  final String? path;
  final String message;

  bool get hasPath => path != null;
  bool get needsCreation => status == AutoDetectModsPathStatus.foundNeedsCreation;
}

class MinecraftPathService {
  MinecraftPathService({
    Map<String, String>? environment,
    DirectoryExistsFn? directoryExists,
    ListDirectoriesFn? listDirectories,
    ReadFileFn? readFile,
  })  : _environment = environment ?? Platform.environment,
        _directoryExists = directoryExists ?? _defaultDirectoryExists,
        _listDirectories = listDirectories ?? _defaultListDirectories,
        _readFile = readFile ?? _defaultReadFile;

  final Map<String, String> _environment;
  final DirectoryExistsFn _directoryExists;
  final ListDirectoriesFn _listDirectories;
  final ReadFileFn _readFile;
  final p.Context _windowsPath = p.Context(style: p.Style.windows);

  static Future<bool> _defaultDirectoryExists(String path) {
    return Directory(path).exists();
  }

  static Future<List<String>> _defaultListDirectories(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return const [];
    }
    final result = <String>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) {
        result.add(entity.path);
      }
    }
    return result;
  }

  static Future<String> _defaultReadFile(String path) {
    return File(path).readAsString();
  }

  Future<String?> detectDefaultModsPath() async {
    final result = await detectDefaultModsPathDetailed();
    return result.path;
  }

  Future<AutoDetectModsPathResult> detectDefaultModsPathDetailed() async {
    final appData = _environment['APPDATA'];
    final userProfile = _environment['USERPROFILE'];
    final localAppData = _environment['LOCALAPPDATA'];

    final candidates = <String>[];
    void addCandidate(String? path) {
      if (path == null || path.isEmpty) {
        return;
      }
      final normalized = _windowsPath.normalize(path);
      if (!candidates.any((c) => c.toLowerCase() == normalized.toLowerCase())) {
        candidates.add(normalized);
      }
    }

    // Instance-based launchers (Prism, MultiMC, CurseForge, ATLauncher, Modrinth App).
    final instanceRoots = _collectInstanceRoots(appData, userProfile);
    final instanceCandidates = await _collectInstanceCandidates(instanceRoots);

    // Prefer loader-based instances, newest Minecraft version first.
    final loaderInstances = instanceCandidates
        .where((candidate) => candidate.loader != null)
        .toList()
      ..sort(_compareInstanceCandidates);

    for (final candidate in loaderInstances) {
      for (final modsPath in candidate.modsCandidates) {
        if (await _directoryExists(modsPath)) {
          return AutoDetectModsPathResult(
            status: AutoDetectModsPathStatus.foundReady,
            path: modsPath,
            message:
                'Auto-detected ${candidate.launcherLabel} instance (${candidate.loaderLabel}${candidate.minecraftVersionLabel}).',
          );
        }
      }
    }

    if (loaderInstances.isNotEmpty) {
      final preferred = loaderInstances.first;
      return AutoDetectModsPathResult(
        status: AutoDetectModsPathStatus.foundNeedsCreation,
        path: preferred.preferredModsPath,
        message:
            'Detected ${preferred.launcherLabel} instance (${preferred.loaderLabel}${preferred.minecraftVersionLabel}), but mods folder does not exist yet. It can be created now.',
      );
    }

    if (instanceCandidates.isNotEmpty) {
      return const AutoDetectModsPathResult(
        status: AutoDetectModsPathStatus.noLoaderInstance,
        path: null,
        message:
            'Minecraft instances were found, but no supported mod loader (Fabric/Quilt/Forge/NeoForge) was detected. This app manages Java loader-based mods only.',
      );
    }

    // Vanilla Java + fallback path.
    addCandidate(
      appData == null ? null : _windowsPath.join(appData, '.minecraft', 'mods'),
    );
    addCandidate(
      userProfile == null
          ? null
          : _windowsPath.join(
              userProfile,
              'AppData',
              'Roaming',
              '.minecraft',
              'mods',
            ),
    );

    // Windows launcher package variants.
    addCandidate(
      localAppData == null
          ? null
          : _windowsPath.join(
              localAppData,
              'Packages',
              'Microsoft.4297127D64EC6_8wekyb3d8bbwe',
              'LocalCache',
              'Roaming',
              '.minecraft',
              'mods',
            ),
    );

    // Official launcher custom game directories from launcher_profiles.json.
    final customGameDirs = await _loadLauncherProfileGameDirs(appData);
    for (final gameDir in customGameDirs) {
      addCandidate(_windowsPath.join(gameDir, 'mods'));
      addCandidate(_windowsPath.join(gameDir, '.minecraft', 'mods'));
    }

    for (final candidate in candidates) {
      if (await _directoryExists(candidate)) {
        return AutoDetectModsPathResult(
          status: AutoDetectModsPathStatus.foundReady,
          path: candidate,
          message:
              'Auto-detected a Minecraft Java mods folder. If this is not your active modded instance, use Browse to choose another path.',
        );
      }
    }

    return const AutoDetectModsPathResult(
      status: AutoDetectModsPathStatus.notFound,
      path: null,
      message:
          'Could not auto-detect a usable Minecraft Java mods folder. Launch your loader instance once, then try Auto-detect again.',
    );
  }

  String normalizeSelectedPath(String selectedPath) {
    final normalized = selectedPath.trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    final lower = normalized.toLowerCase();
    if (lower.endsWith('.minecraft')) {
      return _windowsPath.join(normalized, 'mods');
    }
    return normalized;
  }

  Future<bool> pathExistsAndDirectory(String path) async {
    final entityType = await FileSystemEntity.type(path);
    return entityType == FileSystemEntityType.directory;
  }

  Future<void> createModsDirectory(String path) async {
    await Directory(path).create(recursive: true);
  }

  Future<List<String>> _loadLauncherProfileGameDirs(String? appData) async {
    if (appData == null || appData.isEmpty) {
      return const [];
    }

    final launcherProfilesPath = _windowsPath.join(
      appData,
      '.minecraft',
      'launcher_profiles.json',
    );

    try {
      final content = await _readFile(launcherProfilesPath);
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const [];
      }
      final profiles = decoded['profiles'];
      if (profiles is! Map) {
        return const [];
      }

      final dirs = <String>[];
      for (final value in profiles.values) {
        if (value is! Map) {
          continue;
        }
        final gameDir = value['gameDir'];
        if (gameDir is! String || gameDir.trim().isEmpty) {
          continue;
        }
        dirs.add(_expandEnvironmentVariables(gameDir.trim()));
      }
      return dirs;
    } catch (_) {
      return const [];
    }
  }

  String _expandEnvironmentVariables(String rawPath) {
    var result = rawPath;
    final matches = RegExp(r'%([^%]+)%').allMatches(rawPath).toList();
    for (final match in matches) {
      final variable = match.group(1);
      if (variable == null) {
        continue;
      }
      final value = _environment[variable] ??
          _environment[variable.toUpperCase()] ??
          _environment[variable.toLowerCase()];
      if (value != null) {
        result = result.replaceAll('%$variable%', value);
      }
    }
    return result;
  }

  List<_InstanceRoot> _collectInstanceRoots(String? appData, String? userProfile) {
    return <_InstanceRoot>[
      if (appData != null)
        _InstanceRoot(
          path: _windowsPath.join(appData, 'PrismLauncher', 'instances'),
          launcherLabel: 'Prism Launcher',
        ),
      if (appData != null)
        _InstanceRoot(
          path: _windowsPath.join(appData, 'MultiMC', 'instances'),
          launcherLabel: 'MultiMC',
        ),
      if (appData != null)
        _InstanceRoot(
          path: _windowsPath.join(appData, 'ATLauncher', 'instances'),
          launcherLabel: 'ATLauncher',
        ),
      if (appData != null)
        _InstanceRoot(
          path: _windowsPath.join(appData, 'com.modrinth.theseus', 'profiles'),
          launcherLabel: 'Modrinth App',
        ),
      if (userProfile != null)
        _InstanceRoot(
          path: _windowsPath.join(
            userProfile,
            'curseforge',
            'minecraft',
            'Instances',
          ),
          launcherLabel: 'CurseForge',
        ),
      if (userProfile != null)
        _InstanceRoot(
          path: _windowsPath.join(
            userProfile,
            'Documents',
            'Curseforge',
            'Minecraft',
            'Instances',
          ),
          launcherLabel: 'CurseForge',
        ),
      if (userProfile != null)
        _InstanceRoot(
          path: _windowsPath.join(
            userProfile,
            'Documents',
            'curseforge',
            'minecraft',
            'Instances',
          ),
          launcherLabel: 'CurseForge',
        ),
      if (userProfile != null)
        _InstanceRoot(
          path: _windowsPath.join(userProfile, 'ATLauncher', 'instances'),
          launcherLabel: 'ATLauncher',
        ),
      if (userProfile != null)
        _InstanceRoot(
          path: _windowsPath.join(userProfile, 'PrismLauncher', 'instances'),
          launcherLabel: 'Prism Launcher',
        ),
    ];
  }

  Future<List<_InstanceCandidate>> _collectInstanceCandidates(
    List<_InstanceRoot> roots,
  ) async {
    final candidates = <_InstanceCandidate>[];
    final seen = <String>{};

    for (final root in roots) {
      final instanceDirs = await _listDirectories(root.path);
      for (final instanceDir in instanceDirs) {
        final normalizedInstance = _windowsPath.normalize(instanceDir);
        final key = normalizedInstance.toLowerCase();
        if (!seen.add(key)) {
          continue;
        }
        final modsCandidates = <String>[
          _windowsPath.join(normalizedInstance, '.minecraft', 'mods'),
          _windowsPath.join(normalizedInstance, 'minecraft', 'mods'),
          _windowsPath.join(normalizedInstance, 'mods'),
        ];
        final metadata = await _readInstanceMetadata(normalizedInstance);
        candidates.add(
          _InstanceCandidate(
            instancePath: normalizedInstance,
            launcherLabel: root.launcherLabel,
            loader: metadata.loader,
            minecraftVersion: metadata.minecraftVersion,
            modsCandidates: modsCandidates,
          ),
        );
      }
    }

    return candidates;
  }

  Future<_InstanceMetadata> _readInstanceMetadata(String instanceDir) async {
    final mmcPackPath = _windowsPath.join(instanceDir, 'mmc-pack.json');
    final instanceCfgPath = _windowsPath.join(instanceDir, 'instance.cfg');

    final mmcPackContent = await _tryReadFile(mmcPackPath);
    final fromMmc = _parseMmcPackMetadata(mmcPackContent);

    final cfgContent = await _tryReadFile(instanceCfgPath);
    final fromCfg = _parseInstanceCfgMetadata(cfgContent);

    return _InstanceMetadata(
      loader: fromMmc.loader ?? fromCfg.loader,
      minecraftVersion: fromMmc.minecraftVersion ?? fromCfg.minecraftVersion,
    );
  }

  _InstanceMetadata _parseMmcPackMetadata(String? content) {
    if (content == null || content.trim().isEmpty) {
      return const _InstanceMetadata();
    }
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const _InstanceMetadata();
      }
      final components = decoded['components'];
      if (components is! List) {
        return const _InstanceMetadata();
      }
      String? loader;
      String? version;
      for (final item in components) {
        if (item is! Map) {
          continue;
        }
        final uid = item['uid']?.toString().toLowerCase();
        final compVersion = item['version']?.toString();
        if (uid == null) {
          continue;
        }
        if (uid == 'net.minecraft' && compVersion != null) {
          version ??= compVersion.trim();
        }
        if (uid.contains('neoforge')) {
          loader ??= 'neoforge';
          continue;
        }
        if (uid.contains('quilt')) {
          loader ??= 'quilt';
          continue;
        }
        if (uid.contains('fabric')) {
          loader ??= 'fabric';
          continue;
        }
        if (uid == 'net.minecraftforge' || uid.endsWith('.forge')) {
          loader ??= 'forge';
        }
      }
      return _InstanceMetadata(
        loader: loader,
        minecraftVersion: _sanitizeMinecraftVersion(version),
      );
    } catch (_) {
      return const _InstanceMetadata();
    }
  }

  _InstanceMetadata _parseInstanceCfgMetadata(String? content) {
    if (content == null || content.trim().isEmpty) {
      return const _InstanceMetadata();
    }
    final lines = const LineSplitter().convert(content);
    String? loader;
    String? version;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        continue;
      }
      final lower = line.toLowerCase();
      loader ??= _extractLoaderFromText(lower);
      version ??= _extractMinecraftVersionFromText(line);
    }
    return _InstanceMetadata(
      loader: loader,
      minecraftVersion: _sanitizeMinecraftVersion(version),
    );
  }

  String? _extractLoaderFromText(String text) {
    if (text.contains('neoforge')) {
      return 'neoforge';
    }
    if (text.contains('quilt')) {
      return 'quilt';
    }
    if (text.contains('fabric')) {
      return 'fabric';
    }
    if (text.contains('forge')) {
      return 'forge';
    }
    return null;
  }

  String? _extractMinecraftVersionFromText(String text) {
    final match = RegExp(r'(?<!\d)(1\.\d{1,2}(?:\.\d{1,2})?)').firstMatch(text);
    return match?.group(1);
  }

  String? _sanitizeMinecraftVersion(String? raw) {
    if (raw == null) {
      return null;
    }
    final match = RegExp(r'(?<!\d)(1\.\d{1,2}(?:\.\d{1,2})?)').firstMatch(raw);
    return match?.group(1);
  }

  int _compareInstanceCandidates(_InstanceCandidate a, _InstanceCandidate b) {
    final versionDiff = _compareMinecraftVersions(
      b.minecraftVersion,
      a.minecraftVersion,
    );
    if (versionDiff != 0) {
      return versionDiff;
    }
    return a.instancePath.toLowerCase().compareTo(b.instancePath.toLowerCase());
  }

  int _compareMinecraftVersions(String? left, String? right) {
    if (left == null && right == null) {
      return 0;
    }
    if (left == null) {
      return -1;
    }
    if (right == null) {
      return 1;
    }

    List<int> parse(String value) => value
        .split('.')
        .map((segment) => int.tryParse(segment) ?? 0)
        .toList();

    final a = parse(left);
    final b = parse(right);
    final maxLength = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < maxLength; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) {
        return ai.compareTo(bi);
      }
    }
    return 0;
  }

  Future<String?> _tryReadFile(String path) async {
    try {
      return await _readFile(path);
    } catch (_) {
      return null;
    }
  }
}

class _InstanceRoot {
  const _InstanceRoot({required this.path, required this.launcherLabel});

  final String path;
  final String launcherLabel;
}

class _InstanceMetadata {
  const _InstanceMetadata({this.loader, this.minecraftVersion});

  final String? loader;
  final String? minecraftVersion;
}

class _InstanceCandidate {
  const _InstanceCandidate({
    required this.instancePath,
    required this.launcherLabel,
    required this.loader,
    required this.minecraftVersion,
    required this.modsCandidates,
  });

  final String instancePath;
  final String launcherLabel;
  final String? loader;
  final String? minecraftVersion;
  final List<String> modsCandidates;

  String get preferredModsPath => modsCandidates.first;

  String get loaderLabel {
    if (loader == null) {
      return 'unknown loader';
    }
    switch (loader!) {
      case 'fabric':
        return 'Fabric';
      case 'quilt':
        return 'Quilt';
      case 'forge':
        return 'Forge';
      case 'neoforge':
        return 'NeoForge';
      default:
        return loader!;
    }
  }

  String get minecraftVersionLabel {
    if (minecraftVersion == null || minecraftVersion!.isEmpty) {
      return '';
    }
    return ' / MC $minecraftVersion';
  }
}

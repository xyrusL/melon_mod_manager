import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;

typedef DirectoryExistsFn = Future<bool> Function(String path);
typedef ListDirectoriesFn = Future<List<String>> Function(String path);
typedef ReadFileFn = Future<String> Function(String path);

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
    addCandidate(
      localAppData == null
          ? null
          : _windowsPath.join(
              localAppData,
              'Packages',
              'Microsoft.MinecraftUWP_8wekyb3d8bbwe',
              'LocalState',
              'games',
              'com.mojang',
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

    // Instance-based launchers (Prism, MultiMC, CurseForge, ATLauncher, Modrinth App).
    final instanceRoots = <String>[
      if (appData != null) _windowsPath.join(appData, 'PrismLauncher', 'instances'),
      if (appData != null) _windowsPath.join(appData, 'MultiMC', 'instances'),
      if (appData != null) _windowsPath.join(appData, 'ATLauncher', 'instances'),
      if (appData != null)
        _windowsPath.join(appData, 'com.modrinth.theseus', 'profiles'),
      if (userProfile != null)
        _windowsPath.join(userProfile, 'curseforge', 'minecraft', 'Instances'),
      if (userProfile != null)
        _windowsPath.join(
          userProfile,
          'Documents',
          'Curseforge',
          'Minecraft',
          'Instances',
        ),
      if (userProfile != null)
        _windowsPath.join(
          userProfile,
          'Documents',
          'curseforge',
          'minecraft',
          'Instances',
        ),
      if (userProfile != null)
        _windowsPath.join(userProfile, 'ATLauncher', 'instances'),
      if (userProfile != null)
        _windowsPath.join(userProfile, 'PrismLauncher', 'instances'),
    ];

    for (final root in instanceRoots) {
      final instanceDirs = await _listDirectories(root);
      for (final instanceDir in instanceDirs) {
        addCandidate(_windowsPath.join(instanceDir, '.minecraft', 'mods'));
        addCandidate(_windowsPath.join(instanceDir, 'minecraft', 'mods'));
        addCandidate(_windowsPath.join(instanceDir, 'mods'));
      }
    }

    for (final candidate in candidates) {
      if (await _directoryExists(candidate)) {
        return candidate;
      }
    }

    return null;
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
}

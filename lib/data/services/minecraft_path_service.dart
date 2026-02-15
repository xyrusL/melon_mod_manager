import 'dart:io';

import 'package:path/path.dart' as p;

typedef DirectoryExistsFn = Future<bool> Function(String path);

class MinecraftPathService {
  MinecraftPathService({
    Map<String, String>? environment,
    DirectoryExistsFn? directoryExists,
  })  : _environment = environment ?? Platform.environment,
        _directoryExists = directoryExists ?? _defaultDirectoryExists;

  final Map<String, String> _environment;
  final DirectoryExistsFn _directoryExists;
  final p.Context _windowsPath = p.Context(style: p.Style.windows);

  static Future<bool> _defaultDirectoryExists(String path) {
    return Directory(path).exists();
  }

  Future<String?> detectDefaultModsPath() async {
    final appData = _environment['APPDATA'];
    final userProfile = _environment['USERPROFILE'];
    final localAppData = _environment['LOCALAPPDATA'];

    final candidates = <String>[
      if (appData != null) _windowsPath.join(appData, '.minecraft', 'mods'),
      if (userProfile != null)
        _windowsPath.join(
          userProfile,
          'AppData',
          'Roaming',
          '.minecraft',
          'mods',
        ),
      if (localAppData != null)
        _windowsPath.join(
          localAppData,
          'Packages',
          'Microsoft.4297127D64EC6_8wekyb3d8bbwe',
          'LocalCache',
          'Roaming',
          '.minecraft',
          'mods',
        ),
      if (localAppData != null)
        _windowsPath.join(
          localAppData,
          'Packages',
          'Microsoft.MinecraftUWP_8wekyb3d8bbwe',
          'LocalState',
          'games',
          'com.mojang',
          '.minecraft',
          'mods',
        ),
    ];

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
}

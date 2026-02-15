import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/services/minecraft_path_service.dart';

void main() {
  group('MinecraftPathService', () {
    test('detects APPDATA .minecraft mods path first', () async {
      final service = MinecraftPathService(
        environment: {
          'APPDATA': r'C:\Users\Alex\AppData\Roaming',
          'USERPROFILE': r'C:\Users\Alex',
        },
        directoryExists: (path) async =>
            path == r'C:\Users\Alex\AppData\Roaming\.minecraft\mods',
      );

      final detected = await service.detectDefaultModsPath();
      expect(detected, r'C:\Users\Alex\AppData\Roaming\.minecraft\mods');
    });

    test('detects Prism Launcher instance mods path', () async {
      final existing = <String>{
        r'C:\Users\Alex\AppData\Roaming\PrismLauncher\instances\PackA\.minecraft\mods',
      };
      final service = MinecraftPathService(
        environment: {
          'APPDATA': r'C:\Users\Alex\AppData\Roaming',
          'USERPROFILE': r'C:\Users\Alex',
        },
        directoryExists: (path) async => existing.contains(path),
        listDirectories: (path) async {
          if (path ==
              r'C:\Users\Alex\AppData\Roaming\PrismLauncher\instances') {
            return [
              r'C:\Users\Alex\AppData\Roaming\PrismLauncher\instances\PackA',
            ];
          }
          return const [];
        },
      );

      final detected = await service.detectDefaultModsPath();
      expect(
        detected,
        r'C:\Users\Alex\AppData\Roaming\PrismLauncher\instances\PackA\.minecraft\mods',
      );
    });

    test('detects CurseForge instance mods path', () async {
      final existing = <String>{
        r'C:\Users\Alex\curseforge\minecraft\Instances\BetterMC\mods',
      };
      final service = MinecraftPathService(
        environment: {
          'APPDATA': r'C:\Users\Alex\AppData\Roaming',
          'USERPROFILE': r'C:\Users\Alex',
        },
        directoryExists: (path) async => existing.contains(path),
        listDirectories: (path) async {
          if (path == r'C:\Users\Alex\curseforge\minecraft\Instances') {
            return [r'C:\Users\Alex\curseforge\minecraft\Instances\BetterMC'];
          }
          return const [];
        },
      );

      final detected = await service.detectDefaultModsPath();
      expect(
        detected,
        r'C:\Users\Alex\curseforge\minecraft\Instances\BetterMC\mods',
      );
    });

    test('detects Official launcher custom gameDir from launcher_profiles.json',
        () async {
      final existing = <String>{
        r'C:\Games\CustomMinecraft\mods',
      };
      final service = MinecraftPathService(
        environment: {
          'APPDATA': r'C:\Users\Alex\AppData\Roaming',
          'USERPROFILE': r'C:\Users\Alex',
        },
        directoryExists: (path) async => existing.contains(path),
        readFile: (path) async {
          if (path ==
              r'C:\Users\Alex\AppData\Roaming\.minecraft\launcher_profiles.json') {
            return '''
{
  "profiles": {
    "custom-profile": {
      "name": "Custom",
      "gameDir": "C:\\\\Games\\\\CustomMinecraft"
    }
  }
}
''';
          }
          throw Exception('file not found');
        },
      );

      final detected = await service.detectDefaultModsPath();
      expect(detected, r'C:\Games\CustomMinecraft\mods');
    });

    test('expands environment variables in launcher profile gameDir', () async {
      final existing = <String>{
        r'C:\Users\Alex\AppData\Roaming\CustomMC\mods',
      };
      final service = MinecraftPathService(
        environment: {
          'APPDATA': r'C:\Users\Alex\AppData\Roaming',
          'USERPROFILE': r'C:\Users\Alex',
        },
        directoryExists: (path) async => existing.contains(path),
        readFile: (path) async {
          if (path ==
              r'C:\Users\Alex\AppData\Roaming\.minecraft\launcher_profiles.json') {
            return '''
{
  "profiles": {
    "custom-profile": {
      "gameDir": "%APPDATA%\\\\CustomMC"
    }
  }
}
''';
          }
          throw Exception('file not found');
        },
      );

      final detected = await service.detectDefaultModsPath();
      expect(detected, r'C:\Users\Alex\AppData\Roaming\CustomMC\mods');
    });

    test('normalizes .minecraft folder to .minecraft/mods', () {
      final service = MinecraftPathService(environment: const {});

      final normalized = service.normalizeSelectedPath(r'C:\Games\.minecraft');
      expect(normalized, r'C:\Games\.minecraft\mods');
    });
  });
}

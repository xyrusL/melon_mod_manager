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

    test('normalizes .minecraft folder to .minecraft/mods', () {
      final service = MinecraftPathService(environment: const {});

      final normalized = service.normalizeSelectedPath(r'C:\Games\.minecraft');
      expect(normalized, r'C:\Games\.minecraft\mods');
    });
  });
}

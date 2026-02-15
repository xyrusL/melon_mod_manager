import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/services/minecraft_version_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MinecraftVersionService', () {
    test('detects version from path segment before .minecraft', () async {
      final service = MinecraftVersionService();
      final result = await service.detectVersionFromModsPath(
        r'C:\Users\john\AppData\Roaming\PrismLauncher\instances\1.21.1\.minecraft\mods',
      );

      expect(result, '1.21.1');
    });

    test('detects version from mmc-pack.json', () async {
      final temp =
          await Directory.systemTemp.createTemp('melon_mod_version_test_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final instanceDir = Directory(p.join(temp.path, 'instances', 'MyPack'));
      await Directory(p.join(instanceDir.path, '.minecraft', 'mods'))
          .create(recursive: true);

      final mmcPack = File(p.join(instanceDir.path, 'mmc-pack.json'));
      await mmcPack.writeAsString(
        jsonEncode({
          'components': [
            {'uid': 'net.minecraft', 'version': '1.20.1'},
          ],
        }),
      );

      final service = MinecraftVersionService();
      final result = await service.detectVersionFromModsPath(
        p.join(instanceDir.path, '.minecraft', 'mods'),
      );

      expect(result, '1.20.1');
    });

    test('returns null when no version can be detected', () async {
      final temp =
          await Directory.systemTemp.createTemp('melon_mod_version_test_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final modsDir = Directory(p.join(temp.path, '.minecraft', 'mods'));
      await modsDir.create(recursive: true);

      final service = MinecraftVersionService();
      final result = await service.detectVersionFromModsPath(modsDir.path);

      expect(result, isNull);
    });
  });
}

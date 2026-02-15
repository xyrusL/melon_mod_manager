import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/services/minecraft_loader_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('MinecraftLoaderService', () {
    test('detects Fabric loader and version from mmc-pack.json', () async {
      final temp = await Directory.systemTemp.createTemp('loader_fabric_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final instanceDir = Directory(p.join(temp.path, 'instances', 'PackA'));
      await Directory(p.join(instanceDir.path, '.minecraft', 'mods'))
          .create(recursive: true);
      await File(p.join(instanceDir.path, 'mmc-pack.json')).writeAsString('''
{
  "components": [
    {"uid": "net.minecraft", "version": "1.21.1"},
    {"uid": "net.fabricmc.fabric-loader", "version": "0.16.10"}
  ]
}
''');

      final service = MinecraftLoaderService();
      final detected = await service.detectLoaderFromModsPath(
        p.join(instanceDir.path, '.minecraft', 'mods'),
      );

      expect(detected, isNotNull);
      expect(detected!.loader, 'fabric');
      expect(detected.version, '0.16.10');
    });

    test('detects Quilt loader and version from mmc-pack.json', () async {
      final temp = await Directory.systemTemp.createTemp('loader_quilt_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final instanceDir = Directory(p.join(temp.path, 'instances', 'PackB'));
      await Directory(p.join(instanceDir.path, '.minecraft', 'mods'))
          .create(recursive: true);
      await File(p.join(instanceDir.path, 'mmc-pack.json')).writeAsString('''
{
  "components": [
    {"uid": "net.minecraft", "version": "1.21.1"},
    {"uid": "org.quiltmc.quilt-loader", "version": "0.26.4"}
  ]
}
''');

      final service = MinecraftLoaderService();
      final detected = await service.detectLoaderFromModsPath(
        p.join(instanceDir.path, '.minecraft', 'mods'),
      );

      expect(detected, isNotNull);
      expect(detected!.loader, 'quilt');
      expect(detected.version, '0.26.4');
    });

    test('falls back to loader detection from path segments', () async {
      final service = MinecraftLoaderService();
      final detected = await service.detectLoaderFromModsPath(
        r'C:\Users\Alex\AppData\Roaming\PrismLauncher\instances\fabric-1.21.1\.minecraft\mods',
      );

      expect(detected, isNotNull);
      expect(detected!.loader, 'fabric');
      expect(detected.version, isNull);
    });

    test('detects Forge loader and version from mmc-pack.json', () async {
      final temp = await Directory.systemTemp.createTemp('loader_forge_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final instanceDir = Directory(p.join(temp.path, 'instances', 'PackC'));
      await Directory(p.join(instanceDir.path, '.minecraft', 'mods'))
          .create(recursive: true);
      await File(p.join(instanceDir.path, 'mmc-pack.json')).writeAsString('''
{
  "components": [
    {"uid": "net.minecraft", "version": "1.20.1"},
    {"uid": "net.minecraftforge", "version": "47.3.6"}
  ]
}
''');

      final service = MinecraftLoaderService();
      final detected = await service.detectLoaderFromModsPath(
        p.join(instanceDir.path, '.minecraft', 'mods'),
      );

      expect(detected, isNotNull);
      expect(detected!.loader, 'forge');
      expect(detected.version, '47.3.6');
    });

    test('detects NeoForge loader and version from mmc-pack.json', () async {
      final temp = await Directory.systemTemp.createTemp('loader_neoforge_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      final instanceDir = Directory(p.join(temp.path, 'instances', 'PackD'));
      await Directory(p.join(instanceDir.path, '.minecraft', 'mods'))
          .create(recursive: true);
      await File(p.join(instanceDir.path, 'mmc-pack.json')).writeAsString('''
{
  "components": [
    {"uid": "net.minecraft", "version": "1.21.1"},
    {"uid": "net.neoforged.neoforge", "version": "21.1.80"}
  ]
}
''');

      final service = MinecraftLoaderService();
      final detected = await service.detectLoaderFromModsPath(
        p.join(instanceDir.path, '.minecraft', 'mods'),
      );

      expect(detected, isNotNull);
      expect(detected!.loader, 'neoforge');
      expect(detected.version, '21.1.80');
    });
  });
}

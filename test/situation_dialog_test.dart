import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/services/minecraft_path_service.dart';
import 'package:melon_mod/presentation/dialogs/situation_dialog.dart';

void main() {
  group('situationSpecForAutoDetect', () {
    test('maps no-loader instances to a user-friendly loader warning', () {
      const result = AutoDetectModsPathResult(
        status: AutoDetectModsPathStatus.noLoaderInstance,
        message: 'No supported loader found.',
      );

      final spec = situationSpecForAutoDetect(result);

      expect(spec.title, 'Minecraft Found, But Loader Is Unsupported');
      expect(spec.summary, contains('Fabric'));
      expect(spec.details, 'No supported loader found.');
    });

    test('maps missing mods folder to a creation-focused explanation', () {
      const result = AutoDetectModsPathResult(
        status: AutoDetectModsPathStatus.foundNeedsCreation,
        path: r'C:\Games\Pack\.minecraft\mods',
        message: 'Detected instance, but mods folder is missing.',
      );

      final spec = situationSpecForAutoDetect(result);

      expect(spec.title, 'Mods Folder Not Created Yet');
      expect(spec.summary, contains('mods folder is missing'));
      expect(spec.details, 'Detected instance, but mods folder is missing.');
    });
  });

  group('situationSpecForEnvironmentDetection', () {
    test('explains when both loader and version are unknown', () {
      final spec = situationSpecForEnvironmentDetection(
        actionLabel: 'download mods',
      );

      expect(spec.title, 'Can’t Identify This Modded Instance');
      expect(spec.summary, contains('download mods'));
      expect(spec.details, contains('mod loader or the Minecraft version'));
    });

    test('explains when only loader is unknown', () {
      final spec = situationSpecForEnvironmentDetection(
        actionLabel: 'check for updates',
        minecraftVersion: '1.21.1',
      );

      expect(spec.title, 'Can’t Identify The Mod Loader');
      expect(spec.details, contains('Minecraft 1.21.1'));
    });
  });

  test('fallback unknown problem keeps details when provided', () {
    final spec = situationSpecForUnknownProblem('Permission denied');

    expect(spec.title, 'Problem Detected');
    expect(spec.details, 'Permission denied');
  });
}

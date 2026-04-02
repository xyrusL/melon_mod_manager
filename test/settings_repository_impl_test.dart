import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/repositories/settings_repository_impl.dart';
import 'package:melon_mod/domain/entities/app_theme_mode.dart';
import 'package:melon_mod/domain/entities/auto_update_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsRepositoryImpl theme preference', () {
    test('defaults to current theme when preference is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      expect(await repository.getAppThemeMode(), AppThemeMode.defaultDark);
    });

    test('saves and loads the selected theme mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      await repository.saveAppThemeMode(AppThemeMode.modernDark);

      expect(await repository.getAppThemeMode(), AppThemeMode.modernDark);
    });

    test('falls back to default theme for invalid stored values', () async {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': 'unknown_theme',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      expect(await repository.getAppThemeMode(), AppThemeMode.defaultDark);
    });
  });

  group('SettingsRepositoryImpl post-update metadata state', () {
    test('treats missing last seen version as fresh install without prompt',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final state = await repository.getPostUpdateMetadataState('1.7.3');

      expect(state.isFreshInstall, isTrue);
      expect(state.isUpgrade, isFalse);
      expect(state.shouldPromptForRefresh, isFalse);
      expect(state.shouldWarmUpInBackground, isTrue);
    });

    test('does not prompt when current version matches last seen version',
        () async {
      SharedPreferences.setMockInitialValues({
        'last_seen_app_version': '1.7.3',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final state = await repository.getPostUpdateMetadataState('1.7.3');

      expect(state.isFreshInstall, isFalse);
      expect(state.isUpgrade, isFalse);
      expect(state.shouldPromptForRefresh, isFalse);
      expect(state.shouldWarmUpInBackground, isTrue);
    });

    test('prompts when app was upgraded and metadata is not prepared', () async {
      SharedPreferences.setMockInitialValues({
        'last_seen_app_version': '1.7.2',
        'metadata_prepared_app_version': '1.7.2',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final state = await repository.getPostUpdateMetadataState('1.7.3');

      expect(state.previousVersion, '1.7.2');
      expect(state.isUpgrade, isTrue);
      expect(state.shouldPromptForRefresh, isTrue);
      expect(state.shouldWarmUpInBackground, isFalse);
    });

    test('does not prompt when upgraded app already has prepared metadata',
        () async {
      SharedPreferences.setMockInitialValues({
        'last_seen_app_version': '1.7.2',
        'metadata_prepared_app_version': '1.7.3',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final state = await repository.getPostUpdateMetadataState('1.7.3');

      expect(state.isUpgrade, isTrue);
      expect(state.isMetadataPreparedForCurrentVersion, isTrue);
      expect(state.shouldPromptForRefresh, isFalse);
      expect(state.shouldWarmUpInBackground, isFalse);
    });
  });

  group('SettingsRepositoryImpl auto-update interval migration', () {
    test('defaults to 8 hours when no interval is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final interval = await repository.getAutoUpdateInterval(
        AutoUpdateTarget.app,
      );

      expect(interval.preset, AutoUpdateIntervalPreset.hour8);
      expect(interval.toDuration(), const Duration(hours: 8));
    });

    test('migrates legacy off preset to 8 hours', () async {
      SharedPreferences.setMockInitialValues({
        'auto_update_interval_app': 'off',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final interval = await repository.getAutoUpdateInterval(
        AutoUpdateTarget.app,
      );

      expect(interval.preset, AutoUpdateIntervalPreset.hour8);
    });

    test('migrates legacy month preset to one week', () async {
      SharedPreferences.setMockInitialValues({
        'auto_update_interval_app': 'month1',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final interval = await repository.getAutoUpdateInterval(
        AutoUpdateTarget.app,
      );

      expect(interval.preset, AutoUpdateIntervalPreset.week1);
      expect(interval.toDuration(), const Duration(days: 7));
    });

    test('reads legacy custom day values and clamps anything above one week',
        () async {
      SharedPreferences.setMockInitialValues({
        'auto_update_interval_app': 'custom',
        'auto_update_custom_days_app': 10,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final interval = await repository.getAutoUpdateInterval(
        AutoUpdateTarget.app,
      );

      expect(interval.preset, AutoUpdateIntervalPreset.custom);
      expect(interval.customUnit, AutoUpdateIntervalUnit.weeks);
      expect(interval.customValue, 1);
      expect(interval.toDuration(), const Duration(days: 7));
    });

    test('preserves valid legacy custom day values as custom days', () async {
      SharedPreferences.setMockInitialValues({
        'auto_update_interval_app': 'custom',
        'auto_update_custom_days_app': 2,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      final interval = await repository.getAutoUpdateInterval(
        AutoUpdateTarget.app,
      );

      expect(interval.preset, AutoUpdateIntervalPreset.custom);
      expect(interval.customUnit, AutoUpdateIntervalUnit.days);
      expect(interval.customValue, 2);
      expect(interval.toDuration(), const Duration(days: 2));
    });

    test('rejects invalid custom interval saves', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepositoryImpl(prefs);

      expect(
        () => repository.saveAutoUpdateInterval(
          AutoUpdateTarget.app,
          const AutoUpdateIntervalSetting(
            preset: AutoUpdateIntervalPreset.custom,
            customValue: 2,
            customUnit: AutoUpdateIntervalUnit.weeks,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

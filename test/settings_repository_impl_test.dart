import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/data/repositories/settings_repository_impl.dart';
import 'package:melon_mod/domain/entities/auto_update_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

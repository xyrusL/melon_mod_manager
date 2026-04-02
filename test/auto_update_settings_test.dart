import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/domain/entities/auto_update_settings.dart';
import 'package:melon_mod/domain/services/auto_update_scheduler.dart';

void main() {
  group('AutoUpdateIntervalSetting', () {
    test('uses 8 hours as the default interval', () {
      expect(
        AutoUpdateIntervalSetting.defaultSetting.toDuration(),
        const Duration(hours: 8),
      );
    });

    test('preset durations map to the expected values', () {
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.hour1,
        ).toDuration(),
        const Duration(hours: 1),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.hour3,
        ).toDuration(),
        const Duration(hours: 3),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.hour8,
        ).toDuration(),
        const Duration(hours: 8),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.hour12,
        ).toDuration(),
        const Duration(hours: 12),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.day1,
        ).toDuration(),
        const Duration(days: 1),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.day2,
        ).toDuration(),
        const Duration(days: 2),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.week1,
        ).toDuration(),
        const Duration(days: 7),
      );
    });

    test('custom intervals support hours, days, and weeks within bounds', () {
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.custom,
          customValue: 6,
          customUnit: AutoUpdateIntervalUnit.hours,
        ).toDuration(),
        const Duration(hours: 6),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.custom,
          customValue: 2,
          customUnit: AutoUpdateIntervalUnit.days,
        ).toDuration(),
        const Duration(days: 2),
      );
      expect(
        const AutoUpdateIntervalSetting(
          preset: AutoUpdateIntervalPreset.custom,
          customValue: 1,
          customUnit: AutoUpdateIntervalUnit.weeks,
        ).toDuration(),
        const Duration(days: 7),
      );
    });

    test('rejects custom intervals longer than one week', () {
      const interval = AutoUpdateIntervalSetting(
        preset: AutoUpdateIntervalPreset.custom,
        customValue: 2,
        customUnit: AutoUpdateIntervalUnit.weeks,
      );

      expect(interval.isValid, isFalse);
      expect(
        interval.validationError(),
        'Use hours, days, or weeks only. The longest check interval is 1 week.',
      );
    });
  });

  group('AutoUpdateScheduler', () {
    test('runs only after the configured interval has elapsed', () {
      const scheduler = AutoUpdateScheduler();
      final now = DateTime(2026, 4, 2, 12);

      expect(
        scheduler.shouldRun(
          interval: const AutoUpdateIntervalSetting(
            preset: AutoUpdateIntervalPreset.hour8,
          ),
          lastCheckedAt: now.subtract(const Duration(hours: 7, minutes: 59)),
          now: now,
        ),
        isFalse,
      );

      expect(
        scheduler.shouldRun(
          interval: const AutoUpdateIntervalSetting(
            preset: AutoUpdateIntervalPreset.hour8,
          ),
          lastCheckedAt: now.subtract(const Duration(hours: 8)),
          now: now,
        ),
        isTrue,
      );
    });
  });
}

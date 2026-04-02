enum AutoUpdateTarget {
  app,
  mods,
  resourcePacks,
  shaderPacks,
}

enum AutoUpdateIntervalPreset {
  hour1,
  hour3,
  hour8,
  hour12,
  day1,
  day2,
  week1,
  custom,
}

enum AutoUpdateIntervalUnit {
  hours,
  days,
  weeks,
}

class AutoUpdateIntervalSetting {
  const AutoUpdateIntervalSetting({
    required this.preset,
    this.customValue = 8,
    this.customUnit = AutoUpdateIntervalUnit.hours,
  });

  static const defaultSetting = AutoUpdateIntervalSetting(
    preset: AutoUpdateIntervalPreset.hour8,
    customValue: 8,
    customUnit: AutoUpdateIntervalUnit.hours,
  );

  static const minimumDuration = Duration(hours: 1);
  static const maximumDuration = Duration(days: 7);

  final AutoUpdateIntervalPreset preset;
  final int customValue;
  final AutoUpdateIntervalUnit customUnit;

  Duration toDuration() {
    return switch (preset) {
      AutoUpdateIntervalPreset.hour1 => const Duration(hours: 1),
      AutoUpdateIntervalPreset.hour3 => const Duration(hours: 3),
      AutoUpdateIntervalPreset.hour8 => const Duration(hours: 8),
      AutoUpdateIntervalPreset.hour12 => const Duration(hours: 12),
      AutoUpdateIntervalPreset.day1 => const Duration(days: 1),
      AutoUpdateIntervalPreset.day2 => const Duration(days: 2),
      AutoUpdateIntervalPreset.week1 => const Duration(days: 7),
      AutoUpdateIntervalPreset.custom => _customDuration,
    };
  }

  String? validationError() {
    if (preset != AutoUpdateIntervalPreset.custom) {
      return null;
    }

    if (customValue < 1) {
      return 'Enter a number greater than 0.';
    }

    if (_customDuration > maximumDuration) {
      return 'Use hours, days, or weeks only. The longest check interval is 1 week.';
    }

    if (_customDuration < minimumDuration) {
      return 'The shortest check interval is 1 hour.';
    }

    return null;
  }

  bool get isValid => validationError() == null;

  AutoUpdateIntervalSetting copyWith({
    AutoUpdateIntervalPreset? preset,
    int? customValue,
    AutoUpdateIntervalUnit? customUnit,
  }) {
    return AutoUpdateIntervalSetting(
      preset: preset ?? this.preset,
      customValue: customValue ?? this.customValue,
      customUnit: customUnit ?? this.customUnit,
    );
  }

  Duration get _customDuration => switch (customUnit) {
        AutoUpdateIntervalUnit.hours => Duration(hours: customValue),
        AutoUpdateIntervalUnit.days => Duration(days: customValue),
        AutoUpdateIntervalUnit.weeks => Duration(days: customValue * 7),
      };
}

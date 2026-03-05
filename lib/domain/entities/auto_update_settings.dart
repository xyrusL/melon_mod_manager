enum AutoUpdateTarget {
  app,
  mods,
  resourcePacks,
  shaderPacks,
}

enum AutoUpdateIntervalPreset {
  off,
  day1,
  day3,
  week1,
  month1,
  custom,
}

class AutoUpdateIntervalSetting {
  const AutoUpdateIntervalSetting({
    required this.preset,
    this.customDays = 7,
  });

  const AutoUpdateIntervalSetting.off()
      : preset = AutoUpdateIntervalPreset.off,
        customDays = 7;

  final AutoUpdateIntervalPreset preset;
  final int customDays;

  Duration? toDuration() {
    return switch (preset) {
      AutoUpdateIntervalPreset.off => null,
      AutoUpdateIntervalPreset.day1 => const Duration(days: 1),
      AutoUpdateIntervalPreset.day3 => const Duration(days: 3),
      AutoUpdateIntervalPreset.week1 => const Duration(days: 7),
      AutoUpdateIntervalPreset.month1 => const Duration(days: 30),
      AutoUpdateIntervalPreset.custom =>
        Duration(days: customDays.clamp(1, 365)),
    };
  }

  AutoUpdateIntervalSetting copyWith({
    AutoUpdateIntervalPreset? preset,
    int? customDays,
  }) {
    return AutoUpdateIntervalSetting(
      preset: preset ?? this.preset,
      customDays: customDays ?? this.customDays,
    );
  }
}

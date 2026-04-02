import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/auto_update_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  static const _modsPathKey = 'mods_path';
  static const _appThemeModeKey = 'app_theme_mode';
  static const _lastSeenAppVersionKey = 'last_seen_app_version';
  static const _metadataPreparedVersionKey = 'metadata_prepared_app_version';
  static const _autoUpdateIntervalPrefix = 'auto_update_interval';
  static const _autoUpdateCustomValuePrefix = 'auto_update_custom_value';
  static const _autoUpdateCustomUnitPrefix = 'auto_update_custom_unit';
  static const _autoUpdateCustomDaysPrefix = 'auto_update_custom_days';
  static const _autoUpdateLastCheckedPrefix = 'auto_update_last_checked';

  final SharedPreferences _prefs;

  @override
  Future<String?> getModsPath() async {
    final value = _prefs.getString(_modsPathKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  @override
  Future<void> saveModsPath(String path) async {
    await _prefs.setString(_modsPathKey, path);
  }

  @override
  Future<AppThemeMode> getAppThemeMode() async {
    final raw = _prefs.getString(_appThemeModeKey);
    for (final value in AppThemeMode.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return AppThemeMode.defaultDark;
  }

  @override
  Future<void> saveAppThemeMode(AppThemeMode mode) async {
    await _prefs.setString(_appThemeModeKey, mode.name);
  }

  @override
  Future<String?> getLastSeenAppVersion() async {
    final value = _prefs.getString(_lastSeenAppVersionKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  @override
  Future<void> saveLastSeenAppVersion(String appVersion) async {
    await _prefs.setString(_lastSeenAppVersionKey, appVersion);
  }

  @override
  Future<PostUpdateMetadataState> getPostUpdateMetadataState(
    String currentVersion,
  ) async {
    final previousVersion = await getLastSeenAppVersion();
    final isFreshInstall = previousVersion == null;
    final isUpgrade = !isFreshInstall && previousVersion != currentVersion;
    final preparedVersion = _prefs.getString(_metadataPreparedVersionKey);

    return PostUpdateMetadataState(
      previousVersion: previousVersion,
      currentVersion: currentVersion,
      isFreshInstall: isFreshInstall,
      isUpgrade: isUpgrade,
      isMetadataPreparedForCurrentVersion: preparedVersion == currentVersion,
    );
  }

  @override
  Future<bool> shouldPrepareMetadataForAppVersion(String appVersion) async {
    final preparedVersion = _prefs.getString(_metadataPreparedVersionKey);
    return preparedVersion != appVersion;
  }

  @override
  Future<void> markMetadataPreparedForAppVersion(String appVersion) async {
    await _prefs.setString(_metadataPreparedVersionKey, appVersion);
  }

  @override
  Future<AutoUpdateIntervalSetting> getAutoUpdateInterval(
    AutoUpdateTarget target,
  ) async {
    final presetRaw = _prefs.getString(_intervalPresetKey(target));
    final preset = _parsePreset(presetRaw);
    final storedCustomValue =
        _prefs.getInt(_intervalCustomValueKey(target)) ??
            _prefs.getInt(_intervalLegacyCustomDaysKey(target)) ??
            7;
    final storedUnitRaw = _prefs.getString(_intervalCustomUnitKey(target));
    final customUnit = _parseUnit(storedUnitRaw) ??
        (storedUnitRaw == null
            ? AutoUpdateIntervalUnit.days
            : AutoUpdateIntervalSetting.defaultSetting.customUnit);

    if (preset == null) {
      return AutoUpdateIntervalSetting.defaultSetting;
    }

    if (preset == AutoUpdateIntervalPreset.custom) {
      return _migrateLegacyCustomSetting(
        customValue: storedCustomValue,
        customUnit: customUnit,
      );
    }

    return AutoUpdateIntervalSetting(
      preset: preset,
      customValue: storedCustomValue,
      customUnit: customUnit,
    );
  }

  @override
  Future<void> saveAutoUpdateInterval(
    AutoUpdateTarget target,
    AutoUpdateIntervalSetting interval,
  ) async {
    if (!interval.isValid) {
      throw ArgumentError(interval.validationError());
    }
    await _prefs.setString(_intervalPresetKey(target), interval.preset.name);
    await _prefs.setInt(
      _intervalCustomValueKey(target),
      interval.customValue,
    );
    await _prefs.setString(
      _intervalCustomUnitKey(target),
      interval.customUnit.name,
    );
  }

  @override
  Future<DateTime?> getLastAutoUpdateCheckAt(AutoUpdateTarget target) async {
    final raw = _prefs.getInt(_lastCheckedKey(target));
    if (raw == null || raw <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  @override
  Future<void> markAutoUpdateCheckAt(
    AutoUpdateTarget target,
    DateTime timestamp,
  ) async {
    await _prefs.setInt(
      _lastCheckedKey(target),
      timestamp.millisecondsSinceEpoch,
    );
  }

  String _targetKey(AutoUpdateTarget target) => switch (target) {
        AutoUpdateTarget.app => 'app',
        AutoUpdateTarget.mods => 'mods',
        AutoUpdateTarget.resourcePacks => 'resource_packs',
        AutoUpdateTarget.shaderPacks => 'shader_packs',
      };

  String _intervalPresetKey(AutoUpdateTarget target) =>
      '${_autoUpdateIntervalPrefix}_${_targetKey(target)}';

  String _intervalCustomValueKey(AutoUpdateTarget target) =>
      '${_autoUpdateCustomValuePrefix}_${_targetKey(target)}';

  String _intervalCustomUnitKey(AutoUpdateTarget target) =>
      '${_autoUpdateCustomUnitPrefix}_${_targetKey(target)}';

  String _intervalLegacyCustomDaysKey(AutoUpdateTarget target) =>
      '${_autoUpdateCustomDaysPrefix}_${_targetKey(target)}';

  String _lastCheckedKey(AutoUpdateTarget target) =>
      '${_autoUpdateLastCheckedPrefix}_${_targetKey(target)}';

  AutoUpdateIntervalPreset? _parsePreset(String? raw) {
    switch (raw) {
      case null:
      case '':
      case 'off':
        return AutoUpdateIntervalPreset.hour8;
      case 'month1':
        return AutoUpdateIntervalPreset.week1;
    }

    for (final value in AutoUpdateIntervalPreset.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  AutoUpdateIntervalUnit? _parseUnit(String? raw) {
    for (final value in AutoUpdateIntervalUnit.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }

  AutoUpdateIntervalSetting _migrateLegacyCustomSetting({
    required int customValue,
    required AutoUpdateIntervalUnit customUnit,
  }) {
    final sanitizedValue = customValue < 1 ? 1 : customValue;
    final candidate = AutoUpdateIntervalSetting(
      preset: AutoUpdateIntervalPreset.custom,
      customValue: sanitizedValue,
      customUnit: customUnit,
    );

    if (candidate.isValid) {
      return candidate;
    }

    return const AutoUpdateIntervalSetting(
      preset: AutoUpdateIntervalPreset.custom,
      customValue: 1,
      customUnit: AutoUpdateIntervalUnit.weeks,
    );
  }
}

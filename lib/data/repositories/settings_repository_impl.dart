import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auto_update_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  static const _modsPathKey = 'mods_path';
  static const _metadataPreparedVersionKey = 'metadata_prepared_app_version';
  static const _autoUpdateIntervalPrefix = 'auto_update_interval';
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
    AutoUpdateIntervalPreset? preset;
    for (final value in AutoUpdateIntervalPreset.values) {
      if (value.name == presetRaw) {
        preset = value;
        break;
      }
    }
    final customDays = _prefs.getInt(_intervalCustomDaysKey(target)) ?? 7;
    if (preset == null) {
      return const AutoUpdateIntervalSetting.off();
    }
    return AutoUpdateIntervalSetting(
      preset: preset,
      customDays: customDays.clamp(1, 365),
    );
  }

  @override
  Future<void> saveAutoUpdateInterval(
    AutoUpdateTarget target,
    AutoUpdateIntervalSetting interval,
  ) async {
    await _prefs.setString(_intervalPresetKey(target), interval.preset.name);
    await _prefs.setInt(
      _intervalCustomDaysKey(target),
      interval.customDays.clamp(1, 365),
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

  String _intervalCustomDaysKey(AutoUpdateTarget target) =>
      '${_autoUpdateCustomDaysPrefix}_${_targetKey(target)}';

  String _lastCheckedKey(AutoUpdateTarget target) =>
      '${_autoUpdateLastCheckedPrefix}_${_targetKey(target)}';
}

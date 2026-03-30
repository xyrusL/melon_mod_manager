import '../entities/auto_update_settings.dart';

abstract class SettingsRepository {
  Future<String?> getModsPath();

  Future<void> saveModsPath(String path);

  Future<String?> getLastSeenAppVersion();

  Future<void> saveLastSeenAppVersion(String appVersion);

  Future<bool> shouldPrepareMetadataForAppVersion(String appVersion);

  Future<void> markMetadataPreparedForAppVersion(String appVersion);

  Future<AutoUpdateIntervalSetting> getAutoUpdateInterval(
    AutoUpdateTarget target,
  );

  Future<void> saveAutoUpdateInterval(
    AutoUpdateTarget target,
    AutoUpdateIntervalSetting interval,
  );

  Future<DateTime?> getLastAutoUpdateCheckAt(AutoUpdateTarget target);

  Future<void> markAutoUpdateCheckAt(
    AutoUpdateTarget target,
    DateTime timestamp,
  );
}

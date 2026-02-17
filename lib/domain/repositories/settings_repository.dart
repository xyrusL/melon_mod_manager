abstract class SettingsRepository {
  Future<String?> getModsPath();

  Future<void> saveModsPath(String path);

  Future<bool> shouldPrepareMetadataForAppVersion(String appVersion);

  Future<void> markMetadataPreparedForAppVersion(String appVersion);
}

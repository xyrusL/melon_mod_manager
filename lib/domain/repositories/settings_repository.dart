abstract class SettingsRepository {
  Future<String?> getModsPath();

  Future<void> saveModsPath(String path);
}

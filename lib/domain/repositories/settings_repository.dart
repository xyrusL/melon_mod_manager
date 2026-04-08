import '../entities/app_theme_mode.dart';
import '../entities/auto_update_settings.dart';

class PostUpdateMetadataState {
  const PostUpdateMetadataState({
    required this.previousVersion,
    required this.currentVersion,
    required this.isFreshInstall,
    required this.isUpgrade,
    required this.isMetadataPreparedForCurrentVersion,
  });

  final String? previousVersion;
  final String currentVersion;
  final bool isFreshInstall;
  final bool isUpgrade;
  final bool isMetadataPreparedForCurrentVersion;

  bool get shouldPromptForRefresh =>
      isUpgrade && !isMetadataPreparedForCurrentVersion;

  bool get shouldWarmUpInBackground =>
      !isUpgrade && !isMetadataPreparedForCurrentVersion;
}

abstract class SettingsRepository {
  Future<String?> getModsPath();

  Future<void> saveModsPath(String path);

  Future<AppThemeMode> getAppThemeMode();

  Future<void> saveAppThemeMode(AppThemeMode mode);

  Future<bool> getHasCompletedWelcomeFlow();

  Future<void> markWelcomeFlowCompleted();

  Future<String?> getLastSeenAppVersion();

  Future<void> saveLastSeenAppVersion(String appVersion);

  Future<PostUpdateMetadataState> getPostUpdateMetadataState(
    String currentVersion,
  );

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

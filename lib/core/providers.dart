import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/github_api_client.dart';
import '../data/repositories/modrinth_mapping_repository_impl.dart';
import '../data/repositories/modrinth_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/services/file_install_service.dart';
import '../data/services/minecraft_path_service.dart';
import '../data/services/minecraft_version_service.dart';
import '../data/services/mod_scanner_service.dart';
import '../data/services/modrinth_api_client.dart';
import '../domain/repositories/modrinth_mapping_repository.dart';
import '../domain/repositories/modrinth_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/entities/developer_snapshot.dart';
import '../domain/services/dependency_resolver_service.dart';
import '../domain/usecases/install_mod_usecase.dart';
import '../domain/usecases/install_queue_usecase.dart';
import '../domain/usecases/update_mods_usecase.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);

final mappingBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError('Hive box not initialized'),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider));
});

final mappingRepositoryProvider = Provider<ModrinthMappingRepository>((ref) {
  return ModrinthMappingRepositoryImpl(ref.watch(mappingBoxProvider));
});

final modrinthApiClientProvider = Provider<ModrinthApiClient>((ref) {
  return ModrinthApiClient(client: ref.watch(httpClientProvider));
});

final gitHubApiClientProvider = Provider<GitHubApiClient>((ref) {
  return GitHubApiClient(client: ref.watch(httpClientProvider));
});

const _developerGitHubUsername = 'xyrusL';
const _projectRepositoryName = 'melon_mod_manager';
const projectRepositoryUrl =
    'https://github.com/$_developerGitHubUsername/$_projectRepositoryName';

final developerSnapshotProvider =
    FutureProvider.autoDispose<DeveloperSnapshot>((ref) async {
  final api = ref.watch(gitHubApiClientProvider);
  final profile = await api.getUserProfile(_developerGitHubUsername);
  final repo = await api.getRepository(
    _developerGitHubUsername,
    _projectRepositoryName,
  );
  return DeveloperSnapshot(
    profile: profile.toEntity(),
    repository: repo.toEntity(),
  );
});

final appVersionLabelProvider = FutureProvider.autoDispose<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version} (Beta)';
});

final modrinthRepositoryProvider = Provider<ModrinthRepository>((ref) {
  return ModrinthRepositoryImpl(ref.watch(modrinthApiClientProvider));
});

final minecraftPathServiceProvider = Provider<MinecraftPathService>((ref) {
  return MinecraftPathService();
});

final minecraftVersionServiceProvider =
    Provider<MinecraftVersionService>((ref) {
  return MinecraftVersionService();
});

final modScannerServiceProvider = Provider<ModScannerService>((ref) {
  return ModScannerService();
});

final fileInstallServiceProvider = Provider<FileInstallService>((ref) {
  return FileInstallService();
});

final dependencyResolverServiceProvider =
    Provider<DependencyResolverService>((ref) {
  return DependencyResolverService(
    modrinthRepository: ref.watch(modrinthRepositoryProvider),
    mappingRepository: ref.watch(mappingRepositoryProvider),
  );
});

final installQueueUsecaseProvider = Provider<InstallQueueUsecase>((ref) {
  return InstallQueueUsecase(
    modrinthRepository: ref.watch(modrinthRepositoryProvider),
    mappingRepository: ref.watch(mappingRepositoryProvider),
  );
});

final installModUsecaseProvider = Provider<InstallModUsecase>((ref) {
  return InstallModUsecase(
    dependencyResolverService: ref.watch(dependencyResolverServiceProvider),
    installQueueUsecase: ref.watch(installQueueUsecaseProvider),
  );
});

final updateModsUsecaseProvider = Provider<UpdateModsUsecase>((ref) {
  return UpdateModsUsecase(
    modrinthRepository: ref.watch(modrinthRepositoryProvider),
    mappingRepository: ref.watch(mappingRepositoryProvider),
  );
});

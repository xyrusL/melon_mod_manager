import 'package:flutter_riverpod/legacy.dart';

import '../../core/providers.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';

enum AppStatus { loading, setup, ready }

class AppState {
  const AppState({
    required this.status,
    this.modsPath,
    this.error,
    this.themeMode = AppThemeMode.defaultDark,
  });

  final AppStatus status;
  final String? modsPath;
  final String? error;
  final AppThemeMode themeMode;

  AppState copyWith({
    AppStatus? status,
    String? modsPath,
    String? error,
    AppThemeMode? themeMode,
  }) {
    return AppState(
      status: status ?? this.status,
      modsPath: modsPath ?? this.modsPath,
      error: error,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

final appControllerProvider = StateNotifierProvider<AppController, AppState>((
  ref,
) {
  return AppController(ref.watch(settingsRepositoryProvider));
});

class AppController extends StateNotifier<AppState> {
  AppController(this._settingsRepository)
      : super(const AppState(status: AppStatus.loading)) {
    _bootstrap();
  }

  final SettingsRepository _settingsRepository;

  Future<void> _bootstrap() async {
    try {
      final path = await _settingsRepository.getModsPath();
      final themeMode = await _settingsRepository.getAppThemeMode();
      if (path == null || path.trim().isEmpty) {
        state = AppState(status: AppStatus.setup, themeMode: themeMode);
      } else {
        state = AppState(
          status: AppStatus.ready,
          modsPath: path,
          themeMode: themeMode,
        );
      }
    } catch (error) {
      state = AppState(status: AppStatus.setup, error: error.toString());
    }
  }

  Future<void> saveModsPath(String path) async {
    await _settingsRepository.saveModsPath(path);
    state = AppState(
      status: AppStatus.ready,
      modsPath: path,
      themeMode: state.themeMode,
    );
  }

  Future<void> saveThemeMode(AppThemeMode mode) async {
    await _settingsRepository.saveAppThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }
}

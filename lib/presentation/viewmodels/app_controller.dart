import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/repositories/settings_repository.dart';

enum AppStatus { loading, setup, ready }

class AppState {
  const AppState({required this.status, this.modsPath, this.error});

  final AppStatus status;
  final String? modsPath;
  final String? error;

  AppState copyWith({AppStatus? status, String? modsPath, String? error}) {
    return AppState(
      status: status ?? this.status,
      modsPath: modsPath ?? this.modsPath,
      error: error,
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
      if (path == null || path.trim().isEmpty) {
        state = const AppState(status: AppStatus.setup);
      } else {
        state = AppState(status: AppStatus.ready, modsPath: path);
      }
    } catch (error) {
      state = AppState(status: AppStatus.setup, error: error.toString());
    }
  }

  Future<void> saveModsPath(String path) async {
    await _settingsRepository.saveModsPath(path);
    state = AppState(status: AppStatus.ready, modsPath: path);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/app_update_service.dart';
import '../../domain/entities/github_release.dart';
import '../../core/providers.dart';

enum AppUpdateCheckStatus { idle, checking, upToDate, updateAvailable, error }

class AppUpdateState {
  const AppUpdateState({
    this.status = AppUpdateCheckStatus.idle,
    this.currentVersion,
    this.latestRelease,
    this.message,
    this.checkedAt,
  });

  final AppUpdateCheckStatus status;
  final String? currentVersion;
  final GitHubRelease? latestRelease;
  final String? message;
  final DateTime? checkedAt;

  AppUpdateState copyWith({
    AppUpdateCheckStatus? status,
    String? currentVersion,
    GitHubRelease? latestRelease,
    String? message,
    DateTime? checkedAt,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestRelease: latestRelease ?? this.latestRelease,
      message: message,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}

final appUpdateControllerProvider =
    StateNotifierProvider<AppUpdateController, AppUpdateState>((ref) {
  return AppUpdateController(ref.watch(appUpdateServiceProvider));
});

class AppUpdateController extends StateNotifier<AppUpdateState> {
  AppUpdateController(this._service) : super(const AppUpdateState()) {
    Future<void>.microtask(() => checkForUpdates(silent: true));
  }

  final AppUpdateService _service;

  Future<void> checkForUpdates({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(status: AppUpdateCheckStatus.checking, message: null);
    }

    try {
      final result = await _service.checkForUpdate();
      state = state.copyWith(
        status: result.hasUpdate
            ? AppUpdateCheckStatus.updateAvailable
            : AppUpdateCheckStatus.upToDate,
        currentVersion: result.currentVersion,
        latestRelease: result.latestRelease,
        message: result.hasUpdate
            ? 'New version available: ${result.latestRelease.tagName}'
            : 'You are on the latest version.',
        checkedAt: DateTime.now(),
      );
    } catch (error) {
      state = state.copyWith(
        status: AppUpdateCheckStatus.error,
        message: 'Failed to check app updates: $error',
        checkedAt: DateTime.now(),
      );
    }
  }
}

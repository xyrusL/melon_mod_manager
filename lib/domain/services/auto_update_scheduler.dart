import '../entities/auto_update_settings.dart';

class AutoUpdateScheduler {
  const AutoUpdateScheduler();

  bool shouldRun({
    required AutoUpdateIntervalSetting interval,
    required DateTime? lastCheckedAt,
    DateTime? now,
  }) {
    final duration = interval.toDuration();
    if (lastCheckedAt == null) {
      return true;
    }

    final current = now ?? DateTime.now();
    return current.difference(lastCheckedAt) >= duration;
  }
}

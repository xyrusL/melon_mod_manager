import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  static const _modsPathKey = 'mods_path';

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
}

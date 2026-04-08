import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/presentation/viewmodels/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fresh install enters welcome flow before setup', () async {
    final prefs = await _prefs({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await _pumpUntilReady(container);

    expect(container.read(appControllerProvider).status, AppStatus.welcome);
  });

  test('completed welcome without saved path enters setup', () async {
    final prefs = await _prefs({
      'has_completed_welcome_flow': true,
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await _pumpUntilReady(container);

    expect(container.read(appControllerProvider).status, AppStatus.setup);
  });

  test('completed welcome with saved path enters ready', () async {
    final prefs = await _prefs({
      'has_completed_welcome_flow': true,
      'mods_path': r'C:\Users\johnp\AppData\Roaming\.minecraft\mods',
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await _pumpUntilReady(container);

    final state = container.read(appControllerProvider);
    expect(state.status, AppStatus.ready);
    expect(state.modsPath, r'C:\Users\johnp\AppData\Roaming\.minecraft\mods');
  });

  test('existing user with previous version skips welcome even without flag',
      () async {
    final prefs = await _prefs({
      'last_seen_app_version': '1.7.7',
    });
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await _pumpUntilReady(container);

    expect(container.read(appControllerProvider).status, AppStatus.setup);
  });
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> _pumpUntilReady(ProviderContainer container) async {
  while (container.read(appControllerProvider).status == AppStatus.loading) {
    await Future<void>.delayed(Duration.zero);
  }
}

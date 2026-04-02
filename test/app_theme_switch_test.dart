import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/app.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/domain/entities/app_theme_mode.dart';
import 'package:melon_mod/presentation/viewmodels/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app root uses default theme when no preference is stored',
      (tester) async {
    final prefs = await _prefs({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MelonModApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, const Color(0xFF5AFFA7));
  });

  testWidgets('changing theme mode updates the app theme live', (tester) async {
    final prefs = await _prefs({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MelonModApp(),
      ),
    );
    await tester.pumpAndSettle();

    await container
        .read(appControllerProvider.notifier)
        .saveThemeMode(AppThemeMode.modernDark);
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, const Color(0xFF64E4FF));
  });

  testWidgets('selected theme persists after rebuilding the app', (tester) async {
    final prefs = await _prefs({});
    final firstContainer = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(firstContainer.dispose);

    await firstContainer
        .read(appControllerProvider.notifier)
        .saveThemeMode(AppThemeMode.modernDark);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: firstContainer,
        child: const MelonModApp(),
      ),
    );
    await tester.pumpAndSettle();

    final secondContainer = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(secondContainer.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: secondContainer,
        child: const MelonModApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.colorScheme.primary, const Color(0xFF64E4FF));
  });
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

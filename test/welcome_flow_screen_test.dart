import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/presentation/screens/welcome_flow_screen.dart';
import 'package:melon_mod/presentation/viewmodels/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('welcome flow shows thank-you copy with next and skip', (
    tester,
  ) async {
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
        child: const MaterialApp(
          home: WelcomeFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Melon Mod Manager'), findsOneWidget);
    expect(find.textContaining('Thanks for downloading Melon'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('final action completes onboarding and moves to setup', (
    tester,
  ) async {
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
        child: const MaterialApp(
          home: WelcomeFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Start Setup'), findsOneWidget);
    await tester.tap(find.text('Start Setup'));
    await tester.pumpAndSettle();

    final state = container.read(appControllerProvider);
    expect(state.status, AppStatus.setup);
  });
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

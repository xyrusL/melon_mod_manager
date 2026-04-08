import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/core/theme/app_theme.dart';
import 'package:melon_mod/domain/entities/app_theme_mode.dart';
import 'package:melon_mod/presentation/screens/welcome_flow_screen.dart';
import 'package:melon_mod/presentation/viewmodels/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('welcome flow shows thank-you copy with next and skip', (
    tester,
  ) async {
    await _setDesktopViewport(tester);
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
        child: MaterialApp(
          theme: AppTheme.themeFor(AppThemeMode.defaultDark),
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
    await _setDesktopViewport(tester);
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
        child: MaterialApp(
          theme: AppTheme.themeFor(AppThemeMode.defaultDark),
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

    final state = await _waitForAppState(container);
    expect(state.status, AppStatus.setup);
  });
}

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> _setDesktopViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<AppState> _waitForAppState(ProviderContainer container) async {
  AppState state = container.read(appControllerProvider);
  while (state.status == AppStatus.loading) {
    await Future<void>.delayed(Duration.zero);
    state = container.read(appControllerProvider);
  }
  return state;
}

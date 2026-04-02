import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/data/repositories/settings_repository_impl.dart';
import 'package:melon_mod/presentation/widgets/action_panel.dart';
import 'package:melon_mod/presentation/widgets/refresh_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'update settings dialog shows 1.7.4 intervals and cleaner theme picker',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepositoryImpl(prefs);

    await tester.pumpWidget(
      _buildTestApp(repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check Frequency'), findsOneWidget);
    expect(find.text('Every 8 hours'), findsOneWidget);
    expect(find.text('Switch themes any time. Changes show up right away.'),
        findsOneWidget);
    expect(find.text('Melon Default'), findsOneWidget);
    expect(find.text('Midnight Glass'), findsOneWidget);
    expect(find.text('Off'), findsNothing);
    expect(find.text('Every month'), findsNothing);

    await tester.tap(find.text('Every 8 hours').first);
    await tester.pumpAndSettle();

    expect(find.text('Every 1 hour').last, findsOneWidget);
    expect(find.text('Every 3 hours').last, findsOneWidget);
    expect(find.text('Every 12 hours').last, findsOneWidget);
    expect(find.text('Every 2 days').last, findsOneWidget);
  });

  testWidgets(
      'custom settings use value plus unit and block intervals above one week',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepositoryImpl(prefs);

    await tester.pumpWidget(
      _buildTestApp(repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Every 8 hours').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Value'), findsOneWidget);
    expect(find.text('Unit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '169');
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Use hours, days, or weeks only. The longest check interval is 1 week.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Update Settings'), findsOneWidget);
  });
}

Widget _buildTestApp(SettingsRepositoryImpl repository) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: UpdateSettingsDialog(
          onForceRefreshData: _noopRefresh,
        ),
      ),
    ),
  );
}

Future<String> _noopRefresh(RefreshProgressCallback onProgress) async {
  return 'Done';
}

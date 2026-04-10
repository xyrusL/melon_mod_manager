import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melon_mod/core/providers.dart';
import 'package:melon_mod/data/repositories/settings_repository_impl.dart';
import 'package:melon_mod/data/services/app_update_service.dart';
import 'package:melon_mod/data/services/github_api_client.dart';
import 'package:melon_mod/domain/entities/github_release.dart';
import 'package:melon_mod/presentation/viewmodels/app_update_controller.dart';
import 'package:melon_mod/presentation/widgets/action_panel.dart';
import 'package:melon_mod/presentation/widgets/panel_action_button.dart';
import 'package:melon_mod/presentation/widgets/refresh_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app update button uses update icon while idle', (tester) async {
    final repository = await _buildRepository();

    await tester.pumpWidget(
      _buildPanel(
        repository: repository,
        appUpdateState: const AppUpdateState(
          status: AppUpdateCheckStatus.idle,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('App Update'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedActionIcon &&
            widget.icon == Icons.update_rounded &&
            !widget.animate,
      ),
      findsOneWidget,
    );
  });

  testWidgets('app update button uses rotating refresh icon while checking',
      (tester) async {
    final repository = await _buildRepository();

    await tester.pumpWidget(
      _buildPanel(
        repository: repository,
        appUpdateState: const AppUpdateState(
          status: AppUpdateCheckStatus.checking,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Checking'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedActionIcon &&
            widget.icon == Icons.autorenew_rounded &&
            widget.animate,
      ),
      findsOneWidget,
    );
  });

  testWidgets('metadata banner uses animated icon instead of progress spinner',
      (tester) async {
    final repository = await _buildRepository();

    await tester.pumpWidget(
      _buildPanel(
        repository: repository,
        appUpdateState: const AppUpdateState(),
        isBusy: true,
      ),
    );
    await tester.pump();

    expect(find.text('Preparing metadata...'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedActionIcon &&
            widget.icon == Icons.autorenew_rounded &&
            widget.animate &&
            widget.color == const Color(0xFF57F1B4),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

Future<SettingsRepositoryImpl> _buildRepository() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return SettingsRepositoryImpl(prefs);
}

Widget _buildPanel({
  required SettingsRepositoryImpl repository,
  required AppUpdateState appUpdateState,
  bool isBusy = false,
}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      appVersionLabelProvider.overrideWith((ref) async => 'v1.7.4'),
      environmentInfoProvider.overrideWith(
        (ref, modsPath) async => const EnvironmentInfoSnapshot(
          minecraftVersion: '1.21.1',
          loaderName: 'Fabric',
          loaderVersion: '0.18.4',
        ),
      ),
      appUpdateControllerProvider.overrideWith(
        (ref) => _FakeAppUpdateController(appUpdateState),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ActionPanel(
          modsPath: r'C:\melon\mods',
          onDownloadMods: () {},
          onCheckUpdates: () {},
          onAddFile: () {},
          onImportZip: () {},
          onExportZip: () {},
          onDeleteSelected: () {},
          onForceRefreshData: _noopRefresh,
          isBusy: isBusy,
          hasDeleteSelection: false,
          downloadLabel: 'Download Mods',
          actionsEnabled: true,
        ),
      ),
    ),
  );
}

Future<String> _noopRefresh(RefreshProgressCallback onProgress) async => 'Done';

class _FakeAppUpdateController extends AppUpdateController {
  _FakeAppUpdateController(AppUpdateState initialState)
      : super(_FakeAppUpdateService()) {
    state = initialState;
  }
}

class _FakeAppUpdateService extends AppUpdateService {
  _FakeAppUpdateService()
      : super(
          apiClient: GitHubApiClient(
            client: MockClient(
              (_) async => http.Response('{}', 200),
            ),
          ),
          owner: 'xyrusL',
          repository: 'melon_mod_manager',
          currentVersionProvider: () async => '1.7.4',
        );

  @override
  Future<AppUpdateResult> checkForUpdate() async {
    return AppUpdateResult(
      currentVersion: '1.7.4',
      latestRelease: const GitHubRelease(
        tagName: 'v1.7.4',
        name: 'v1.7.4',
        htmlUrl: 'https://example.com',
        body: '',
        prerelease: false,
        draft: false,
        publishedAt: null,
      ),
      hasUpdate: false,
    );
  }
}

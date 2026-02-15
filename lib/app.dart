import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/setup_screen.dart';
import 'presentation/viewmodels/app_controller.dart';

class MelonModApp extends ConsumerWidget {
  const MelonModApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);

    return MaterialApp(
      title: 'Melon Mod Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: switch (appState.status) {
        AppStatus.loading => const _LoadingView(),
        AppStatus.setup => const SetupScreen(),
        AppStatus.ready => MainScreen(modsPath: appState.modsPath!),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_error_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/setup_screen.dart';
import 'presentation/screens/welcome_flow_screen.dart';
import 'presentation/viewmodels/app_controller.dart';

class MelonModApp extends ConsumerWidget {
  const MelonModApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appControllerProvider);

    return MaterialApp(
      title: 'Melon Mod Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(appState.themeMode),
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const _GlobalErrorOverlay(),
        ],
      ),
      home: switch (appState.status) {
        AppStatus.loading => const _LoadingView(),
        AppStatus.welcome => const WelcomeFlowScreen(),
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

class _GlobalErrorOverlay extends StatefulWidget {
  const _GlobalErrorOverlay();

  @override
  State<_GlobalErrorOverlay> createState() => _GlobalErrorOverlayState();
}

class _GlobalErrorOverlayState extends State<_GlobalErrorOverlay> {
  final AppErrorService _service = AppErrorService.instance;
  late final ScrollController _errorLogScrollController;

  @override
  void initState() {
    super.initState();
    _errorLogScrollController = ScrollController();
  }

  @override
  void dispose() {
    _errorLogScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final fatal = _service.activeFatal;
        if (fatal == null) {
          return const SizedBox.shrink();
        }

        final logText = _service.buildLogText();
        final shortMessage = fatal.shortMessage;

        return Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.65),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 900, maxHeight: 620),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101824),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The app hit an unexpected error.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shortMessage,
                        style: TextStyle(
                          color: Colors.redAccent.shade100,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          'This is an internal app error. Copy or export the log and send it with the steps that triggered the issue so it can be reproduced.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Scrollbar(
                            controller: _errorLogScrollController,
                            thumbVisibility: true,
                            interactive: true,
                            radius: const Radius.circular(99),
                            thickness: 5,
                            child: SingleChildScrollView(
                              controller: _errorLogScrollController,
                              primary: false,
                              padding: const EdgeInsets.only(right: 10),
                              child: SelectableText(
                                logText,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _copyLog(logText),
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Log'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _exportLog(logText),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export Log'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _service.dismissActiveFatal,
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyLog(String logText) async {
    await Clipboard.setData(ClipboardData(text: logText));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error log copied to clipboard.')),
    );
  }

  Future<void> _exportLog(String logText) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final targetPath = await FilePicker.saveFile(
      dialogTitle: 'Export error log',
      fileName: 'melon_mod_error_$timestamp.log',
      lockParentWindow: true,
    );

    if (targetPath == null || targetPath.trim().isEmpty) {
      return;
    }

    await File(targetPath).writeAsString(logText);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error log exported to $targetPath')),
    );
  }
}

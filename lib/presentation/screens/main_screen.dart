import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/file_install_service.dart';
import '../dialogs/confirm_overwrite_dialog.dart';
import '../dialogs/modrinth_search_dialog.dart';
import '../viewmodels/app_controller.dart';
import '../viewmodels/mods_controller.dart';
import '../widgets/action_panel.dart';
import '../widgets/mods_table.dart';
import '../widgets/status_banner.dart';
import '../widgets/top_bar.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.modsPath});

  final String modsPath;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(modsControllerProvider.notifier).loadMods(widget.modsPath),
    );
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modsPath != widget.modsPath) {
      ref.read(modsControllerProvider.notifier).loadMods(widget.modsPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modsControllerProvider);
    final notifier = ref.read(modsControllerProvider.notifier);
    final filteredMods = state.filteredMods();

    return Container(
      decoration: AppTheme.appBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final uiScale = _computeUiScale(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
            final sidePanelWidth =
                (constraints.maxWidth * 0.24).clamp(260.0, 360.0).toDouble();
            final pagePadding = (18 * uiScale).clamp(18, 24).toDouble();
            final contentGap = (14 * uiScale).clamp(14, 20).toDouble();

            return Padding(
              padding: EdgeInsets.all(pagePadding),
              child: Column(
                children: [
                  TopBar(
                    currentPath: widget.modsPath,
                    isBusy: state.isScanning || state.isBusy,
                    uiScale: uiScale,
                    onRefresh: () async {
                      ref.invalidate(developerSnapshotProvider);
                      ref.invalidate(environmentInfoProvider(widget.modsPath));
                      await notifier.loadMods(widget.modsPath);
                    },
                    onBrowsePath: _browseNewPath,
                    onAutoDetectPath: _autoDetectPath,
                  ),
                  if (state.errorMessage != null ||
                      state.infoMessage != null) ...[
                    SizedBox(height: (10 * uiScale).clamp(10, 14).toDouble()),
                    StatusBanner(
                      message: state.errorMessage ?? state.infoMessage!,
                      isError: state.errorMessage != null,
                      onDismiss: notifier.clearMessages,
                    ),
                  ],
                  SizedBox(height: contentGap),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: AppTheme.glassPanel(),
                            padding: EdgeInsets.all(
                              (8 * uiScale).clamp(8, 12).toDouble(),
                            ),
                            child: ModsTable(
                              mods: filteredMods,
                              selectedFiles: state.selectedFiles,
                              onToggleSelected: notifier.toggleModSelection,
                              onToggleSelectAllVisible: (selected) =>
                                  notifier.toggleSelectAllVisible(
                                      filteredMods, selected),
                              isScanning: state.isScanning,
                              processed: state.scanProcessed,
                              total: state.scanTotal,
                              uiScale: uiScale,
                            ),
                          ),
                        ),
                        SizedBox(width: contentGap),
                        SizedBox(
                          width: sidePanelWidth,
                          child: ActionPanel(
                            modsPath: widget.modsPath,
                            isBusy: state.isBusy,
                            hasDeleteSelection: state.selectedFiles.isNotEmpty,
                            uiScale: uiScale,
                        onDownloadMods: _openModrinthSearch,
                            onCheckUpdates: _checkUpdatesWithReview,
                            onAddFile: _addFiles,
                            onDeleteSelected: _deleteSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _computeUiScale({required double width, required double height}) {
    const baseWidth = 1100.0;
    const baseHeight = 650.0;
    final scale = (width / baseWidth).clamp(1.0, 1.3);
    final heightScale = (height / baseHeight).clamp(1.0, 1.2);
    return (scale < heightScale ? scale : heightScale).toDouble();
  }

  Future<void> _openModrinthSearch() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ModrinthSearchDialog(modsPath: widget.modsPath),
    );
  }

  Future<void> _addFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jar'],
    );

    final paths = picked?.paths.whereType<String>().toList() ?? const [];
    if (paths.isEmpty || !mounted) {
      return;
    }

    await ref.read(modsControllerProvider.notifier).installExternalFiles(
          modsPath: widget.modsPath,
          sourcePaths: paths,
          onConflict: _resolveConflict,
        );
  }

  Future<void> _deleteSelected() async {
    final selectedCount = ref.read(modsControllerProvider).selectedFiles.length;
    if (selectedCount == 0 || !mounted) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected mods?'),
        content: Text(
          'This will permanently delete $selectedCount selected mod file(s) from your mods folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A7D),
              foregroundColor: Colors.black,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    await ref.read(modsControllerProvider.notifier).deleteSelectedMods(
          widget.modsPath,
        );
  }

  Future<ConflictResolution> _resolveConflict(String fileName) async {
    final result = await showDialog<ConflictResolution>(
      context: context,
      builder: (context) => ConfirmOverwriteDialog(fileName: fileName),
    );
    return result ?? ConflictResolution.skip;
  }

  Future<void> _browseNewPath() async {
    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected == null || !mounted) {
      return;
    }

    final pathService = ref.read(minecraftPathServiceProvider);
    final normalized = pathService.normalizeSelectedPath(selected);
    await _applyPath(normalized);
  }

  Future<void> _autoDetectPath() async {
    final pathService = ref.read(minecraftPathServiceProvider);
    final detected = await pathService.detectDefaultModsPath();
    if (!mounted) {
      return;
    }
    if (detected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          backgroundColor: const Color(0xFF3A1420),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFFF6A7D), width: 1),
          ),
          content: const Text(
            'Could not auto-detect a default mods folder.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    await _applyPath(detected);
  }

  Future<void> _checkUpdatesWithReview() async {
    final notifier = ref.read(modsControllerProvider.notifier);
    final preview = await showDialog<UpdateCheckPreview>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateCheckProgressDialog(
        runCheck: (onProgress) =>
            notifier.checkForUpdatesPreview(onProgress: onProgress),
      ),
    );

    if (!mounted || preview == null) {
      return;
    }

    if (preview.totalChecked == 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => const _UpdateResultDialog(
          title: 'Update Check Complete',
          message: 'No mods available for update.',
        ),
      );
      return;
    }

    if (preview.updates.isEmpty) {
      final scope = preview.selectedOnly ? 'selected mods' : 'all mods';
      await showDialog<void>(
        context: context,
        builder: (context) => _UpdateResultDialog(
          title: 'No Updates Found',
          message: 'Checked ${preview.totalChecked} mod(s) in $scope.\n'
              'Everything is already up to date.',
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => _UpdateConfirmDialog(preview: preview),
    );

    if (confirm != true || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateRunDialog(
        total: preview.updates.length,
        run: () async {
          final summary = await notifier.runUpdatesForMods(
            modsPath: widget.modsPath,
            mods: preview.updates.map((e) => e.mod).toList(),
            selectedOnly: preview.selectedOnly,
          );
          return 'Checked ${summary.totalChecked} mod(s)\n'
              'Updated: ${summary.updated}\n'
              'Up to date: ${summary.alreadyLatest}\n'
              'Skipped: ${summary.externalSkipped}\n'
              'Failed: ${summary.failed}';
        },
      ),
    );
  }

  Future<void> _applyPath(String path) async {
    final pathService = ref.read(minecraftPathServiceProvider);
    final exists = await pathService.pathExistsAndDirectory(path);
    if (!mounted) {
      return;
    }

    if (!exists) {
      final create = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create mods folder?'),
          content: Text('The folder does not exist:\n$path\n\nCreate it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (create != true) {
        return;
      }
      await pathService.createModsDirectory(path);
    }

    await ref.read(appControllerProvider.notifier).saveModsPath(path);
    if (mounted) {
      await ref.read(modsControllerProvider.notifier).loadMods(path);
    }
  }
}

class _UpdateCheckProgressDialog extends StatefulWidget {
  const _UpdateCheckProgressDialog({required this.runCheck});

  final Future<UpdateCheckPreview> Function(UpdateCheckProgressCallback onProgress)
      runCheck;

  @override
  State<_UpdateCheckProgressDialog> createState() =>
      _UpdateCheckProgressDialogState();
}

class _UpdateCheckProgressDialogState extends State<_UpdateCheckProgressDialog> {
  int _processed = 0;
  int _total = 0;
  String _message = 'Preparing update check...';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final preview = await widget.runCheck((processed, total, message) {
      if (!mounted) {
        return;
      }
      setState(() {
        _processed = processed;
        _total = total;
        _message = message;
      });
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _done = true;
      _message = 'Check complete.';
    });
    Navigator.of(context).pop(preview);
  }

  @override
  Widget build(BuildContext context) {
    final value =
        (_total > 0) ? (_processed / _total).clamp(0.0, 1.0).toDouble() : null;
    return AlertDialog(
      title: const Text('Checking for Updates'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_message),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: value),
            const SizedBox(height: 8),
            Text(
              _total > 0 ? '$_processed / $_total checked' : 'Starting...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _done ? () => Navigator.of(context).pop() : null,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _UpdateConfirmDialog extends StatelessWidget {
  const _UpdateConfirmDialog({required this.preview});

  final UpdateCheckPreview preview;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Updates Found'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${preview.updates.length} update(s). '
              'All found updates will be installed.',
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: preview.updates.length,
                itemBuilder: (context, index) {
                  final item = preview.updates[index];
                  final from = item.currentVersion ?? 'unknown';
                  final to = item.latestVersion ?? 'latest';
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == preview.updates.length - 1 ? 0 : 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.mod.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$from -> $to',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Update All'),
        ),
      ],
    );
  }
}

class _UpdateRunDialog extends StatefulWidget {
  const _UpdateRunDialog({
    required this.total,
    required this.run,
  });

  final int total;
  final Future<String> Function() run;

  @override
  State<_UpdateRunDialog> createState() => _UpdateRunDialogState();
}

class _UpdateRunDialogState extends State<_UpdateRunDialog> {
  String _message = 'Starting updates...';
  bool _done = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    try {
      final result = await widget.run();
      if (!mounted) {
        return;
      }
      setState(() {
        _done = true;
        _failed = false;
        _message = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _done = true;
        _failed = true;
        _message = 'Update failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Updating Mods'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_message),
            const SizedBox(height: 10),
            if (!_done) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Applying ${widget.total} update(s)...',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _done
              ? () => Navigator.of(context).pop()
              : null,
          child: Text(_failed ? 'Close' : 'Done'),
        ),
      ],
    );
  }
}

class _UpdateResultDialog extends StatelessWidget {
  const _UpdateResultDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

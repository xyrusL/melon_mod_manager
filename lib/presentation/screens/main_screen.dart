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
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TopBar(
                currentPath: widget.modsPath,
                isBusy: state.isScanning || state.isBusy,
                onRefresh: () async {
                  ref.invalidate(developerSnapshotProvider);
                  await notifier.loadMods(widget.modsPath);
                },
                onBrowsePath: _browseNewPath,
                onAutoDetectPath: _autoDetectPath,
              ),
              if (state.errorMessage != null || state.infoMessage != null) ...[
                const SizedBox(height: 10),
                StatusBanner(
                  message: state.errorMessage ?? state.infoMessage!,
                  isError: state.errorMessage != null,
                  onDismiss: notifier.clearMessages,
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: AppTheme.glassPanel(),
                        padding: const EdgeInsets.all(8),
                        child: ModsTable(
                          mods: filteredMods,
                          selectedFiles: state.selectedFiles,
                          onToggleSelected: notifier.toggleModSelection,
                          onToggleSelectAllVisible: (selected) => notifier
                              .toggleSelectAllVisible(filteredMods, selected),
                          isScanning: state.isScanning,
                          processed: state.scanProcessed,
                          total: state.scanTotal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 260,
                      child: ActionPanel(
                        isBusy: state.isBusy,
                        hasDeleteSelection: state.selectedFiles.isNotEmpty,
                        onDownloadMods: _openModrinthSearch,
                        onCheckUpdates: () =>
                            notifier.checkForUpdates(widget.modsPath),
                        onAddFile: _addFiles,
                        onDeleteSelected: _deleteSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        const SnackBar(
          content: Text('Could not auto-detect a default mods folder.'),
        ),
      );
      return;
    }

    await _applyPath(detected);
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

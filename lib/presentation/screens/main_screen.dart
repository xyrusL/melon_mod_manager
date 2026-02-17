import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/file_install_service.dart';
import '../../domain/entities/content_type.dart';
import '../dialogs/confirm_overwrite_dialog.dart';
import '../dialogs/modrinth_search_dialog.dart';
import '../viewmodels/app_controller.dart';
import '../viewmodels/app_update_controller.dart';
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
  ProviderSubscription<AppUpdateState>? _updateSub;
  bool _autoUpdatePromptShown = false;
  bool _isInitializing = true;
  bool _isDropHovering = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeForPath(widget.modsPath));
    _updateSub = ref.listenManual<AppUpdateState>(
      appUpdateControllerProvider,
      (previous, next) {
        if (!mounted || _autoUpdatePromptShown) {
          return;
        }
        if (next.status == AppUpdateCheckStatus.updateAvailable) {
          _autoUpdatePromptShown = true;
          final tag = next.latestRelease?.tagName ?? 'latest';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New app update available: $tag'),
              action: SnackBarAction(label: 'See Sidebar', onPressed: () {}),
            ),
          );
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modsPath != widget.modsPath) {
      Future.microtask(() => _initializeForPath(widget.modsPath));
    }
  }

  @override
  void dispose() {
    _updateSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modsControllerProvider);
    final notifier = ref.read(modsControllerProvider.notifier);
    final filteredMods = state.filteredMods();
    final activePath = ref.read(contentPathServiceProvider).resolveContentPath(
          modsPath: widget.modsPath,
          contentType: state.contentType,
        );

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
                (constraints.maxWidth * 0.21).clamp(218.0, 300.0).toDouble();
            final pagePadding = (10 * uiScale).clamp(8, 14).toDouble();
            final contentGap = (10 * uiScale).clamp(8, 14).toDouble();
            final maxBodyWidth = (constraints.maxWidth - (pagePadding * 2))
                .clamp(1024.0, 1760.0)
                .toDouble();

            return Padding(
              padding: EdgeInsets.all(pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBodyWidth),
                  child: Column(
                    children: [
                      TopBar(
                        currentPath: activePath,
                        isBusy: state.isScanning || state.isBusy,
                        uiScale: uiScale,
                        onRefresh: () async {
                          ref.invalidate(developerSnapshotProvider);
                          ref.invalidate(
                              environmentInfoProvider(widget.modsPath));
                          await notifier.loadContent(
                            modsPath: widget.modsPath,
                            contentType: state.contentType,
                            forceRefresh: true,
                          );
                        },
                        onBrowsePath: _browseNewPath,
                        onAutoDetectPath: _autoDetectPath,
                      ),
                      SizedBox(height: (6 * uiScale).clamp(4, 9).toDouble()),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ContentTypeTabs(
                          selected: state.contentType,
                          enabled: !_isInitializing,
                          onChanged: (value) => _switchContentType(value),
                        ),
                      ),
                      if (_isInitializing) ...[
                        SizedBox(height: (8 * uiScale).clamp(6, 10).toDouble()),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: (12 * uiScale).clamp(10, 16).toDouble(),
                            vertical: (8 * uiScale).clamp(7, 11).toDouble(),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Preparing local files and Modrinth metadata...',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (state.errorMessage != null ||
                          state.infoMessage != null) ...[
                        SizedBox(
                            height: (10 * uiScale).clamp(10, 14).toDouble()),
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
                              child: DropTarget(
                                onDragEntered: (_) {
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() => _isDropHovering = true);
                                },
                                onDragExited: (_) {
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() => _isDropHovering = false);
                                },
                                onDragDone: (details) async {
                                  if (mounted) {
                                    setState(() => _isDropHovering = false);
                                  }
                                  final paths = details.files
                                      .map((file) => file.path)
                                      .where((path) => path.trim().isNotEmpty)
                                      .toList();
                                  await _handleDroppedFiles(paths);
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: AppTheme.glassPanel(),
                                      padding: EdgeInsets.all(
                                        (6 * uiScale).clamp(4, 10).toDouble(),
                                      ),
                                      child: ModsTable(
                                        title: state.contentType.label,
                                        mods: filteredMods,
                                        selectedFiles: state.selectedFiles,
                                        onToggleSelected:
                                            notifier.toggleModSelection,
                                        onToggleSelectAllVisible: (selected) =>
                                            notifier.toggleSelectAllVisible(
                                                filteredMods, selected),
                                        isScanning: state.isScanning,
                                        processed: state.scanProcessed,
                                        total: state.scanTotal,
                                        uiScale: uiScale,
                                      ),
                                    ),
                                    if (_isDropHovering)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: const Color(0x2238E8A5),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: const Color(0xFF48E39F),
                                                width: 1.8,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _dropHintLabel(
                                                    state.contentType),
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFFB7FEE0),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: (16 * uiScale)
                                                      .clamp(13, 20)
                                                      .toDouble(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: contentGap),
                            SizedBox(
                              width: sidePanelWidth,
                              child: ActionPanel(
                                modsPath: widget.modsPath,
                                isBusy: state.isBusy,
                                hasDeleteSelection:
                                    state.selectedFiles.isNotEmpty,
                                uiScale: uiScale,
                                downloadLabel:
                                    'Download ${state.contentType.label}',
                                actionsEnabled:
                                    !_isInitializing && !state.isScanning,
                                canCheckUpdates: true,
                                canZipTools: true,
                                onDownloadMods: _openModrinthSearch,
                                onCheckUpdates: _checkUpdatesWithReview,
                                onAddFile: _addFiles,
                                onImportZip: _importZipPack,
                                onExportZip: _exportZipPack,
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
          },
        ),
      ),
    );
  }

  double _computeUiScale({required double width, required double height}) {
    const baseWidth = 1024.0;
    const baseHeight = 620.0;
    final scale = (width / baseWidth).clamp(0.88, 1.25);
    final heightScale = (height / baseHeight).clamp(0.88, 1.2);
    return (scale < heightScale ? scale : heightScale).toDouble();
  }

  Future<void> _openModrinthSearch() async {
    final state = ref.read(modsControllerProvider);
    final targetPath = ref.read(contentPathServiceProvider).resolveContentPath(
          modsPath: widget.modsPath,
          contentType: state.contentType,
        );
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => ModrinthSearchDialog(
        modsPath: widget.modsPath,
        targetPath: targetPath,
        contentType: state.contentType,
      ),
    );
    if (!mounted || changed != true) {
      return;
    }
    await ref.read(modsControllerProvider.notifier).loadContent(
          modsPath: widget.modsPath,
          contentType: state.contentType,
          forceRefresh: true,
        );
  }

  Future<void> _addFiles() async {
    final state = ref.read(modsControllerProvider);
    final targetPath = ref.read(contentPathServiceProvider).resolveContentPath(
          modsPath: widget.modsPath,
          contentType: state.contentType,
        );
    final allowedExtensions = switch (state.contentType) {
      ContentType.mod => const ['jar'],
      ContentType.resourcePack => const ['zip'],
      ContentType.shaderPack => const ['zip'],
    };
    final dialogTitle = switch (state.contentType) {
      ContentType.mod => 'Select Mod File(s) (.jar)',
      ContentType.resourcePack => 'Select Resource Pack File(s) (.zip)',
      ContentType.shaderPack => 'Select Shader Pack File(s) (.zip)',
    };
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    final paths = picked?.paths.whereType<String>().toList() ?? const [];
    if (paths.isEmpty || !mounted) {
      return;
    }

    await ref.read(modsControllerProvider.notifier).installExternalFiles(
          targetPath: targetPath,
          sourcePaths: paths,
          onConflict: _resolveConflict,
        );
  }

  Future<void> _handleDroppedFiles(List<String> sourcePaths) async {
    if (!mounted || sourcePaths.isEmpty || _isInitializing) {
      return;
    }

    final state = ref.read(modsControllerProvider);
    if (state.isBusy) {
      return;
    }

    final allowedExtensions = switch (state.contentType) {
      ContentType.mod => const ['jar'],
      ContentType.resourcePack => const ['zip'],
      ContentType.shaderPack => const ['zip'],
    };
    final allowedSuffixes =
        allowedExtensions.map((ext) => '.${ext.toLowerCase()}').toList();

    final acceptedPaths = sourcePaths.where((path) {
      final normalized = path.toLowerCase();
      return allowedSuffixes.any(normalized.endsWith);
    }).toList();
    final ignoredCount = sourcePaths.length - acceptedPaths.length;

    if (acceptedPaths.isEmpty) {
      final expected = allowedSuffixes.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No valid file found. Expected: $expected'),
        ),
      );
      return;
    }

    final targetPath = ref.read(contentPathServiceProvider).resolveContentPath(
          modsPath: widget.modsPath,
          contentType: state.contentType,
        );

    await ref.read(modsControllerProvider.notifier).installExternalFiles(
          targetPath: targetPath,
          sourcePaths: acceptedPaths,
          onConflict: _resolveConflict,
        );

    if (!mounted || ignoredCount <= 0) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${acceptedPaths.length} file(s). Ignored $ignoredCount invalid file(s).',
        ),
      ),
    );
  }

  String _dropHintLabel(ContentType contentType) {
    return switch (contentType) {
      ContentType.mod => 'Drop .jar files to add mods',
      ContentType.resourcePack => 'Drop .zip files to add resource packs',
      ContentType.shaderPack => 'Drop .zip files to add shader packs',
    };
  }

  Future<void> _importZipPack() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final zipPath = picked?.files.single.path;
    if (zipPath == null || zipPath.isEmpty || !mounted) {
      return;
    }

    await ref.read(modsControllerProvider.notifier).importContentFromZip(
          modsPath: widget.modsPath,
          zipPath: zipPath,
        );
  }

  Future<void> _exportZipPack() async {
    final state = ref.read(modsControllerProvider);
    final timestamp = DateTime.now();
    final prefix = switch (state.contentType) {
      ContentType.mod => 'melon_mod_pack',
      ContentType.resourcePack => 'melon_resource_pack',
      ContentType.shaderPack => 'melon_shader_pack',
    };
    final fileName =
        '${prefix}_${timestamp.year.toString().padLeft(4, '0')}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}.zip';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export ${state.contentType.label}',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (savePath == null || savePath.isEmpty || !mounted) {
      return;
    }

    final normalized =
        savePath.toLowerCase().endsWith('.zip') ? savePath : '$savePath.zip';
    await ref.read(modsControllerProvider.notifier).exportContentToZip(
          modsPath: widget.modsPath,
          zipPath: normalized,
        );
  }

  Future<void> _deleteSelected() async {
    final state = ref.read(modsControllerProvider);
    final targetPath = ref.read(contentPathServiceProvider).resolveContentPath(
          modsPath: widget.modsPath,
          contentType: state.contentType,
        );
    final selectedCount = ref.read(modsControllerProvider).selectedFiles.length;
    if (selectedCount == 0 || !mounted) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Delete selected ${state.contentType.label.toLowerCase()}?'),
        content: Text(
          'This will permanently delete $selectedCount selected ${state.contentType.singularLabel.toLowerCase()} file(s) from:\n$targetPath',
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

    await ref
        .read(modsControllerProvider.notifier)
        .deleteSelectedMods(targetPath);
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
    final result = await pathService.detectDefaultModsPathDetailed();
    if (!mounted) {
      return;
    }
    if (!result.hasPath) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          backgroundColor: const Color(0xFF3A1420),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFFF6A7D), width: 1),
          ),
          content: Text(
            result.message,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    if (result.needsCreation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          content: Text(result.message),
        ),
      );
    }

    await _applyPath(result.path!);
  }

  Future<void> _checkUpdatesWithReview() async {
    final notifier = ref.read(modsControllerProvider.notifier);
    final contentLabel =
        ref.read(modsControllerProvider).contentType.label.toLowerCase();
    final preview = await showDialog<UpdateCheckPreview>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateCheckProgressDialog(
        runCheck: (onProgress) => notifier.checkForUpdatesPreview(
          modsPath: widget.modsPath,
          onProgress: onProgress,
        ),
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
          message: 'No items available for update.',
        ),
      );
      return;
    }

    if (preview.updates.isEmpty) {
      final scope =
          preview.selectedOnly ? 'selected $contentLabel' : 'all $contentLabel';
      final detail = _buildNoUpdatesDetail(preview);
      await showDialog<void>(
        context: context,
        builder: (context) => _UpdateResultDialog(
          title: 'No Updates Found',
          message: 'Checked ${preview.totalChecked} item(s) in $scope.\n'
              '$detail',
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
          return 'Checked ${summary.totalChecked} item(s)\n'
              'Updated: ${summary.updated}\n'
              'Up to date: ${summary.alreadyLatest}\n'
              'Skipped: ${summary.externalSkipped}\n'
              'Failed: ${summary.failed}';
        },
      ),
    );
  }

  String _buildNoUpdatesDetail(UpdateCheckPreview preview) {
    if (preview.failed > 0) {
      return '${preview.alreadyLatest} up to date, '
          '${preview.externalOrUnknown} external/unmapped, '
          '${preview.failed} failed to check.';
    }
    if (preview.externalOrUnknown > 0) {
      return '${preview.alreadyLatest} up to date, '
          '${preview.externalOrUnknown} external/unmapped.';
    }
    return 'Everything is already up to date.';
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
    if (mounted && path == widget.modsPath) {
      await _initializeForPath(path);
    }
  }

  Future<void> _switchContentType(ContentType contentType) async {
    if (_isInitializing) {
      return;
    }
    await ref.read(modsControllerProvider.notifier).loadContent(
          modsPath: widget.modsPath,
          contentType: contentType,
        );
  }

  Future<void> _initializeForPath(String modsPath) async {
    if (mounted) {
      setState(() => _isInitializing = true);
    }
    final notifier = ref.read(modsControllerProvider.notifier);
    final currentType = ref.read(modsControllerProvider).contentType;
    await notifier.loadContent(
      modsPath: modsPath,
      contentType: currentType,
      forceRefresh: true,
    );
    if (mounted) {
      setState(() => _isInitializing = false);
    }
    unawaited(
      notifier.warmUpContentCaches(modsPath).catchError((_) {
        // Warm-up should never block the primary UI load.
      }),
    );
  }

}

class _ContentTypeTabs extends StatelessWidget {
  const _ContentTypeTabs({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final ContentType selected;
  final ValueChanged<ContentType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ContentType.values
          .map(
            (type) => ChoiceChip(
              label: Text(type.label),
              selected: selected == type,
              onSelected: enabled ? (_) => onChanged(type) : null,
            ),
          )
          .toList(),
    );
  }
}

class _UpdateCheckProgressDialog extends StatefulWidget {
  const _UpdateCheckProgressDialog({required this.runCheck});

  final Future<UpdateCheckPreview> Function(
      UpdateCheckProgressCallback onProgress) runCheck;

  @override
  State<_UpdateCheckProgressDialog> createState() =>
      _UpdateCheckProgressDialogState();
}

class _UpdateCheckProgressDialogState
    extends State<_UpdateCheckProgressDialog> {
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
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
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
          onPressed: _done ? () => Navigator.of(context).pop() : null,
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

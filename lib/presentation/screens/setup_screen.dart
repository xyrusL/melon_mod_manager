import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/melon_logo.dart';
import '../viewmodels/app_controller.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _pathController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _autoDetect() async {
    final pathService = ref.read(minecraftPathServiceProvider);
    final detected = await pathService.detectDefaultModsPath();
    if (detected == null) {
      setState(() => _error = 'Could not auto-detect Minecraft mods folder.');
      return;
    }

    setState(() {
      _error = null;
      _pathController.text = detected;
    });
  }

  Future<void> _browse() async {
    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected == null) {
      return;
    }

    final normalized =
        ref.read(minecraftPathServiceProvider).normalizeSelectedPath(selected);
    setState(() {
      _error = null;
      _pathController.text = normalized;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final pathService = ref.read(minecraftPathServiceProvider);
    final normalized = pathService.normalizeSelectedPath(_pathController.text);

    if (normalized.trim().isEmpty) {
      setState(() {
        _saving = false;
        _error = 'Please select a mods folder path.';
      });
      return;
    }

    final exists = await pathService.pathExistsAndDirectory(normalized);
    if (!exists) {
      final create = await _askCreateFolder(normalized);
      if (create != true) {
        setState(() {
          _saving = false;
          _error = 'Folder does not exist.';
        });
        return;
      }
      try {
        await pathService.createModsDirectory(normalized);
      } catch (error) {
        setState(() {
          _saving = false;
          _error = 'Cannot create folder: $error';
        });
        return;
      }
    }

    try {
      await ref.read(appControllerProvider.notifier).saveModsPath(normalized);
    } catch (error) {
      setState(() {
        _error = 'Failed to save path: $error';
      });
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  Future<bool?> _askCreateFolder(String folderPath) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create mods folder?'),
        content: Text(
          'The folder does not exist:\n$folderPath\n\nCreate it now?',
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            final pagePadding = (18 * uiScale).clamp(18, 30).toDouble();
            final cardMaxWidth =
                (constraints.maxWidth * 0.72).clamp(700.0, 920.0).toDouble();
            final titleSize = (38 * uiScale).clamp(30, 42).toDouble();
            final subtitleSize = (16 * uiScale).clamp(14, 18).toDouble();
            final bodySize = (15 * uiScale).clamp(13, 16).toDouble();
            final cardPadding = (30 * uiScale).clamp(22, 34).toDouble();
            final gapSm = (10 * uiScale).clamp(8, 12).toDouble();
            final gapMd = (16 * uiScale).clamp(12, 18).toDouble();
            final gapLg = (24 * uiScale).clamp(18, 28).toDouble();
            final iconSize = (18 * uiScale).clamp(16, 20).toDouble();

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: AppTheme.glassPanel(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MelonLogo(size: (38 * uiScale).clamp(34, 44).toDouble()),
                            SizedBox(width: gapMd),
                            Expanded(
                              child: Text(
                                'Setup Mods Folder',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: gapSm),
                        Text(
                          'Choose how you want to set your .minecraft/mods path. You can auto-detect defaults or browse manually.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: subtitleSize,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: gapLg),
                        TextField(
                          controller: _pathController,
                          style: TextStyle(fontSize: bodySize),
                          decoration: InputDecoration(
                            labelText: 'Mods folder path',
                            labelStyle: TextStyle(fontSize: bodySize),
                            prefixIcon: Icon(
                              Icons.folder_copy_rounded,
                              size: iconSize,
                            ),
                          ),
                        ),
                        SizedBox(height: gapMd),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _autoDetect,
                                icon: Icon(
                                  Icons.auto_fix_high_rounded,
                                  size: iconSize,
                                ),
                                label: Text(
                                  'Auto-detect',
                                  style: TextStyle(
                                    fontSize: bodySize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(0, (48 * uiScale).clamp(44, 52).toDouble()),
                                ),
                              ),
                            ),
                            SizedBox(width: gapMd),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _browse,
                                icon: Icon(
                                  Icons.folder_open_rounded,
                                  size: iconSize,
                                ),
                                label: Text(
                                  'Browse',
                                  style: TextStyle(
                                    fontSize: bodySize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(0, (48 * uiScale).clamp(44, 52).toDouble()),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          SizedBox(height: gapMd),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: const Color(0xFFFF7D7D),
                              fontSize: bodySize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        SizedBox(height: gapLg),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(0, (52 * uiScale).clamp(48, 56).toDouble()),
                            ),
                            child: _saving
                                ? SizedBox(
                                    width: (18 * uiScale).clamp(16, 20).toDouble(),
                                    height: (18 * uiScale).clamp(16, 20).toDouble(),
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    'Save and Continue',
                                    style: TextStyle(
                                      fontSize: bodySize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
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
    const baseWidth = 1100.0;
    const baseHeight = 700.0;
    final widthScale = (width / baseWidth).clamp(0.9, 1.3);
    final heightScale = (height / baseHeight).clamp(0.9, 1.2);
    return widthScale < heightScale ? widthScale : heightScale;
  }
}

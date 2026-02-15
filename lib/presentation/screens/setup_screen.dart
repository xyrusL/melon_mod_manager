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
    return Container(
      decoration: AppTheme.appBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: AppTheme.glassPanel(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      MelonLogo(size: 34),
                      SizedBox(width: 10),
                      Text(
                        'Setup Mods Folder',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your .minecraft/mods folder to start managing Fabric/Quilt mods.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Mods folder path',
                      prefixIcon: Icon(Icons.folder_copy_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _autoDetect,
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: const Text('Auto-detect'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _browse,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Browse'),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save and Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

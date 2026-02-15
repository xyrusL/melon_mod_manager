import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_reporter.dart';
import '../../domain/entities/modrinth_project.dart';
import '../../domain/usecases/install_queue_usecase.dart';
import '../viewmodels/mods_controller.dart';

class ModrinthSearchDialog extends ConsumerStatefulWidget {
  const ModrinthSearchDialog({super.key, required this.modsPath});

  final String modsPath;

  @override
  ConsumerState<ModrinthSearchDialog> createState() =>
      _ModrinthSearchDialogState();
}

class _ModrinthSearchDialogState extends ConsumerState<ModrinthSearchDialog> {
  final _queryController = TextEditingController();
  final _gameVersionController = TextEditingController();

  var _loader = 'fabric';
  var _loading = false;
  List<ModrinthProject> _results = const [];
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    _gameVersionController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Type a search query first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects =
          await ref.read(modsControllerProvider.notifier).searchModrinth(
                query,
                loader: _loader,
                gameVersion: _gameVersionController.text.trim().isEmpty
                    ? null
                    : _gameVersionController.text.trim(),
              );
      setState(() => _results = projects);
    } catch (error) {
      setState(() => _error = ErrorReporter().toUserMessage(error));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _install(ModrinthProject project) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DependencyInstallProgressDialog(
        modsPath: widget.modsPath,
        project: project,
        loader: _loader,
        gameVersion: _gameVersionController.text.trim().isEmpty
            ? null
            : _gameVersionController.text.trim(),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 760,
        height: 560,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download from Modrinth',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      hintText: 'Search mods',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    initialValue: _loader,
                    items: const [
                      DropdownMenuItem(value: 'fabric', child: Text('Fabric')),
                      DropdownMenuItem(value: 'quilt', child: Text('Quilt')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _loader = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Loader'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _gameVersionController,
                    decoration:
                        const InputDecoration(labelText: 'Game version'),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results yet.'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: item.iconUrl == null
                                ? const Icon(Icons.extension_rounded)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.iconUrl!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.extension_rounded),
                                    ),
                                  ),
                            title: Text(item.title),
                            subtitle: Text(
                              item.description.isEmpty
                                  ? item.slug
                                  : item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: FilledButton.tonal(
                              onPressed: _loading ? null : () => _install(item),
                              child: const Text('Install'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependencyInstallProgressDialog extends ConsumerStatefulWidget {
  const _DependencyInstallProgressDialog({
    required this.modsPath,
    required this.project,
    required this.loader,
    this.gameVersion,
  });

  final String modsPath;
  final ModrinthProject project;
  final String loader;
  final String? gameVersion;

  @override
  ConsumerState<_DependencyInstallProgressDialog> createState() =>
      _DependencyInstallProgressDialogState();
}

class _DependencyInstallProgressDialogState
    extends ConsumerState<_DependencyInstallProgressDialog> {
  String _message = 'Resolving dependencies...';
  InstallProgressStage _stage = InstallProgressStage.resolving;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runInstall);
  }

  Future<void> _runInstall() async {
    await ref.read(modsControllerProvider.notifier).installFromModrinth(
          modsPath: widget.modsPath,
          project: widget.project,
          loader: widget.loader,
          gameVersion: widget.gameVersion,
          onProgress: _onProgress,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _finished = true;
      if (_stage != InstallProgressStage.error) {
        _message = 'Done.';
      }
    });
  }

  Future<void> _onProgress(InstallProgress progress) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _stage = progress.stage;
      _message = progress.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Installing Mod + Dependencies'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_finished) const LinearProgressIndicator(),
            if (!_finished) const SizedBox(height: 14),
            Text(
              _message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'This mod may require additional mods. Required dependencies are installed automatically.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _finished ? () => Navigator.of(context).pop() : null,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

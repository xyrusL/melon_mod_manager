part of '../modrinth_search_dialog.dart';

class _BulkInstallSummary {
  const _BulkInstallSummary({
    required this.installed,
    required this.updated,
    required this.skipped,
    required this.failed,
  });

  final int installed;
  final int updated;
  final int skipped;
  final int failed;

  bool get hasChanges => installed > 0 || updated > 0;
}

class _BulkInstallProgressDialog extends ConsumerStatefulWidget {
  const _BulkInstallProgressDialog({
    required this.modsPath,
    required this.targetPath,
    required this.projects,
    required this.installInfo,
    required this.loader,
    required this.gameVersion,
    required this.contentType,
  });

  final String modsPath;
  final String targetPath;
  final List<ModrinthProject> projects;
  final Map<String, ProjectInstallInfo> installInfo;
  final String? loader;
  final String? gameVersion;
  final ContentType contentType;

  @override
  ConsumerState<_BulkInstallProgressDialog> createState() =>
      _BulkInstallProgressDialogState();
}

class _BulkInstallProgressDialogState
    extends ConsumerState<_BulkInstallProgressDialog> {
  String _message = 'Preparing installation...';
  final List<String> _logs = [];
  var _done = false;

  int _installed = 0;
  int _updated = 0;
  int _skipped = 0;
  int _failed = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    final total = widget.projects.length;

    for (var i = 0; i < total; i++) {
      final project = widget.projects[i];
      final installState = widget.installInfo[project.id]?.state;
      final step = i + 1;

      if (widget.contentType == ContentType.mod &&
          installState == ProjectInstallState.installed) {
        _skipped++;
        _logs.add('Skipped ${project.title}: already installed.');
        if (mounted) {
          setState(() {
            _message =
                '[$step/$total] Skipped ${project.title} (already installed).';
          });
        }
        continue;
      }
      if (widget.contentType == ContentType.mod &&
          installState == ProjectInstallState.installedUntracked) {
        _skipped++;
        _logs.add(
          'Skipped ${project.title}: already in mods folder (untracked).',
        );
        if (mounted) {
          setState(() {
            _message = '[$step/$total] Skipped ${project.title} (on disk).';
          });
        }
        continue;
      }

      if (widget.contentType == ContentType.mod) {
        final result =
            await ref.read(modsControllerProvider.notifier).installFromModrinth(
                  modsPath: widget.modsPath,
                  project: project,
                  loader: widget.loader ?? 'fabric',
                  gameVersion: widget.gameVersion,
                  onProgress: (progress) async {
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _message = '[$step/$total] ${progress.message}';
                    });
                  },
                );

        if (!result.installed) {
          _failed++;
          _logs.add('Failed ${project.title}: ${result.message}');
          continue;
        }

        if (installState == ProjectInstallState.updateAvailable) {
          _updated++;
          _logs.add('Updated ${project.title}.');
        } else {
          _installed++;
          _logs.add('Installed ${project.title}.');
        }
      } else {
        if (mounted) {
          setState(() {
            _message = '[$step/$total] Downloading ${project.title}...';
          });
        }
        try {
          await ref
              .read(modsControllerProvider.notifier)
              .installProjectFileFromModrinth(
                targetPath: widget.targetPath,
                project: project,
                contentType: widget.contentType,
                loader: null,
                gameVersion: null,
              );
          _installed++;
          _logs.add('Downloaded ${project.title}.');
        } catch (_) {
          _failed++;
          _logs.add('Failed ${project.title}.');
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _done = true;
      _message = 'Done. Installed $_installed, Updated $_updated, '
          'Skipped $_skipped, Failed $_failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.contentType == ContentType.mod
            ? 'Installing Selected Mods'
            : 'Downloading Selected ${widget.contentType.label}',
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_done) const LinearProgressIndicator(),
            if (!_done) const SizedBox(height: 12),
            Text(_message),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${_logs[index]}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
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
        FilledButton(
          onPressed: _done
              ? () => Navigator.of(context).pop(
                    _BulkInstallSummary(
                      installed: _installed,
                      updated: _updated,
                      skipped: _skipped,
                      failed: _failed,
                    ),
                  )
              : null,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'app_modal.dart';

class RefreshProgressSnapshot {
  const RefreshProgressSnapshot({
    required this.detail,
    required this.step,
    required this.totalSteps,
  });

  final String detail;
  final int step;
  final int totalSteps;
}

typedef RefreshProgressCallback = void Function(RefreshProgressSnapshot update);
typedef RunRefreshWithProgress = Future<String> Function(
  RefreshProgressCallback onProgress,
);

class RefreshProgressDialog extends StatefulWidget {
  const RefreshProgressDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.runRefresh,
    this.startingMessage = 'Preparing refresh...',
    this.width = 520,
  });

  final String title;
  final String subtitle;
  final String startingMessage;
  final double width;
  final RunRefreshWithProgress runRefresh;

  @override
  State<RefreshProgressDialog> createState() => _RefreshProgressDialogState();
}

class _RefreshProgressDialogState extends State<RefreshProgressDialog> {
  late String _message = widget.startingMessage;
  int _step = 0;
  int _totalSteps = 0;
  bool _done = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_run);
  }

  Future<void> _run() async {
    try {
      final result = await widget.runRefresh((update) {
        if (!mounted) {
          return;
        }
        setState(() {
          _message = update.detail;
          _step = update.step;
          _totalSteps = update.totalSteps;
        });
      });
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
        _message = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (!_done && _totalSteps > 0)
        ? (_step / _totalSteps).clamp(0.0, 1.0)
        : null;
    final stepLabel =
        _totalSteps > 0 ? 'Step $_step of $_totalSteps' : 'Starting...';

    return AppModal(
      title: AppModalTitle(widget.title),
      subtitle: Text(widget.subtitle),
      showCloseButton: false,
      width: widget.width,
      content: SizedBox(
        width: widget.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_message),
            const SizedBox(height: 12),
            if (!_done) ...[
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 8),
              Text(
                stepLabel,
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

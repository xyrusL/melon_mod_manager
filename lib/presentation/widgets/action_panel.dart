import 'package:flutter/material.dart';

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.onDownloadMods,
    required this.onCheckUpdates,
    required this.onAddFile,
    required this.isBusy,
  });

  final VoidCallback onDownloadMods;
  final VoidCallback onCheckUpdates;
  final VoidCallback onAddFile;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: isBusy ? null : onDownloadMods,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Mods'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onCheckUpdates,
            icon: const Icon(Icons.system_update_alt_rounded),
            label: const Text('Check for Updates'),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isBusy ? null : onAddFile,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Add File'),
          ),
        ],
      ),
    );
  }
}

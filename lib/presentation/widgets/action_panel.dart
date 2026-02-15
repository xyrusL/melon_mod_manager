import 'package:flutter/material.dart';

import 'developer_info_card.dart';
import 'panel_action_button.dart';

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.onDownloadMods,
    required this.onCheckUpdates,
    required this.onAddFile,
    required this.onDeleteSelected,
    required this.isBusy,
    required this.hasDeleteSelection,
  });

  final VoidCallback onDownloadMods;
  final VoidCallback onCheckUpdates;
  final VoidCallback onAddFile;
  final VoidCallback onDeleteSelected;
  final bool isBusy;
  final bool hasDeleteSelection;

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
          PanelActionButton(
            label: 'Download Mods',
            icon: Icons.download_rounded,
            backgroundColor: const Color(0xFF50F0A8),
            foregroundColor: Colors.black,
            onPressed: isBusy ? null : onDownloadMods,
          ),
          const SizedBox(height: 10),
          PanelActionButton(
            label: 'Check for Updates',
            icon: Icons.system_update_alt_rounded,
            backgroundColor: const Color(0xFFFFC15A),
            foregroundColor: Colors.black,
            onPressed: isBusy ? null : onCheckUpdates,
          ),
          const SizedBox(height: 10),
          PanelActionButton(
            label: 'Add File',
            icon: Icons.add_circle_outline_rounded,
            backgroundColor: const Color(0xFF6AB9FF),
            foregroundColor: Colors.black,
            onPressed: isBusy ? null : onAddFile,
          ),
          const SizedBox(height: 10),
          PanelActionButton(
            label: 'Delete Selected',
            icon: Icons.delete_forever_rounded,
            backgroundColor: const Color(0xFFFF6A7D),
            foregroundColor: Colors.black,
            onPressed: isBusy || !hasDeleteSelection ? null : onDeleteSelected,
          ),
          const SizedBox(height: 12),
          const Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: DeveloperInfoCard(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.currentPath,
    required this.isBusy,
    required this.onRefresh,
    required this.onBrowsePath,
    required this.onAutoDetectPath,
  });

  final String currentPath;
  final bool isBusy;
  final VoidCallback onRefresh;
  final VoidCallback onBrowsePath;
  final VoidCallback onAutoDetectPath;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Text(
            'Melon Mod Manager',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: PopupMenuButton<_PathAction>(
              tooltip: 'Mods path options',
              onSelected: (action) {
                switch (action) {
                  case _PathAction.browse:
                    onBrowsePath();
                    break;
                  case _PathAction.autoDetect:
                    onAutoDetectPath();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _PathAction.browse,
                  child: Text('Browse folder'),
                ),
                PopupMenuItem(
                  value: _PathAction.autoDetect,
                  child: Text('Auto-detect default'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          IconButton.filledTonal(
            onPressed: isBusy ? null : onRefresh,
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

enum _PathAction { browse, autoDetect }

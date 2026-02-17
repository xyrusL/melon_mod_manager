import 'package:flutter/material.dart';

import 'melon_logo.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.currentPath,
    required this.isBusy,
    required this.onRefresh,
    required this.onBrowsePath,
    required this.onAutoDetectPath,
    this.uiScale = 1.0,
  });

  final String currentPath;
  final bool isBusy;
  final VoidCallback onRefresh;
  final VoidCallback onBrowsePath;
  final VoidCallback onAutoDetectPath;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final titleSize = (19 * uiScale).clamp(17, 24).toDouble();
    final iconSize = (17 * uiScale).clamp(15, 22).toDouble();
    final controlVerticalPadding = (8 * uiScale).clamp(6, 12).toDouble();
    final paddingH = (16 * uiScale).clamp(12, 24).toDouble();
    final paddingV = (10 * uiScale).clamp(8, 15).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          MelonLogo(size: (26 * uiScale).clamp(22, 34).toDouble()),
          SizedBox(width: (8 * uiScale).clamp(6, 12).toDouble()),
          Text(
            'Melon',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: (6 * uiScale).clamp(5, 10).toDouble()),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (7 * uiScale).clamp(6, 10).toDouble(),
              vertical: (3 * uiScale).clamp(2, 5).toDouble(),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              'BETA',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: (10 * uiScale).clamp(9.5, 12).toDouble(),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: (14 * uiScale).clamp(10, 24).toDouble()),
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
                padding: EdgeInsets.symmetric(
                  horizontal: (12 * uiScale).clamp(10, 16).toDouble(),
                  vertical: controlVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: iconSize),
                    SizedBox(width: (8 * uiScale).clamp(6, 12).toDouble()),
                    Expanded(
                      child: Text(
                        currentPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: (12 * uiScale).clamp(11, 15).toDouble(),
                        ),
                      ),
                    ),
                    SizedBox(width: (4 * uiScale).clamp(3, 8).toDouble()),
                    Icon(Icons.keyboard_arrow_down_rounded, size: iconSize),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: (10 * uiScale).clamp(8, 14).toDouble()),
          IconButton.filledTonal(
            onPressed: isBusy ? null : onRefresh,
            icon: isBusy
                ? SizedBox(
                    width: (14 * uiScale).clamp(12, 18).toDouble(),
                    height: (14 * uiScale).clamp(12, 18).toDouble(),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: (20 * uiScale).clamp(17, 24).toDouble(),
                  ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

enum _PathAction { browse, autoDetect }

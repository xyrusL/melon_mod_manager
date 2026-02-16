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
    final titleSize = (21 * uiScale).clamp(21, 27).toDouble();
    final iconSize = (18 * uiScale).clamp(18, 24).toDouble();
    final controlVerticalPadding = (10 * uiScale).clamp(10, 14).toDouble();
    final paddingH = (20 * uiScale).clamp(20, 28).toDouble();
    final paddingV = (14 * uiScale).clamp(14, 18).toDouble();

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
          MelonLogo(size: (30 * uiScale).clamp(30, 38).toDouble()),
          SizedBox(width: (10 * uiScale).clamp(10, 14).toDouble()),
          Text(
            'Melon',
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: (8 * uiScale).clamp(8, 12).toDouble()),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (8 * uiScale).clamp(8, 12).toDouble(),
              vertical: (4 * uiScale).clamp(4, 6).toDouble(),
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
                fontSize: (11 * uiScale).clamp(11, 13).toDouble(),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: (22 * uiScale).clamp(22, 28).toDouble()),
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
                  horizontal: (14 * uiScale).clamp(14, 18).toDouble(),
                  vertical: controlVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, size: iconSize),
                    SizedBox(width: (10 * uiScale).clamp(10, 14).toDouble()),
                    Expanded(
                      child: Text(
                        currentPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: (13 * uiScale).clamp(13, 16).toDouble(),
                        ),
                      ),
                    ),
                    SizedBox(width: (6 * uiScale).clamp(6, 10).toDouble()),
                    Icon(Icons.keyboard_arrow_down_rounded, size: iconSize),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: (14 * uiScale).clamp(14, 18).toDouble()),
          IconButton.filledTonal(
            onPressed: isBusy ? null : onRefresh,
            icon: isBusy
                ? SizedBox(
                    width: (16 * uiScale).clamp(16, 20).toDouble(),
                    height: (16 * uiScale).clamp(16, 20).toDouble(),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: (22 * uiScale).clamp(22, 26).toDouble(),
                  ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

enum _PathAction { browse, autoDetect }

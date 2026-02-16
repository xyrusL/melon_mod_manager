part of '../modrinth_search_dialog.dart';

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.info,
    required this.selected,
    required this.versionLine,
    required this.onTapAction,
  });

  final ModrinthProject project;
  final ProjectInstallInfo? info;
  final bool selected;
  final String versionLine;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    final state = info?.state ?? ProjectInstallState.notInstalled;
    final isInstalled = state == ProjectInstallState.installed;
    final isUntracked = state == ProjectInstallState.installedUntracked;
    final isUpdate = state == ProjectInstallState.updateAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: project.iconUrl == null
                ? Container(
                    width: 46,
                    height: 46,
                    color: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(Icons.extension_rounded),
                  )
                : Image.network(
                    project.iconUrl!,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 46,
                      height: 46,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: const Icon(Icons.extension_rounded),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.description.isEmpty
                      ? project.slug
                      : project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.sell_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        versionLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatPill(
                      icon: Icons.download_rounded,
                      label: _formatCompact(project.downloads),
                    ),
                    const SizedBox(width: 6),
                    _StatPill(
                      icon: Icons.favorite_border_rounded,
                      label: _formatCompact(project.follows),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isInstalled)
                  const _StatusTag(
                    label: 'Installed',
                    color: Color(0xFF68DA97),
                  ),
                if (isUpdate)
                  const _StatusTag(
                    label: 'Update',
                    color: Color(0xFFFFB55A),
                  ),
                if (isUntracked)
                  const _StatusTag(
                    label: 'On Disk',
                    color: Color(0xFF86C5FF),
                  ),
                if (!isInstalled && !isUpdate && !isUntracked)
                  const _StatusTag(
                    label: 'Available',
                    color: Color(0xFF8D98A5),
                  ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: (isInstalled || isUntracked) ? null : onTapAction,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(150, 42),
                    backgroundColor: isInstalled
                        ? const Color(0xFF68DA97).withValues(alpha: 0.15)
                        : isUntracked
                            ? const Color(0xFF86C5FF).withValues(alpha: 0.15)
                            : isUpdate
                                ? const Color(0xFFFFB55A).withValues(alpha: 0.2)
                                : selected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.25)
                                    : null,
                    foregroundColor: isInstalled
                        ? const Color(0xFF68DA97)
                        : isUntracked
                            ? const Color(0xFF86C5FF)
                            : isUpdate
                                ? const Color(0xFFFFC574)
                                : null,
                  ),
                  child: Text(
                    isInstalled
                        ? 'Installed'
                        : isUntracked
                            ? 'On Disk'
                            : selected
                                ? 'Selected'
                                : isUpdate
                                    ? 'Add Update'
                                    : 'Add',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCompact(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

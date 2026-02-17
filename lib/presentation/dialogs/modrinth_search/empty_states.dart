part of '../modrinth_search_dialog.dart';

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReloadPopular});

  final VoidCallback onReloadPopular;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No projects found.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onReloadPopular,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Load popular projects'),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClearFilter});

  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No projects in this status filter.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onClearFilter,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Show all statuses'),
          ),
        ],
      ),
    );
  }
}

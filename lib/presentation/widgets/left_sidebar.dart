import 'package:flutter/material.dart';

import '../viewmodels/mods_controller.dart';

class LeftSidebar extends StatefulWidget {
  const LeftSidebar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ModFilter selectedFilter;
  final ValueChanged<ModFilter> onFilterChanged;

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(context, label: 'All', value: ModFilter.all),
              _filterChip(
                context,
                label: 'Modrinth',
                value: ModFilter.modrinth,
              ),
              _filterChip(
                context,
                label: 'External',
                value: ModFilter.external,
              ),
              _filterChip(
                context,
                label: 'Updatable',
                value: ModFilter.updatable,
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required ModFilter value,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: widget.selectedFilter == value,
      onSelected: (_) => widget.onFilterChanged(value),
      selectedColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    );
  }
}

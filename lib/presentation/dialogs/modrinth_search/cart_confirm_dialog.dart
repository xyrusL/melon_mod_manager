part of '../modrinth_search_dialog.dart';

class _CartConfirmDialog extends StatefulWidget {
  const _CartConfirmDialog({
    required this.projects,
    required this.installInfo,
    required this.latestVersionByProject,
    required this.dependencyPreview,
  });

  static const int _scrollTriggerCount = 4;
  static const double _rowHeight = 62;
  static const double _listMaxHeight = 280;

  final List<ModrinthProject> projects;
  final Map<String, ProjectInstallInfo> installInfo;
  final Map<String, String> latestVersionByProject;
  final DependencyPreview dependencyPreview;

  @override
  State<_CartConfirmDialog> createState() => _CartConfirmDialogState();
}

class _CartConfirmDialogState extends State<_CartConfirmDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldScroll =
        widget.projects.length > _CartConfirmDialog._scrollTriggerCount ||
            widget.dependencyPreview.requiredDependencies.length >
                _CartConfirmDialog._scrollTriggerCount;
    final desiredHeight = (widget.projects.length +
                widget.dependencyPreview.requiredDependencies.length) *
            _CartConfirmDialog._rowHeight +
        (widget.dependencyPreview.requiredDependencies.isEmpty ? 18 : 74);
    final listHeight = shouldScroll
        ? 420.0
        : desiredHeight.clamp(0, _CartConfirmDialog._listMaxHeight).toDouble();
    final requiredDependencies = widget.dependencyPreview.requiredDependencies;
    final blockingIssues = widget.dependencyPreview.blockingIssues;
    final selectedCount = widget.projects.length;
    final requiredCount = requiredDependencies.length;

    return AppModal(
      title: const AppModalTitle('Confirm Installation'),
      subtitle: Text(
        blockingIssues.isNotEmpty
            ? 'Melon found dependency problems that must be fixed before install.'
            : 'Review the selected mods and required dependencies before Melon installs them.',
      ),
      width: 620,
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requiredCount == 0
                  ? 'Install $selectedCount selected mod${selectedCount == 1 ? '' : 's'}.'
                  : 'Install $selectedCount selected mod${selectedCount == 1 ? '' : 's'} + '
                      '$requiredCount required mod${requiredCount == 1 ? '' : 's'}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (blockingIssues.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppModalSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cannot install yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFA7B3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final issue in blockingIssues)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(issue),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: shouldScroll,
                interactive: true,
                child: ListView(
                  controller: _scrollController,
                  primary: false,
                  shrinkWrap: !shouldScroll,
                  physics: shouldScroll
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  children: [
                    const Text('Selected mods:'),
                    const SizedBox(height: 10),
                    for (var index = 0; index < widget.projects.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index == widget.projects.length - 1 &&
                                  requiredDependencies.isEmpty
                              ? 0
                              : 8,
                        ),
                        child: _buildSelectedProjectRow(widget.projects[index]),
                      ),
                    if (requiredDependencies.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Required mods to install automatically:'),
                      const SizedBox(height: 10),
                      for (var index = 0;
                          index < requiredDependencies.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == requiredDependencies.length - 1
                                ? 0
                                : 8,
                          ),
                          child: _buildRequiredDependencyRow(
                            requiredDependencies[index],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: blockingIssues.isNotEmpty
              ? null
              : () => Navigator.of(context).pop(true),
          child: Text(_installButtonLabel(selectedCount, requiredCount)),
        ),
      ],
    );
  }

  Widget _buildSelectedProjectRow(ModrinthProject project) {
    final info = widget.installInfo[project.id];
    final state = info?.state;
    final label = switch (state) {
      ProjectInstallState.updateAvailable => 'Update',
      ProjectInstallState.installed => 'Installed',
      ProjectInstallState.installedUntracked => 'On Disk',
      _ => 'Install',
    };
    final latestVersion =
        info?.latestVersionNumber ?? widget.latestVersionByProject[project.id];
    final installedVersion = info?.installedVersionNumber;
    final versionText = switch (state) {
      ProjectInstallState.updateAvailable =>
        installedVersion != null && latestVersion != null
            ? '$installedVersion -> $latestVersion'
            : latestVersion ?? 'Update available',
      ProjectInstallState.installed =>
        installedVersion ?? latestVersion ?? 'Installed',
      _ => latestVersion ?? 'Latest version: unknown',
    };

    return AppModalSectionCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: project.iconUrl == null
                ? Container(
                    width: 34,
                    height: 34,
                    color: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(
                      Icons.extension_rounded,
                      size: 18,
                    ),
                  )
                : Image.network(
                    project.iconUrl!,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 34,
                      height: 34,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.extension_rounded,
                        size: 18,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version: $versionText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredDependencyRow(DependencyPreviewItem dependency) {
    return AppModalSectionCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.link_rounded, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dependency.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Required version: ${dependency.versionNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Required',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _installButtonLabel(int selectedCount, int requiredCount) {
    if (requiredCount <= 0) {
      return selectedCount == 1
          ? 'Install 1 Mod'
          : 'Install $selectedCount Mods';
    }
    return 'Install $selectedCount + $requiredCount Required';
  }
}

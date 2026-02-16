part of '../modrinth_search_dialog.dart';

class _CartConfirmDialog extends StatefulWidget {
  const _CartConfirmDialog({
    required this.projects,
    required this.installInfo,
    required this.latestVersionByProject,
  });

  static const int _scrollTriggerCount = 4;
  static const double _rowHeight = 62;
  static const double _listMaxHeight = 280;

  final List<ModrinthProject> projects;
  final Map<String, ProjectInstallInfo> installInfo;
  final Map<String, String> latestVersionByProject;

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
        widget.projects.length > _CartConfirmDialog._scrollTriggerCount;
    final desiredHeight =
        widget.projects.length * _CartConfirmDialog._rowHeight;
    final listHeight = shouldScroll
        ? _CartConfirmDialog._listMaxHeight
        : desiredHeight.clamp(0, _CartConfirmDialog._listMaxHeight).toDouble();

    return AlertDialog(
      title: const Text('Confirm Installation'),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected mods:'),
            const SizedBox(height: 10),
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: shouldScroll,
                interactive: true,
                child: ListView.builder(
                  controller: _scrollController,
                  primary: false,
                  shrinkWrap: !shouldScroll,
                  physics: shouldScroll
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: widget.projects.length,
                  itemBuilder: (context, index) {
                    final project = widget.projects[index];
                    final info = widget.installInfo[project.id];
                    final state = info?.state;
                    final label = switch (state) {
                      ProjectInstallState.updateAvailable => 'Update',
                      ProjectInstallState.installed => 'Installed',
                      ProjectInstallState.installedUntracked => 'On Disk',
                      _ => 'Install',
                    };
                    final latestVersion = info?.latestVersionNumber ??
                        widget.latestVersionByProject[project.id];
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

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == widget.projects.length - 1 ? 0 : 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: project.iconUrl == null
                                  ? Container(
                                      width: 34,
                                      height: 34,
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
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
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
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
                      ),
                    );
                  },
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
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Install Now'),
        ),
      ],
    );
  }
}

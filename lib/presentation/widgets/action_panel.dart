import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../viewmodels/app_update_controller.dart';
import 'panel_action_button.dart';

class ActionPanel extends ConsumerStatefulWidget {
  const ActionPanel({
    super.key,
    required this.modsPath,
    required this.onDownloadMods,
    required this.onCheckUpdates,
    required this.onAddFile,
    required this.onImportZip,
    required this.onExportZip,
    required this.onDeleteSelected,
    required this.isBusy,
    required this.hasDeleteSelection,
    required this.downloadLabel,
    this.canCheckUpdates = true,
    this.canZipTools = true,
    this.uiScale = 1.0,
  });

  final String modsPath;
  final VoidCallback onDownloadMods;
  final VoidCallback onCheckUpdates;
  final VoidCallback onAddFile;
  final VoidCallback onImportZip;
  final VoidCallback onExportZip;
  final VoidCallback onDeleteSelected;
  final bool isBusy;
  final bool hasDeleteSelection;
  final String downloadLabel;
  final bool canCheckUpdates;
  final bool canZipTools;
  final double uiScale;

  @override
  ConsumerState<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends ConsumerState<ActionPanel> {
  late final ScrollController _panelScrollController;

  @override
  void initState() {
    super.initState();
    _panelScrollController = ScrollController();
  }

  @override
  void dispose() {
    _panelScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versionLabel = ref.watch(appVersionLabelProvider);
    final environmentInfo = ref.watch(
      environmentInfoProvider(widget.modsPath),
    );
    final appUpdateState = ref.watch(appUpdateControllerProvider);
    final itemGap = (5 * widget.uiScale).clamp(4, 7).toDouble();
    final sectionGap = (10 * widget.uiScale).clamp(8, 12).toDouble();
    final panelPadding = (12 * widget.uiScale).clamp(10, 14).toDouble();
    final primaryHeight = (37 * widget.uiScale).clamp(34, 41).toDouble();
    final secondaryHeight = (34 * widget.uiScale).clamp(31, 37).toDouble();
    final dangerHeight = (35 * widget.uiScale).clamp(32, 39).toDouble();
    final primaryFont = (14 * widget.uiScale).clamp(12.5, 15.5).toDouble();
    final secondaryFont = (13 * widget.uiScale).clamp(11.5, 14.5).toDouble();
    final buttonIcon = (16 * widget.uiScale).clamp(14, 18).toDouble();
    return Container(
      padding: EdgeInsets.all(panelPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: ScrollbarTheme(
                data: ScrollbarTheme.of(context).copyWith(
                  thumbColor: WidgetStatePropertyAll(
                    Colors.white.withValues(alpha: 0.26),
                  ),
                  trackColor: WidgetStatePropertyAll(
                    Colors.white.withValues(alpha: 0.04),
                  ),
                  radius: const Radius.circular(99),
                  thickness: const WidgetStatePropertyAll(4),
                ),
                child: Scrollbar(
                  controller: _panelScrollController,
                  thumbVisibility: false,
                  trackVisibility: false,
                  interactive: true,
                  child: ListView(
                    controller: _panelScrollController,
                    primary: false,
                    padding: EdgeInsets.only(
                      right: (4 * widget.uiScale).clamp(4, 6),
                    ),
                    children: [
                      _SectionLabel(label: 'PRIMARY'),
                      SizedBox(height: itemGap),
                      PanelActionButton(
                        label: widget.downloadLabel,
                        icon: Icons.download_rounded,
                        backgroundColor: const Color(0xFF50F0A8),
                        foregroundColor: Colors.black,
                        onPressed: widget.isBusy ? null : widget.onDownloadMods,
                        height: primaryHeight,
                        fontSize: primaryFont,
                        iconSize: buttonIcon,
                      ),
                      SizedBox(height: itemGap),
                      PanelActionButton(
                        label: widget.canCheckUpdates
                            ? 'Check for Updates'
                            : 'Updates (Mods Only)',
                        icon: Icons.system_update_alt_rounded,
                        backgroundColor: const Color(0xFFFFC15A),
                        foregroundColor: Colors.black,
                        onPressed: widget.isBusy || !widget.canCheckUpdates
                            ? null
                            : widget.onCheckUpdates,
                        height: primaryHeight,
                        fontSize: primaryFont,
                        iconSize: buttonIcon,
                      ),
                      SizedBox(height: sectionGap),
                      _SectionLabel(label: 'FILES'),
                      SizedBox(height: itemGap),
                      PanelActionButton(
                        label: 'Add File',
                        icon: Icons.add_circle_outline_rounded,
                        backgroundColor: const Color(0xFF6AB9FF),
                        foregroundColor: Colors.black,
                        onPressed: widget.isBusy ? null : widget.onAddFile,
                        height: secondaryHeight,
                        fontSize: secondaryFont,
                        iconSize: buttonIcon,
                      ),
                      SizedBox(height: itemGap),
                      PanelActionButton(
                        label: 'Import Zip',
                        icon: Icons.archive_rounded,
                        backgroundColor: const Color(0xFF7AC8FF),
                        foregroundColor: Colors.black,
                        onPressed: widget.isBusy || !widget.canZipTools
                            ? null
                            : widget.onImportZip,
                        height: secondaryHeight,
                        fontSize: secondaryFont,
                        iconSize: buttonIcon,
                      ),
                      SizedBox(height: itemGap),
                      PanelActionButton(
                        label: 'Export Zip',
                        icon: Icons.outbox_rounded,
                        backgroundColor: const Color(0xFF7BE7B5),
                        foregroundColor: Colors.black,
                        onPressed: widget.isBusy || !widget.canZipTools
                            ? null
                            : widget.onExportZip,
                        height: secondaryHeight,
                        fontSize: secondaryFont,
                        iconSize: buttonIcon,
                      ),
                      SizedBox(height: sectionGap),
                      _SectionLabel(label: 'DANGER'),
                      SizedBox(height: itemGap),
                      PanelActionButton(
                        label: 'Delete Selected',
                        icon: Icons.delete_forever_rounded,
                        backgroundColor: const Color(0xFFFF6A7D),
                        foregroundColor: Colors.black,
                        onPressed: widget.isBusy || !widget.hasDeleteSelection
                            ? null
                            : widget.onDeleteSelected,
                        height: dangerHeight,
                        fontSize: secondaryFont,
                        iconSize: buttonIcon,
                      ),
                      SizedBox(height: sectionGap),
                      _SectionLabel(label: 'INFO'),
                      SizedBox(height: itemGap),
                      _EnvironmentInfoCard(
                        snapshotAsync: environmentInfo,
                        uiScale: widget.uiScale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: itemGap),
          Text(
            versionLabel.when(
              data: (v) => v,
              loading: () => 'Loading version...',
              error: (_, __) => 'v1.0.0-beta',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: (10.5 * widget.uiScale).clamp(9.5, 12.5).toDouble(),
            ),
          ),
          SizedBox(height: itemGap),
          PanelActionButton(
            label: switch (appUpdateState.status) {
              AppUpdateCheckStatus.checking => 'Checking Updates...',
              AppUpdateCheckStatus.updateAvailable => 'New App Update',
              AppUpdateCheckStatus.upToDate => 'App is Up to Date',
              AppUpdateCheckStatus.error => 'Retry App Update Check',
              AppUpdateCheckStatus.idle => 'Check App Updates',
            },
            icon: switch (appUpdateState.status) {
              AppUpdateCheckStatus.checking => Icons.sync_rounded,
              AppUpdateCheckStatus.updateAvailable =>
                Icons.new_releases_rounded,
              AppUpdateCheckStatus.upToDate => Icons.verified_rounded,
              AppUpdateCheckStatus.error => Icons.error_outline_rounded,
              AppUpdateCheckStatus.idle => Icons.system_update_rounded,
            },
            backgroundColor: switch (appUpdateState.status) {
              AppUpdateCheckStatus.updateAvailable => const Color(0xFF8E79FF),
              AppUpdateCheckStatus.upToDate => const Color(0xFF3C4E5F),
              AppUpdateCheckStatus.error => const Color(0xFFB44F5E),
              _ => const Color(0xFF2F4253),
            },
            foregroundColor: Colors.white,
            onPressed: appUpdateState.status == AppUpdateCheckStatus.checking
                ? null
                : () => _checkAppUpdates(context, ref),
            height: secondaryHeight,
            fontSize: secondaryFont,
            iconSize: buttonIcon,
          ),
          SizedBox(height: itemGap),
          PanelActionButton(
            label: 'About',
            icon: Icons.info_outline_rounded,
            backgroundColor: const Color(0xFF2E3E4E),
            foregroundColor: Colors.white,
            onPressed: () => _showAboutDialog(context),
            height: secondaryHeight,
            fontSize: secondaryFont,
            iconSize: buttonIcon,
          ),
        ],
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _AboutDialog(),
    );
  }

  Future<void> _checkAppUpdates(BuildContext context, WidgetRef ref) async {
    await ref.read(appUpdateControllerProvider.notifier).checkForUpdates();
    final state = ref.read(appUpdateControllerProvider);
    if (!context.mounted) {
      return;
    }

    switch (state.status) {
      case AppUpdateCheckStatus.updateAvailable:
        final release = state.latestRelease;
        final title = release?.name.isNotEmpty == true
            ? release!.name
            : (release?.tagName ?? 'latest release');
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('App Update Available'),
            content: Text(
              'Current: ${state.currentVersion ?? '-'}\nLatest: ${release?.tagName ?? '-'}\n\n$title',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Release'),
              ),
            ],
          ),
        );
        if (open == true && release != null) {
          final uri = Uri.tryParse(release.htmlUrl);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
      case AppUpdateCheckStatus.upToDate:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App is already up to date.')),
        );
        break;
      case AppUpdateCheckStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message ?? 'Update check failed.')),
        );
        break;
      case AppUpdateCheckStatus.idle:
      case AppUpdateCheckStatus.checking:
        break;
    }
  }
}

class _EnvironmentInfoCard extends StatelessWidget {
  const _EnvironmentInfoCard({
    required this.snapshotAsync,
    required this.uiScale,
  });

  final AsyncValue<EnvironmentInfoSnapshot> snapshotAsync;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final titleSize = (11 * uiScale).clamp(10, 13).toDouble();
    final valueSize = (11.5 * uiScale).clamp(10.5, 13.5).toDouble();

    return Container(
      padding: EdgeInsets.all((8 * uiScale).clamp(7, 11).toDouble()),
      decoration: BoxDecoration(
        color: const Color(0x1129D79D),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2BCF99).withValues(alpha: 0.3)),
      ),
      child: snapshotAsync.when(
        loading: () => const SizedBox(
          height: 36,
          child: Center(child: LinearProgressIndicator(minHeight: 3)),
        ),
        error: (_, __) => Text(
          'Environment info unavailable',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: valueSize,
          ),
        ),
        data: (info) {
          final mcVersion = info.minecraftVersion ?? 'Unknown';
          final isFabric =
              info.loaderName == null || info.loaderName == 'fabric';
          final fabricLabel = isFabric
              ? (info.loaderVersion?.isNotEmpty == true
                  ? info.loaderVersion!
                  : 'Detected, version unknown')
              : 'N/A (${info.loaderName})';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Environment',
                style: TextStyle(
                  color: const Color(0xFF86FDC7),
                  fontWeight: FontWeight.w700,
                  fontSize: titleSize,
                ),
              ),
              SizedBox(height: (3 * uiScale).clamp(2, 5).toDouble()),
              _InfoRow(
                label: 'Minecraft',
                value: mcVersion,
                uiScale: uiScale,
              ),
              SizedBox(height: (2 * uiScale).clamp(2, 4).toDouble()),
              _InfoRow(
                label: 'Fabric',
                value: fabricLabel,
                uiScale: uiScale,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 10,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.uiScale,
  });

  final String label;
  final String value;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final labelSize = (11 * uiScale).clamp(10, 13).toDouble();
    final valueSize = (12 * uiScale).clamp(10.5, 14).toDouble();
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: labelSize,
          ),
        ),
        SizedBox(width: (6 * uiScale).clamp(5, 9).toDouble()),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              fontSize: valueSize,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutDialog extends ConsumerWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(developerSnapshotProvider);
    final versionLabel = ref.watch(appVersionLabelProvider);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
      title: Row(
        children: [
          const Expanded(child: Text('About Melon Mod Manager')),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                versionLabel.when(
                  data: (v) => v,
                  loading: () => 'Loading version...',
                  error: (_, __) => 'v1.0.0-beta',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Goal',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'A simple Windows app to manage Minecraft content packs: scan local folders, install from Modrinth, and keep your setup clean and up to date.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Developer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              snapshot.when(
                data: (data) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.profile.name.isEmpty
                            ? '@${data.profile.login}'
                            : '${data.profile.name} (@${data.profile.login})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (data.profile.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.profile.bio,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _AboutLinkLine(
                        label: 'Profile',
                        url: data.profile.profileUrl,
                      ),
                      const SizedBox(height: 2),
                      _AboutLinkLine(
                        label: 'Repository',
                        url: data.repository.htmlUrl,
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
                error: (_, __) => Text(
                  'Developer info unavailable right now.\n$projectRepositoryUrl',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutLinkLine extends StatelessWidget {
  const _AboutLinkLine({
    required this.label,
    required this.url,
  });

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.74),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _openUrl(context),
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6AB9FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}

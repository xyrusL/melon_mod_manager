import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../viewmodels/app_update_controller.dart';
import 'panel_action_button.dart';

class ActionPanel extends ConsumerWidget {
  const ActionPanel({
    super.key,
    required this.modsPath,
    required this.onDownloadMods,
    required this.onCheckUpdates,
    required this.onAddFile,
    required this.onDeleteSelected,
    required this.isBusy,
    required this.hasDeleteSelection,
    this.uiScale = 1.0,
  });

  final String modsPath;
  final VoidCallback onDownloadMods;
  final VoidCallback onCheckUpdates;
  final VoidCallback onAddFile;
  final VoidCallback onDeleteSelected;
  final bool isBusy;
  final bool hasDeleteSelection;
  final double uiScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionLabel = ref.watch(appVersionLabelProvider);
    final environmentInfo = ref.watch(environmentInfoProvider(modsPath));
    final appUpdateState = ref.watch(appUpdateControllerProvider);
    final spacing = (10 * uiScale).clamp(10, 14).toDouble();
    final buttonHeight = (44 * uiScale).clamp(44, 52).toDouble();
    final buttonFont = (16 * uiScale).clamp(16, 19).toDouble();
    final buttonIcon = (20 * uiScale).clamp(20, 23).toDouble();
    return Container(
      padding: EdgeInsets.all((16 * uiScale).clamp(16, 20).toDouble()),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                PanelActionButton(
                  label: 'Download Mods',
                  icon: Icons.download_rounded,
                  backgroundColor: const Color(0xFF50F0A8),
                  foregroundColor: Colors.black,
                  onPressed: isBusy ? null : onDownloadMods,
                  height: buttonHeight,
                  fontSize: buttonFont,
                  iconSize: buttonIcon,
                ),
                SizedBox(height: spacing),
                PanelActionButton(
                  label: 'Check for Updates',
                  icon: Icons.system_update_alt_rounded,
                  backgroundColor: const Color(0xFFFFC15A),
                  foregroundColor: Colors.black,
                  onPressed: isBusy ? null : onCheckUpdates,
                  height: buttonHeight,
                  fontSize: buttonFont,
                  iconSize: buttonIcon,
                ),
                SizedBox(height: spacing),
                PanelActionButton(
                  label: 'Add File',
                  icon: Icons.add_circle_outline_rounded,
                  backgroundColor: const Color(0xFF6AB9FF),
                  foregroundColor: Colors.black,
                  onPressed: isBusy ? null : onAddFile,
                  height: buttonHeight,
                  fontSize: buttonFont,
                  iconSize: buttonIcon,
                ),
                SizedBox(height: spacing),
                PanelActionButton(
                  label: 'Delete Selected',
                  icon: Icons.delete_forever_rounded,
                  backgroundColor: const Color(0xFFFF6A7D),
                  foregroundColor: Colors.black,
                  onPressed:
                      isBusy || !hasDeleteSelection ? null : onDeleteSelected,
                  height: buttonHeight,
                  fontSize: buttonFont,
                  iconSize: buttonIcon,
                ),
                SizedBox(height: spacing * 1.4),
                _EnvironmentInfoCard(
                  snapshotAsync: environmentInfo,
                  uiScale: uiScale,
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
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
              fontSize: (12 * uiScale).clamp(12, 14).toDouble(),
            ),
          ),
          SizedBox(height: (8 * uiScale).clamp(8, 10).toDouble()),
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
              AppUpdateCheckStatus.updateAvailable => Icons.new_releases_rounded,
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
            height: buttonHeight,
            fontSize: buttonFont,
            iconSize: buttonIcon,
          ),
          SizedBox(height: (8 * uiScale).clamp(8, 10).toDouble()),
          PanelActionButton(
            label: 'About',
            icon: Icons.info_outline_rounded,
            backgroundColor: const Color(0xFF2E3E4E),
            foregroundColor: Colors.white,
            onPressed: () => _showAboutDialog(context),
            height: buttonHeight,
            fontSize: buttonFont,
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
    final titleSize = (13 * uiScale).clamp(13, 15).toDouble();
    final valueSize = (13 * uiScale).clamp(13, 15).toDouble();

    return Container(
      padding: EdgeInsets.all((12 * uiScale).clamp(12, 14).toDouble()),
      decoration: BoxDecoration(
        color: const Color(0x1129D79D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2BCF99).withValues(alpha: 0.3)),
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
          final isFabric = info.loaderName == null || info.loaderName == 'fabric';
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
              SizedBox(height: (8 * uiScale).clamp(8, 10).toDouble()),
              _InfoRow(
                label: 'Minecraft',
                value: mcVersion,
                uiScale: uiScale,
              ),
              SizedBox(height: (6 * uiScale).clamp(6, 8).toDouble()),
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
    final labelSize = (12 * uiScale).clamp(12, 14).toDouble();
    final valueSize = (13 * uiScale).clamp(13, 15).toDouble();
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: labelSize,
          ),
        ),
        SizedBox(width: (8 * uiScale).clamp(8, 10).toDouble()),
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
                'A simple Windows app to manage Fabric/Quilt mods: scan your mods folder, install from Modrinth with required dependencies, and update safely without duplicate files.',
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
                      Text(
                        'Profile: ${data.profile.profileUrl}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Repository: ${data.repository.htmlUrl}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                        ),
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

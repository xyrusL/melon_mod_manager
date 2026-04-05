import 'package:flutter/material.dart';

import '../../data/services/minecraft_path_service.dart';
import '../widgets/app_modal.dart';

enum SituationTone { info, warning, danger }

class SituationDialogSpec {
  const SituationDialogSpec({
    required this.title,
    required this.summary,
    required this.details,
    required this.nextSteps,
    required this.icon,
    required this.accent,
    this.tone = SituationTone.info,
  });

  final String title;
  final String summary;
  final String details;
  final List<String> nextSteps;
  final IconData icon;
  final Color accent;
  final SituationTone tone;
}

SituationDialogSpec situationSpecForAutoDetect(
  AutoDetectModsPathResult result,
) {
  switch (result.status) {
    case AutoDetectModsPathStatus.foundReady:
      return SituationDialogSpec(
        title: 'Minecraft Instance Found',
        summary: 'Melon found a usable modded Minecraft folder.',
        details: result.message,
        nextSteps: const [
          'Review the detected path before continuing.',
          'Use Browse instead if this is not the instance you want.',
        ],
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF4DE8A8),
      );
    case AutoDetectModsPathStatus.foundNeedsCreation:
      return SituationDialogSpec(
        title: 'Mods Folder Not Created Yet',
        summary:
            'Melon found your Minecraft instance, but the mods folder is missing.',
        details: result.message,
        nextSteps: const [
          'Continue and let Melon create the folder for this instance.',
          'If this looks wrong, use Browse and pick the correct folder manually.',
        ],
        icon: Icons.create_new_folder_rounded,
        accent: const Color(0xFFFFC15A),
        tone: SituationTone.warning,
      );
    case AutoDetectModsPathStatus.noLoaderInstance:
      return SituationDialogSpec(
        title: 'Minecraft Found, But Loader Is Unsupported',
        summary:
            'Melon found Minecraft instances, but none of them looked like Fabric, Quilt, Forge, or NeoForge.',
        details: result.message,
        nextSteps: const [
          'Start the modded instance you actually use, then try Auto-detect again.',
          'If your mods folder is already known, use Browse and select it directly.',
        ],
        icon: Icons.extension_off_rounded,
        accent: const Color(0xFFFF8B6B),
        tone: SituationTone.warning,
      );
    case AutoDetectModsPathStatus.notFound:
      return SituationDialogSpec(
        title: 'No Minecraft Instance Detected',
        summary:
            'Melon could not find a usable Minecraft Java mods folder on this PC.',
        details: result.message,
        nextSteps: const [
          'Open the launcher and run the instance once so its folders exist.',
          'Use Browse if your Minecraft files live in a custom location.',
        ],
        icon: Icons.search_off_rounded,
        accent: const Color(0xFFFF8B6B),
        tone: SituationTone.warning,
      );
  }
}

SituationDialogSpec situationSpecForEnvironmentDetection({
  required String actionLabel,
  String? minecraftVersion,
  String? loaderName,
}) {
  final missingLoader = loaderName == null || loaderName.trim().isEmpty;
  final missingVersion =
      minecraftVersion == null || minecraftVersion.trim().isEmpty;

  if (!missingLoader && !missingVersion) {
    return SituationDialogSpec(
      title: 'Environment Ready',
      summary: 'Melon identified this modded instance.',
      details:
          'Minecraft $minecraftVersion with ${_formatLoaderName(loaderName)} detected.',
      nextSteps: const [
        'Continue normally.',
      ],
      icon: Icons.check_circle_rounded,
      accent: const Color(0xFF4DE8A8),
    );
  }

  final title = switch ((missingLoader, missingVersion)) {
    (true, true) => 'Can’t Identify This Modded Instance',
    (true, false) => 'Can’t Identify The Mod Loader',
    (false, true) => 'Can’t Identify The Minecraft Version',
    _ => 'Environment Detection Problem',
  };

  final details = switch ((missingLoader, missingVersion)) {
    (true, true) =>
      'Melon could not detect the mod loader or the Minecraft version from this folder.',
    (true, false) =>
      'Melon detected Minecraft $minecraftVersion, but could not tell whether this instance uses Fabric, Quilt, Forge, or NeoForge.',
    (false, true) =>
      'Melon detected ${_formatLoaderName(loaderName)}, but could not determine the Minecraft version tied to this folder.',
    _ => 'Melon could not identify enough information about this instance.',
  };

  return SituationDialogSpec(
    title: title,
    summary:
        'Melon can still try to $actionLabel, but results may be incomplete or mismatched.',
    details: details,
    nextSteps: const [
      'Continue only if you know this folder is correct.',
      'If needed, browse to the exact instance folder or launcher profile you use.',
      'Inside the next screen, review the loader/version filters before installing anything.',
    ],
    icon: Icons.warning_amber_rounded,
    accent: const Color(0xFFFFC15A),
    tone: SituationTone.warning,
  );
}

SituationDialogSpec situationSpecForMissingSavedPath(String path) {
  return SituationDialogSpec(
    title: 'Saved Mods Folder Is Unavailable',
    summary:
        'The folder Melon was using is missing, moved, or no longer accessible.',
    details: path,
    nextSteps: const [
      'Create the folder again if this is still the right location.',
      'Use Auto-detect or Browse to switch to the correct Minecraft instance.',
    ],
    icon: Icons.folder_off_rounded,
    accent: const Color(0xFFFF8B6B),
    tone: SituationTone.warning,
  );
}

SituationDialogSpec situationSpecForUnknownProblem([String? details]) {
  return SituationDialogSpec(
    title: 'Problem Detected',
    summary:
        'Melon found a user-facing problem, but could not classify it cleanly.',
    details: (details == null || details.trim().isEmpty)
        ? 'No extra details were available.'
        : details,
    nextSteps: const [
      'Double-check the selected path and current Minecraft instance.',
      'Try Auto-detect or Browse again.',
      'If the issue keeps happening, export the bug log from the internal error dialog if one appears.',
    ],
    icon: Icons.help_outline_rounded,
    accent: const Color(0xFF79B8FF),
    tone: SituationTone.info,
  );
}

class SituationDialog extends StatelessWidget {
  const SituationDialog({
    super.key,
    required this.spec,
    this.actions = const <Widget>[],
    this.width = 560,
  });

  final SituationDialogSpec spec;
  final List<Widget> actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AppModal(
      width: width,
      title: Row(
        children: [
          _SituationBadge(spec: spec),
          const SizedBox(width: 14),
          Expanded(child: AppModalTitle(spec.title)),
        ],
      ),
      subtitle: Text(spec.summary),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppModalSectionCard(
            child: Text(
              spec.details,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
          if (spec.nextSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppModalSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you can do next',
                    style: TextStyle(
                      color: spec.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...spec.nextSteps.map(_buildStep),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.circle,
              size: 7,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SituationBadge extends StatelessWidget {
  const _SituationBadge({required this.spec});

  final SituationDialogSpec spec;

  @override
  Widget build(BuildContext context) {
    final background = switch (spec.tone) {
      SituationTone.info => spec.accent.withValues(alpha: 0.14),
      SituationTone.warning => spec.accent.withValues(alpha: 0.16),
      SituationTone.danger => spec.accent.withValues(alpha: 0.18),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: spec.accent.withValues(alpha: 0.44)),
        boxShadow: [
          BoxShadow(
            color: spec.accent.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(spec.icon, color: spec.accent, size: 24),
    );
  }
}

String _formatLoaderName(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'fabric':
      return 'Fabric';
    case 'quilt':
      return 'Quilt';
    case 'forge':
      return 'Forge';
    case 'neoforge':
      return 'NeoForge';
    default:
      return value == null || value.trim().isEmpty ? 'unknown loader' : value;
  }
}

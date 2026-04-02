import 'dart:io';

class ReleaseMetadata {
  const ReleaseMetadata({
    required this.appVersion,
    required this.tagName,
    required this.isPrerelease,
    required this.releaseChannel,
    required this.releaseTitle,
  });

  final String appVersion;
  final String tagName;
  final bool isPrerelease;
  final String releaseChannel;
  final String releaseTitle;
}

String parseAppVersion(String pubspecContent) {
  final match =
      RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pubspecContent);
  if (match == null) {
    throw const FormatException('Could not find version in pubspec.yaml.');
  }
  final raw = match.group(1)?.trim() ?? '';
  if (raw.isEmpty) {
    throw const FormatException('pubspec.yaml version is empty.');
  }
  return raw.split('+').first.trim();
}

ReleaseMetadata resolveReleaseMetadata({
  required String pubspecContent,
  String? tagName,
}) {
  final appVersion = parseAppVersion(pubspecContent);
  final expectedTag = 'v$appVersion';
  final resolvedTag = (tagName == null || tagName.trim().isEmpty)
      ? expectedTag
      : tagName.trim();

  if (resolvedTag != expectedTag) {
    throw FormatException(
      "Tag/version mismatch. Tag is '$resolvedTag' but pubspec.yaml expects '$expectedTag'.",
    );
  }

  final isStableDateRelease =
      RegExp(r'^\d+\.\d+\.\d+-\d{4}\.\d{2}\.\d{2}$').hasMatch(appVersion);
  final isStableSemver = RegExp(r'^\d+\.\d+\.\d+$').hasMatch(appVersion);
  final isBeta = RegExp(r'-beta(\.|$)').hasMatch(appVersion);
  final isPrerelease =
      isBeta || (appVersion.contains('-') && !isStableDateRelease);
  final releaseChannel = isBeta
      ? 'Beta'
      : (isStableDateRelease || isStableSemver)
          ? 'Stable'
          : 'Pre-release';

  var releaseTitle = 'Melon Mod Manager $appVersion';
  if (releaseChannel == 'Beta') {
    releaseTitle = '$releaseTitle (Beta)';
  }

  return ReleaseMetadata(
    appVersion: appVersion,
    tagName: resolvedTag,
    isPrerelease: isPrerelease,
    releaseChannel: releaseChannel,
    releaseTitle: releaseTitle,
  );
}

Future<void> main(List<String> args) async {
  var pubspecPath = 'pubspec.yaml';
  String? tagName;
  String? githubOutputPath;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--pubspec':
        pubspecPath = args[++i];
        break;
      case '--tag':
        tagName = args[++i];
        break;
      case '--github-output':
        githubOutputPath = args[++i];
        break;
      default:
        throw ArgumentError('Unknown argument: ${args[i]}');
    }
  }

  final pubspecFile = File(pubspecPath);
  if (!await pubspecFile.exists()) {
    throw ArgumentError('pubspec.yaml not found at $pubspecPath');
  }

  final metadata = resolveReleaseMetadata(
    pubspecContent: await pubspecFile.readAsString(),
    tagName: tagName,
  );

  final outputLines = <String>[
    'app_version=${metadata.appVersion}',
    'tag_name=${metadata.tagName}',
    'is_prerelease=${metadata.isPrerelease}',
    'release_channel=${metadata.releaseChannel}',
    'release_title=${metadata.releaseTitle}',
  ];

  if (githubOutputPath != null && githubOutputPath.isNotEmpty) {
    final file = File(githubOutputPath);
    final sink = file.openWrite(mode: FileMode.append);
    for (final line in outputLines) {
      sink.writeln(line);
    }
    await sink.flush();
    await sink.close();
    return;
  }

  stdout.writeln(outputLines.join('\n'));
}

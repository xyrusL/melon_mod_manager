import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entities/github_release.dart';
import 'github_api_client.dart';

class AppUpdateResult {
  const AppUpdateResult({
    required this.currentVersion,
    required this.latestRelease,
    required this.hasUpdate,
  });

  final String currentVersion;
  final GitHubRelease latestRelease;
  final bool hasUpdate;
}

class AppUpdateService {
  AppUpdateService({
    required GitHubApiClient apiClient,
    required this.owner,
    required this.repository,
    Future<String> Function()? currentVersionProvider,
  })  : _apiClient = apiClient,
        _currentVersionProvider = currentVersionProvider ?? _defaultVersionProvider;

  final GitHubApiClient _apiClient;
  final String owner;
  final String repository;
  final Future<String> Function() _currentVersionProvider;

  Future<AppUpdateResult> checkForUpdate() async {
    final currentVersion = (await _currentVersionProvider()).trim();

    final latest = (await _apiClient.getLatestRelease(owner, repository)).toEntity();

    final currentComparable = _normalizeTag(currentVersion);
    final latestComparable = _normalizeTag(latest.tagName);
    final comparison = _compareSemantic(latestComparable, currentComparable);

    return AppUpdateResult(
      currentVersion: currentVersion,
      latestRelease: latest,
      hasUpdate: comparison > 0,
    );
  }

  static Future<String> _defaultVersionProvider() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  String _normalizeTag(String value) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().startsWith('v')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  int _compareSemantic(String a, String b) {
    final parsedA = _parseVersion(a);
    final parsedB = _parseVersion(b);
    if (parsedA == null || parsedB == null) {
      return a.compareTo(b);
    }

    for (var i = 0; i < 3; i++) {
      final diff = parsedA.core[i].compareTo(parsedB.core[i]);
      if (diff != 0) {
        return diff;
      }
    }

    return _comparePrerelease(parsedA.preRelease, parsedB.preRelease);
  }

  _SemVersion? _parseVersion(String value) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:[-+]([^+]+))?$').firstMatch(value);
    if (match == null) {
      return null;
    }

    return _SemVersion(
      core: [
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      ],
      preRelease: match.group(4),
    );
  }

  int _comparePrerelease(String? a, String? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }

    final aParts = a.split('.');
    final bParts = b.split('.');
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < maxLen; i++) {
      if (i >= aParts.length) {
        return -1;
      }
      if (i >= bParts.length) {
        return 1;
      }
      final cmp = _comparePrereleasePart(aParts[i], bParts[i]);
      if (cmp != 0) {
        return cmp;
      }
    }

    return 0;
  }

  int _comparePrereleasePart(String a, String b) {
    final aNum = int.tryParse(a);
    final bNum = int.tryParse(b);

    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }
    if (aNum != null) {
      return -1;
    }
    if (bNum != null) {
      return 1;
    }

    return a.compareTo(b);
  }
}

class _SemVersion {
  const _SemVersion({required this.core, this.preRelease});

  final List<int> core;
  final String? preRelease;
}

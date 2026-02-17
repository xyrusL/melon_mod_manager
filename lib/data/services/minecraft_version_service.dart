import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'instance_dir_utils.dart';

class MinecraftVersionService {
  Future<String?> detectVersionFromModsPath(String modsPath) async {
    final pathVersion = _detectFromPathSegments(modsPath);
    if (pathVersion != null) {
      return pathVersion;
    }

    final mmcVersion = await _detectFromPrismOrMmcMetadata(modsPath);
    if (mmcVersion != null) {
      return mmcVersion;
    }

    final cfgVersion = await _detectFromInstanceCfg(modsPath);
    if (cfgVersion != null) {
      return cfgVersion;
    }

    return null;
  }

  String? _detectFromPathSegments(String modsPath) {
    final normalized = modsPath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();

    final mcIndex = segments.lastIndexOf('.minecraft');
    if (mcIndex > 0) {
      final beforeMinecraft = _extractVersion(segments[mcIndex - 1]);
      if (beforeMinecraft != null) {
        return beforeMinecraft;
      }
    }

    for (final segment in segments.reversed) {
      final value = _extractVersion(segment);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  Future<String?> _detectFromPrismOrMmcMetadata(String modsPath) async {
    final candidates = candidateInstanceDirs(modsPath);
    for (final dir in candidates) {
      final mmcPack = File(p.join(dir.path, 'mmc-pack.json'));
      if (!await mmcPack.exists()) {
        continue;
      }

      try {
        final decoded = jsonDecode(await mmcPack.readAsString());
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        final components = decoded['components'];
        if (components is! List) {
          continue;
        }

        for (final component in components.whereType<Map>()) {
          final uid = component['uid']?.toString();
          if (uid == 'net.minecraft') {
            final version = component['version']?.toString();
            if (version != null && version.trim().isNotEmpty) {
              return version.trim();
            }
          }
        }
      } catch (_) {
        // Keep best-effort detection behavior.
      }
    }

    return null;
  }

  Future<String?> _detectFromInstanceCfg(String modsPath) async {
    final candidates = candidateInstanceDirs(modsPath);
    for (final dir in candidates) {
      final instanceCfg = File(p.join(dir.path, 'instance.cfg'));
      if (!await instanceCfg.exists()) {
        continue;
      }

      try {
        final lines = await instanceCfg.readAsLines();
        for (final line in lines) {
          if (!line.startsWith('MinecraftVersion=')) {
            continue;
          }
          final value = line.split('=').skip(1).join('=').trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      } catch (_) {
        // Keep best-effort detection behavior.
      }
    }

    return null;
  }

  String? _extractVersion(String raw) {
    final lowered = raw.toLowerCase();

    final prefixed =
        RegExp(r'mc(1\.\d{1,2}(?:\.\d+){0,2})').firstMatch(lowered);
    if (prefixed != null) {
      return prefixed.group(1);
    }

    final plain = RegExp(r'(1\.\d{1,2}(?:\.\d+){0,2})').firstMatch(lowered);
    if (plain != null) {
      return plain.group(1);
    }

    return null;
  }
}

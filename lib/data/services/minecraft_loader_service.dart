import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class DetectedLoader {
  const DetectedLoader({
    required this.loader,
    this.version,
  });

  final String loader;
  final String? version;
}

class MinecraftLoaderService {
  Future<DetectedLoader?> detectLoaderFromModsPath(String modsPath) async {
    final mmcLoader = await _detectFromPrismOrMmcMetadata(modsPath);
    if (mmcLoader != null) {
      return mmcLoader;
    }

    final cfgLoader = await _detectFromInstanceCfg(modsPath);
    if (cfgLoader != null) {
      return cfgLoader;
    }

    return _detectFromPathSegments(modsPath);
  }

  Future<DetectedLoader?> _detectFromPrismOrMmcMetadata(String modsPath) async {
    final candidates = _candidateInstanceDirs(modsPath);
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

        // Prefer more specific loaders first.
        for (final component in components.whereType<Map>()) {
          final detected = _detectFromMmcComponent(component);
          if (detected?.loader == 'neoforge') {
            return detected;
          }
        }

        for (final component in components.whereType<Map>()) {
          final detected = _detectFromMmcComponent(component);
          if (detected?.loader == 'quilt') {
            return detected;
          }
        }

        for (final component in components.whereType<Map>()) {
          final detected = _detectFromMmcComponent(component);
          if (detected?.loader == 'fabric') {
            return detected;
          }
        }

        for (final component in components.whereType<Map>()) {
          final detected = _detectFromMmcComponent(component);
          if (detected?.loader == 'forge') {
            return detected;
          }
        }
      } catch (_) {
        // Keep best-effort behavior.
      }
    }
    return null;
  }

  Future<DetectedLoader?> _detectFromInstanceCfg(String modsPath) async {
    final candidates = _candidateInstanceDirs(modsPath);
    for (final dir in candidates) {
      final instanceCfg = File(p.join(dir.path, 'instance.cfg'));
      if (!await instanceCfg.exists()) {
        continue;
      }

      try {
        final lines = await instanceCfg.readAsLines();
        for (final line in lines) {
          final lowered = line.toLowerCase();
          if (lowered.contains('neoforge')) {
            final version = _extractLoaderVersionFromLine(lowered, 'neoforge');
            return DetectedLoader(loader: 'neoforge', version: version);
          }
          if (lowered.contains('quilt')) {
            final version = _extractLoaderVersionFromLine(lowered, 'quilt');
            return DetectedLoader(loader: 'quilt', version: version);
          }
          if (lowered.contains('fabric')) {
            final version = _extractLoaderVersionFromLine(lowered, 'fabric');
            return DetectedLoader(loader: 'fabric', version: version);
          }
          if (lowered.contains('forge')) {
            final version = _extractLoaderVersionFromLine(lowered, 'forge');
            return DetectedLoader(loader: 'forge', version: version);
          }
        }
      } catch (_) {
        // Keep best-effort behavior.
      }
    }
    return null;
  }

  DetectedLoader? _detectFromPathSegments(String modsPath) {
    final normalized = modsPath.toLowerCase().replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty);

    for (final segment in segments) {
      if (segment.contains('neoforge')) {
        return const DetectedLoader(loader: 'neoforge');
      }
      if (segment.contains('quilt')) {
        return const DetectedLoader(loader: 'quilt');
      }
      if (segment.contains('fabric')) {
        return const DetectedLoader(loader: 'fabric');
      }
      if (segment.contains('forge')) {
        return const DetectedLoader(loader: 'forge');
      }
    }

    return null;
  }

  DetectedLoader? _detectFromMmcComponent(Map component) {
    final uid = component['uid']?.toString().toLowerCase();
    final version = component['version']?.toString().trim();

    if (uid == null) {
      return null;
    }

    if (uid == 'org.quiltmc.quilt-loader' || uid.contains('quilt-loader')) {
      return DetectedLoader(loader: 'quilt', version: version);
    }
    if (uid == 'net.fabricmc.fabric-loader' || uid.contains('fabric-loader')) {
      return DetectedLoader(loader: 'fabric', version: version);
    }
    if (uid.contains('neoforge')) {
      return DetectedLoader(loader: 'neoforge', version: version);
    }
    if (uid == 'net.minecraftforge' || uid.endsWith('.forge')) {
      return DetectedLoader(loader: 'forge', version: version);
    }

    return null;
  }

  String? _extractLoaderVersionFromLine(String line, String loader) {
    final keyValue = RegExp(
      '(?:^|[\\s_.-])$loader(?:[_\\s.-]?loader)?(?:[_\\s.-]?version)?\\s*=\\s*([0-9][a-z0-9+._-]*)',
    );
    final keyMatch = keyValue.firstMatch(line);
    if (keyMatch != null) {
      return keyMatch.group(1);
    }

    final inline = RegExp(
      '$loader(?:[_\\s.-]?loader)?[_\\s.-]?([0-9][a-z0-9+._-]*)',
    );
    final inlineMatch = inline.firstMatch(line);
    return inlineMatch?.group(1);
  }

  List<Directory> _candidateInstanceDirs(String modsPath) {
    final modsDir = Directory(modsPath);
    final parent = Directory(p.dirname(modsDir.path));
    final grandParent = Directory(p.dirname(parent.path));

    final candidates = <Directory>[grandParent, parent, modsDir];
    return candidates
        .where((d) => d.path.trim().isNotEmpty)
        .fold<List<Directory>>([], (acc, dir) {
      if (acc.any((e) => p.normalize(e.path) == p.normalize(dir.path))) {
        return acc;
      }
      acc.add(dir);
      return acc;
    });
  }
}

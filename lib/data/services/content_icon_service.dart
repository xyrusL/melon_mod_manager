import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ContentIconService {
  Future<String?> extractPackIcon(String archivePath) async {
    final file = File(archivePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final inputStream = InputFileStream(archivePath);
      late final Archive archive;
      try {
        archive = ZipDecoder().decodeBuffer(inputStream, verify: false);
      } finally {
        inputStream.close();
      }

      ArchiveFile? candidate;
      for (final entry in archive.files) {
        if (entry.isFile != true) {
          continue;
        }
        final fullName = entry.name.toLowerCase();
        final name = p.basename(fullName);
        if (name != 'pack.png' && name != 'icon.png') {
          continue;
        }
        if (candidate == null || entry.name.length < candidate.name.length) {
          candidate = entry;
        }
      }

      if (candidate == null) {
        return null;
      }

      final stat = await file.stat();
      final key =
          '${file.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
      final hash = sha1.convert(utf8.encode(key)).toString();

      final supportDir = await getApplicationSupportDirectory();
      final iconDir =
          Directory(p.join(supportDir.path, 'melon_mod', 'content_icon_cache'));
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }

      final iconFile = File(p.join(iconDir.path, '$hash.png'));
      if (!await iconFile.exists()) {
        final content = candidate.content;
        if (content is! List<int> || content.isEmpty) {
          return null;
        }
        await iconFile.writeAsBytes(content, flush: true);
      }

      return iconFile.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> cacheProjectIcon({
    required String projectId,
    String? iconUrl,
  }) async {
    final normalizedUrl = iconUrl?.trim();
    if (projectId.trim().isEmpty ||
        normalizedUrl == null ||
        normalizedUrl.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null) {
        return null;
      }

      final supportDir = await getApplicationSupportDirectory();
      final iconDir =
          Directory(p.join(supportDir.path, 'melon_mod', 'content_icon_cache'));
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }

      final ext = _iconFileExtension(uri);
      final cacheKey = sha1.convert(
        utf8.encode('${projectId.trim()}|$normalizedUrl'),
      );
      final iconFile = File(p.join(iconDir.path, '${cacheKey.toString()}$ext'));
      if (await iconFile.exists() && await iconFile.length() > 0) {
        return iconFile.path;
      }

      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          return null;
        }
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (bytes.isEmpty) {
          return null;
        }
        await iconFile.writeAsBytes(bytes, flush: true);
        return iconFile.path;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }

  String _iconFileExtension(Uri uri) {
    final ext = p.extension(uri.path).toLowerCase();
    return switch (ext) {
      '.png' || '.jpg' || '.jpeg' || '.webp' => ext,
      _ => '.png',
    };
  }

  Future<void> clearIconCache() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final iconDir =
          Directory(p.join(supportDir.path, 'melon_mod', 'content_icon_cache'));
      if (await iconDir.exists()) {
        await iconDir.delete(recursive: true);
      }
    } catch (_) {
      // Cache cleanup should be best-effort only.
    }
  }
}

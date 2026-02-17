import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ContentIconService {
  Future<String?> extractPackIcon(String archivePath) async {
    final file = File(archivePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);

      ArchiveFile? candidate;
      ArchiveFile? fallbackImage;
      for (final entry in archive.files) {
        if (entry.isFile != true) {
          continue;
        }
        final fullName = entry.name.toLowerCase();
        final name = p.basename(fullName);
        final isImage = name.endsWith('.png') ||
            name.endsWith('.jpg') ||
            name.endsWith('.jpeg');
        if (isImage && fallbackImage == null) {
          fallbackImage = entry;
        }
        if (name != 'pack.png' && name != 'icon.png') {
          continue;
        }
        if (candidate == null || entry.name.length < candidate.name.length) {
          candidate = entry;
        }
      }

      candidate ??= fallbackImage;
      if (candidate == null) {
        return null;
      }

      final stat = await file.stat();
      final key =
          '${file.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
      final hash = sha1.convert(utf8.encode(key)).toString();

      final tempDir = await getTemporaryDirectory();
      final iconDir =
          Directory(p.join(tempDir.path, 'melon_mod', 'content_icon_cache'));
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
}

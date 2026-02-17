import 'dart:io';

import 'package:crypto/crypto.dart';

class FileHashService {
  Future<String?> computeSha1(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final stat = await file.stat();
      if (stat.size <= 0) {
        return null;
      }
      final digest = await sha1.bind(file.openRead()).first;
      return digest.toString();
    } catch (_) {
      return null;
    }
  }
}

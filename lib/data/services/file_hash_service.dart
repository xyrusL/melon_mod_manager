import 'dart:io';

import 'package:crypto/crypto.dart';

class FileHashService {
  Future<String?> computeSha1(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      return sha1.convert(bytes).toString();
    } catch (_) {
      return null;
    }
  }
}

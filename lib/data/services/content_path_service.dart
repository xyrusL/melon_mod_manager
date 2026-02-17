import 'package:path/path.dart' as p;

import '../../domain/entities/content_type.dart';

class ContentPathService {
  String resolveContentPath({
    required String modsPath,
    required ContentType contentType,
  }) {
    final normalized = p.normalize(modsPath);
    final baseName = p.basename(normalized).toLowerCase();
    final knownContentFolders = {
      ContentType.mod.folderName,
      ContentType.resourcePack.folderName,
      ContentType.shaderPack.folderName,
    };
    final instanceRoot = knownContentFolders.contains(baseName)
        ? p.dirname(normalized)
        : normalized;
    return p.join(instanceRoot, contentType.folderName);
  }
}

import 'dart:io';

import 'package:path/path.dart' as p;

List<Directory> candidateInstanceDirs(String modsPath) {
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

class ModrinthVersion {
  const ModrinthVersion({
    required this.id,
    required this.projectId,
    required this.name,
    required this.versionNumber,
    required this.datePublished,
    required this.loaders,
    required this.gameVersions,
    required this.files,
    required this.dependencies,
  });

  final String id;
  final String projectId;
  final String name;
  final String versionNumber;
  final DateTime datePublished;
  final List<String> loaders;
  final List<String> gameVersions;
  final List<ModrinthFile> files;
  final List<ModrinthDependency> dependencies;

  ModrinthFile? get primaryJarFile {
    final jarFiles = files.where(
      (f) => f.fileName.toLowerCase().endsWith('.jar'),
    );
    for (final file in jarFiles) {
      if (file.primary) {
        return file;
      }
    }
    return jarFiles.isEmpty ? null : jarFiles.first;
  }
}

enum ModrinthDependencyType { required, optional, incompatible, embedded }

class ModrinthDependency {
  const ModrinthDependency({
    required this.type,
    this.projectId,
    this.versionId,
    this.fileName,
  });

  final ModrinthDependencyType type;
  final String? projectId;
  final String? versionId;
  final String? fileName;
}

class ModrinthFile {
  const ModrinthFile({
    required this.fileName,
    required this.url,
    required this.size,
    required this.primary,
    this.sha1,
    this.sha512,
  });

  final String fileName;
  final String url;
  final int size;
  final bool primary;
  final String? sha1;
  final String? sha512;
}

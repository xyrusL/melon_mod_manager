import '../../domain/entities/modrinth_version.dart';

class ModrinthVersionModel {
  const ModrinthVersionModel({
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
  final List<ModrinthFileModel> files;
  final List<ModrinthDependencyModel> dependencies;

  factory ModrinthVersionModel.fromJson(Map<String, dynamic> json) {
    return ModrinthVersionModel(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      versionNumber: json['version_number'] as String? ?? 'Unknown',
      datePublished:
          DateTime.tryParse(json['date_published'] as String? ?? '') ??
              DateTime(1970),
      loaders: ((json['loaders'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      gameVersions: ((json['game_versions'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      files: ((json['files'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ModrinthFileModel.fromJson)
          .toList(),
      dependencies: ((json['dependencies'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ModrinthDependencyModel.fromJson)
          .toList(),
    );
  }

  ModrinthVersion toEntity() {
    return ModrinthVersion(
      id: id,
      projectId: projectId,
      name: name,
      versionNumber: versionNumber,
      datePublished: datePublished,
      loaders: loaders,
      gameVersions: gameVersions,
      files: files.map((f) => f.toEntity()).toList(),
      dependencies: dependencies.map((d) => d.toEntity()).toList(),
    );
  }
}

class ModrinthFileModel {
  const ModrinthFileModel({
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

  factory ModrinthFileModel.fromJson(Map<String, dynamic> json) {
    final hashes = json['hashes'] is Map<String, dynamic>
        ? json['hashes'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ModrinthFileModel(
      fileName: json['filename'] as String? ?? '',
      url: json['url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      primary: json['primary'] as bool? ?? false,
      sha1: hashes['sha1'] as String?,
      sha512: hashes['sha512'] as String?,
    );
  }

  ModrinthFile toEntity() {
    return ModrinthFile(
      fileName: fileName,
      url: url,
      size: size,
      primary: primary,
      sha1: sha1,
      sha512: sha512,
    );
  }
}

class ModrinthDependencyModel {
  const ModrinthDependencyModel({
    required this.type,
    this.projectId,
    this.versionId,
    this.fileName,
  });

  final String type;
  final String? projectId;
  final String? versionId;
  final String? fileName;

  factory ModrinthDependencyModel.fromJson(Map<String, dynamic> json) {
    return ModrinthDependencyModel(
      type: json['dependency_type'] as String? ?? 'required',
      projectId: json['project_id'] as String?,
      versionId: json['version_id'] as String?,
      fileName: json['file_name'] as String?,
    );
  }

  ModrinthDependency toEntity() {
    return ModrinthDependency(
      type: switch (type) {
        'required' => ModrinthDependencyType.required,
        'optional' => ModrinthDependencyType.optional,
        'incompatible' => ModrinthDependencyType.incompatible,
        'embedded' => ModrinthDependencyType.embedded,
        _ => ModrinthDependencyType.required,
      },
      projectId: projectId,
      versionId: versionId,
      fileName: fileName,
    );
  }
}

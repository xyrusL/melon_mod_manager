class ModrinthMapping {
  const ModrinthMapping({
    required this.jarFileName,
    required this.projectId,
    required this.versionId,
    required this.installedAt,
    this.sha1,
    this.sha512,
  });

  final String jarFileName;
  final String projectId;
  final String versionId;
  final DateTime installedAt;
  final String? sha1;
  final String? sha512;

  Map<String, dynamic> toJson() => {
        'jarFileName': jarFileName,
        'projectId': projectId,
        'versionId': versionId,
        'installedAt': installedAt.toIso8601String(),
        'sha1': sha1,
        'sha512': sha512,
      };

  factory ModrinthMapping.fromJson(Map<String, dynamic> json) {
    return ModrinthMapping(
      jarFileName: json['jarFileName'] as String,
      projectId: json['projectId'] as String,
      versionId: json['versionId'] as String,
      installedAt: DateTime.parse(json['installedAt'] as String),
      sha1: json['sha1'] as String?,
      sha512: json['sha512'] as String?,
    );
  }
}

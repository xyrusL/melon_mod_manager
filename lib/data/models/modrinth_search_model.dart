import '../../domain/entities/modrinth_project.dart';

class ModrinthSearchHitModel {
  const ModrinthSearchHitModel({
    required this.projectId,
    required this.slug,
    required this.title,
    required this.description,
    this.iconUrl,
  });

  final String projectId;
  final String slug;
  final String title;
  final String description;
  final String? iconUrl;

  factory ModrinthSearchHitModel.fromJson(Map<String, dynamic> json) {
    return ModrinthSearchHitModel(
      projectId: json['project_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
    );
  }

  ModrinthProject toEntity() {
    return ModrinthProject(
      id: projectId,
      slug: slug,
      title: title,
      description: description,
      iconUrl: iconUrl,
    );
  }
}

import '../../domain/entities/modrinth_project.dart';

class ModrinthSearchHitModel {
  const ModrinthSearchHitModel({
    required this.projectId,
    required this.slug,
    required this.title,
    required this.description,
    this.iconUrl,
    this.downloads = 0,
    this.follows = 0,
  });

  final String projectId;
  final String slug;
  final String title;
  final String description;
  final String? iconUrl;
  final int downloads;
  final int follows;

  factory ModrinthSearchHitModel.fromJson(Map<String, dynamic> json) {
    return ModrinthSearchHitModel(
      projectId: json['project_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      downloads: json['downloads'] as int? ?? 0,
      follows: json['follows'] as int? ?? 0,
    );
  }

  ModrinthProject toEntity() {
    return ModrinthProject(
      id: projectId,
      slug: slug,
      title: title,
      description: description,
      iconUrl: iconUrl,
      downloads: downloads,
      follows: follows,
    );
  }
}

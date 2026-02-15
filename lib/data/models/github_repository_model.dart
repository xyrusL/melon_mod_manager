import '../../domain/entities/github_repository.dart';

class GitHubRepositoryModel {
  const GitHubRepositoryModel({
    required this.name,
    required this.fullName,
    required this.description,
    required this.htmlUrl,
    required this.stars,
    required this.forks,
    required this.updatedAt,
  });

  final String name;
  final String fullName;
  final String description;
  final String htmlUrl;
  final int stars;
  final int forks;
  final DateTime? updatedAt;

  factory GitHubRepositoryModel.fromJson(Map<String, dynamic> json) {
    return GitHubRepositoryModel(
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      stars: json['stargazers_count'] as int? ?? 0,
      forks: json['forks_count'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  GitHubRepository toEntity() {
    return GitHubRepository(
      name: name,
      fullName: fullName,
      description: description,
      htmlUrl: htmlUrl,
      stars: stars,
      forks: forks,
      updatedAt: updatedAt,
    );
  }
}

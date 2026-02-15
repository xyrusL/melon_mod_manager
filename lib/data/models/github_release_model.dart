import '../../domain/entities/github_release.dart';

class GitHubReleaseModel {
  const GitHubReleaseModel({
    required this.tagName,
    required this.name,
    required this.htmlUrl,
    required this.body,
    required this.prerelease,
    required this.draft,
    required this.publishedAt,
  });

  final String tagName;
  final String name;
  final String htmlUrl;
  final String body;
  final bool prerelease;
  final bool draft;
  final DateTime? publishedAt;

  factory GitHubReleaseModel.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseModel(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }

  GitHubRelease toEntity() {
    return GitHubRelease(
      tagName: tagName,
      name: name,
      htmlUrl: htmlUrl,
      body: body,
      prerelease: prerelease,
      draft: draft,
      publishedAt: publishedAt,
    );
  }
}

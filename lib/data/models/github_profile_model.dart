import '../../domain/entities/github_profile.dart';

class GitHubProfileModel {
  const GitHubProfileModel({
    required this.login,
    required this.name,
    required this.avatarUrl,
    required this.profileUrl,
    required this.bio,
    required this.followers,
    required this.publicRepos,
    required this.updatedAt,
  });

  final String login;
  final String name;
  final String avatarUrl;
  final String profileUrl;
  final String bio;
  final int followers;
  final int publicRepos;
  final DateTime? updatedAt;

  factory GitHubProfileModel.fromJson(Map<String, dynamic> json) {
    return GitHubProfileModel(
      login: json['login'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      profileUrl: json['html_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      followers: json['followers'] as int? ?? 0,
      publicRepos: json['public_repos'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  GitHubProfile toEntity() {
    return GitHubProfile(
      login: login,
      name: name,
      avatarUrl: avatarUrl,
      profileUrl: profileUrl,
      bio: bio,
      followers: followers,
      publicRepos: publicRepos,
      updatedAt: updatedAt,
    );
  }
}

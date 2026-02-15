class GitHubProfile {
  const GitHubProfile({
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
}

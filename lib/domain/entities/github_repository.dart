class GitHubRepository {
  const GitHubRepository({
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
}

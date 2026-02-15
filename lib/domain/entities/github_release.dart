class GitHubRelease {
  const GitHubRelease({
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
}

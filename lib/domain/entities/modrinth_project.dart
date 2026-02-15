class ModrinthProject {
  const ModrinthProject({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.iconUrl,
    this.downloads = 0,
    this.follows = 0,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String? iconUrl;
  final int downloads;
  final int follows;
}

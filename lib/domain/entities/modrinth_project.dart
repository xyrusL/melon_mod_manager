class ModrinthProject {
  const ModrinthProject({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.iconUrl,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String? iconUrl;
}

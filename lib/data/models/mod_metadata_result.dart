class ModMetadataResult {
  const ModMetadataResult({
    required this.fileName,
    required this.filePath,
    required this.name,
    required this.version,
    required this.modId,
    required this.lastModified,
    this.iconBytes,
    this.iconCachePath,
  });

  final String fileName;
  final String filePath;
  final String name;
  final String version;
  final String modId;
  final DateTime lastModified;
  final List<int>? iconBytes;
  final String? iconCachePath;
}

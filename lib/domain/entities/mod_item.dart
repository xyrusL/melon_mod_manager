enum ModProviderType { modrinth, external }

extension ModProviderTypeLabel on ModProviderType {
  String get label {
    return switch (this) {
      ModProviderType.modrinth => 'Modrinth',
      ModProviderType.external => 'External',
    };
  }
}

class ModItem {
  const ModItem({
    required this.fileName,
    required this.filePath,
    required this.displayName,
    required this.version,
    required this.modId,
    required this.provider,
    required this.lastModified,
    this.iconCachePath,
    this.modrinthProjectId,
    this.modrinthVersionId,
  });

  final String fileName;
  final String filePath;
  final String displayName;
  final String version;
  final String modId;
  final ModProviderType provider;
  final DateTime lastModified;
  final String? iconCachePath;
  final String? modrinthProjectId;
  final String? modrinthVersionId;

  bool get isUpdatable =>
      provider == ModProviderType.modrinth &&
      modrinthProjectId != null &&
      modrinthProjectId!.isNotEmpty;

  ModItem copyWith({
    String? fileName,
    String? filePath,
    String? displayName,
    String? version,
    String? modId,
    ModProviderType? provider,
    DateTime? lastModified,
    String? iconCachePath,
    String? modrinthProjectId,
    String? modrinthVersionId,
  }) {
    return ModItem(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      displayName: displayName ?? this.displayName,
      version: version ?? this.version,
      modId: modId ?? this.modId,
      provider: provider ?? this.provider,
      lastModified: lastModified ?? this.lastModified,
      iconCachePath: iconCachePath ?? this.iconCachePath,
      modrinthProjectId: modrinthProjectId ?? this.modrinthProjectId,
      modrinthVersionId: modrinthVersionId ?? this.modrinthVersionId,
    );
  }
}

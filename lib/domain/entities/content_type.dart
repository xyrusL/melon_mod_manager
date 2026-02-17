enum ContentType { mod, resourcePack, shaderPack }

extension ContentTypeLabel on ContentType {
  String get label {
    return switch (this) {
      ContentType.mod => 'Mods',
      ContentType.resourcePack => 'Resource Packs',
      ContentType.shaderPack => 'Shaders',
    };
  }

  String get singularLabel {
    return switch (this) {
      ContentType.mod => 'Mod',
      ContentType.resourcePack => 'Resource Pack',
      ContentType.shaderPack => 'Shader Pack',
    };
  }

  String get folderName {
    return switch (this) {
      ContentType.mod => 'mods',
      ContentType.resourcePack => 'resourcepacks',
      ContentType.shaderPack => 'shaderpacks',
    };
  }

  String get modrinthProjectType {
    return switch (this) {
      ContentType.mod => 'mod',
      ContentType.resourcePack => 'resourcepack',
      ContentType.shaderPack => 'shader',
    };
  }

  bool get supportsLoaderFilter => this == ContentType.mod;
}

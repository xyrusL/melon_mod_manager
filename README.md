# Melon Mod Manager

Windows Flutter app to manage Minecraft mods from one place.

## Features

- Select or auto-detect a `mods` folder
- Browse and install mods from Modrinth
- Check updates, review found updates, then update all
- Add external `.jar` files
- Delete selected mods
- Error overlay with copy/export logs for crashes

## Supported loaders

- Fabric
- Quilt
- Forge
- NeoForge

The app auto-detects loader + Minecraft version from the selected instance path when possible.

## Quick start (Windows)

```bash
flutter pub get
flutter run -d windows
```

## Build and test

```bash
flutter test
dart analyze lib
```

## Notes

- Only Modrinth-managed mods can be auto-updated.
- External mods are shown in the list but are skipped by Modrinth update flow.

## Repository

`https://github.com/xyrusL/melon_mod_manager`

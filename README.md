# Melon Mod Manager

Windows Flutter app to manage Minecraft content from one place.

## What is new in 1.0.0-beta.2

- Added shader pack management support.
- Added resource pack management support.
- Fixed multiple bugs and runtime errors.
- Improved internal logic for better stability.

## Core features

- Select or auto-detect Minecraft folders
- Browse and install mods from Modrinth
- Check updates, review found updates, then update all
- Add external `.jar` files
- Manage shader packs and resource packs
- Delete selected entries
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

## Release (beta.2)

1. Ensure `pubspec.yaml` version is `1.0.0-beta.2+1`.
2. Commit and push changes to `main`.
3. Create and push the matching tag:

```bash
git tag v1.0.0-beta.2
git push origin v1.0.0-beta.2
```

Or use the helper script to create and push the beta tag in one step:

```powershell
.\scripts\release.ps1 -Channel beta -Push
```

The release workflow at `.github/workflows/release-windows.yml` will run analyze/test, build Windows assets, and publish the installer, portable zip, and checksums.

## Notes

- Only Modrinth-managed mods can be auto-updated.
- External mods are shown in the list but are skipped by Modrinth update flow.

## Repository

`https://github.com/xyrusL/melon_mod_manager`

## License

This project uses the MIT License. You are allowed to use, modify, and fork this project, including for redistribution, as long as you keep the original copyright and license notice.

- Full license text: `LICENSE`
- Credit source: `https://github.com/xyrusL/melon_mod_manager`

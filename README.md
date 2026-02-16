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

## Create a GitHub release (Windows installer + portable zip)

The repository includes CI automation at `.github/workflows/release-windows.yml`.

1. Update `pubspec.yaml` version.
2. Commit and push to `main`.
3. Create and push a matching tag in the format `v<pubspec-version-without-build>`.

Example for current app version:

```bash
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

On tag push, GitHub Actions will:
- run `flutter analyze` and `flutter test`
- build Windows release binaries
- generate:
  - installer `.exe` (Inno Setup)
  - portable `.zip`
- publish both assets to the GitHub Release page

If you already created a tag before this workflow existed, go to:
`Actions -> Release Windows -> Run workflow`
and provide the existing tag (for example `v1.0.0-beta.1`).

## Notes

- Only Modrinth-managed mods can be auto-updated.
- External mods are shown in the list but are skipped by Modrinth update flow.

## Repository

`https://github.com/xyrusL/melon_mod_manager`

## License

This project uses the MIT License. You are allowed to use, modify, and fork this project, including for redistribution, as long as you keep the original copyright and license notice.

- Full license text: `LICENSE`
- Credit source: `https://github.com/xyrusL/melon_mod_manager`

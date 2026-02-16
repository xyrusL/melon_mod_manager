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
  - `SHA256SUMS.txt` for file integrity verification
- publish both assets to the GitHub Release page

### Release helper script (prerelease / beta)

You can create release tags using:

```powershell
.\scripts\release.ps1 -Channel prerelease
.\scripts\release.ps1 -Channel beta
```

To create and push the tag in one step:

```powershell
.\scripts\release.ps1 -Channel beta -Push
```

Rules:
- `prerelease` requires a pubspec version containing `-` (example: `1.1.0-rc.1`).
- `beta` requires `-beta` or `-beta.N` (example: `1.1.0-beta.2`).
- Script checks for a clean git working tree and prevents duplicate tags.

If you already created a tag before this workflow existed, go to:
`Actions -> Release Windows -> Run workflow`
and provide the existing tag (for example `v1.0.0-beta.1`).

### Optional: Windows code signing in CI

If you have a code-signing certificate (`.pfx`), the release workflow can sign:
- `melon_mod_manager.exe` (app binary)
- `MelonModManager-Win64-Setup-<version>.exe` (installer)

Configure repository secrets:
- `WINDOWS_SIGN_PFX_BASE64`
- `WINDOWS_SIGN_PFX_PASSWORD`

To create `WINDOWS_SIGN_PFX_BASE64` on Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\codesign.pfx"))
```

If these secrets are not set, the workflow still works and skips signing.

## Notes

- Only Modrinth-managed mods can be auto-updated.
- External mods are shown in the list but are skipped by Modrinth update flow.

## Repository

`https://github.com/xyrusL/melon_mod_manager`

## License

This project uses the MIT License. You are allowed to use, modify, and fork this project, including for redistribution, as long as you keep the original copyright and license notice.

- Full license text: `LICENSE`
- Credit source: `https://github.com/xyrusL/melon_mod_manager`

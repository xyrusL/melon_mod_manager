## Melon Mod Manager 1.7.1

This 1.7.1 update improves Modrinth installs and offline handling, so Melon is clearer about required dependency mods and stays friendlier when your connection drops.

### Fixes and improvements

- Added an offline warning inside Modrinth download screens for mods, resource packs, and shaders.
- Download screens now show Retry and Exit when there is no internet connection, while the rest of Melon stays usable offline.
- Added a required dependency preview before mod installs start.
- Melon now auto-installs required Modrinth dependencies after one confirmation.
- Shared required dependencies are deduplicated, and blocking dependency issues are shown before install begins.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

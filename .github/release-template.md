## Melon Mod Manager Beta 6.1

This Beta 6.1 update focuses on fixing shader and pack icons so installed content is represented more reliably in the app.

### Fixes and improvements

- Fixed shader pack icons not showing in the Shaders tab for Modrinth-tracked packs.
- Added Modrinth project icon fallback when a local `pack.png` or `icon.png` is missing.
- Removed the incorrect fallback that could show a random internal texture as the item icon.
- Improved local icon caching so pack icons persist more reliably after rescans and app restarts.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

## Melon Mod Manager 1.7.5

This 1.7.5 update focuses on safer file handling so imported bundles and downloaded content stay inside the intended Minecraft folders.

### Fixes and improvements

- Hardened bundle import and Modrinth install paths against unsafe file names and path traversal attempts.
- Added shared file-name validation so only expected `.jar` and `.zip` content types are written to disk.
- Protected cleanup flows from deleting files outside the managed content folders when stale metadata is malformed.
- Added regression tests that verify unsafe archive entries are rejected before any file is written.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

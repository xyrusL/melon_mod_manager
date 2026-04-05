## Melon Mod Manager 7.7.9

Tag: `v7.7.9`

This 7.7.9 release fixes the user-facing environment and path handling flow, cleans up legacy UI behavior, and prepares the desktop builds for release from the current tag.

### Fixes and improvements

- Moved the sidebar scrollbar farther away from the action rows so it stays clearly visible without crowding the buttons.
- Added guided situation modals for Minecraft detection failures, missing mods folders, unknown loader or version detection, and other user-facing setup problems.
- Added a fallback problem modal for cases that do not match a known situation cleanly.
- Kept the internal bug-catch modal separate and improved its reporting guidance so exported logs are more useful for debugging.
- Removed the legacy inline SVG logo path and switched the app to the checked-in asset logo, eliminating the unsupported `<filter>` runtime warning from the old loader path.
- Updated the app version metadata to `7.7.9`.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

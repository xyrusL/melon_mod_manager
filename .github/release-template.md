## Melon Mod Manager Beta 6.2

This Beta 6.2 update focuses on polishing the app flow after an update and making popup dialogs feel consistent across the whole app.

### Fixes and improvements

- Updated popup dialogs to use the new shared modal layout across update flows, folder prompts, file conflicts, and Modrinth install flows.
- Added a post-update modal that tells users the app update is complete and offers a data refresh right away.
- Added refresh handling for Modrinth-backed mods, shader packs, and resource packs after an app update.
- Clarified the refresh result so users can see that non-Modrinth items are skipped instead of treated like an error.
- Removed leftover legacy modal code to keep the UI layer cleaner and easier to maintain.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

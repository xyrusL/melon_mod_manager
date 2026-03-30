## Melon Mod Manager 1.6.3

This 1.6.3 update moves Melon to the new stable date-based version format and polishes the app flow after an update with more consistent popup dialogs.

### Fixes and improvements

- Updated popup dialogs to use the new shared modal layout across update flows, folder prompts, file conflicts, and Modrinth install flows.
- Added a post-update modal that tells users the app update is complete and offers a data refresh right away.
- Added refresh handling for Modrinth-backed mods, shader packs, and resource packs after an app update.
- Clarified the refresh result so users can see that non-Modrinth items are skipped instead of treated like an error.
- Prevented users from closing update settings or saving while local data refresh is still running, with a short wait message.
- Removed leftover legacy modal code to keep the UI layer cleaner and easier to maintain.
- Switched app versioning to the stable `UPGRADE.MAJOR.MINOR-YYYY.MM.DD` format.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

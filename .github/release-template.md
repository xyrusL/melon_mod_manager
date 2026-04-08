## Melon Mod Manager 1.7.8

Tag: `v1.7.8`

This 1.7.8 release adds a first-run welcome flow for brand-new users, keeps existing users from seeing that intro during upgrades, and improves the release stability around the new onboarding flow.

### Fixes and improvements

- Added a multi-step welcome flow for brand-new users before setup starts.
- Added a replayable welcome guide inside the app so the intro can be viewed again later.
- Kept the welcome flow aligned with the current app theme for a more consistent first impression.
- Prevented existing users who update Melon from being treated like first-time installs.
- Added a development-only preview toggle so the welcome flow can be tested locally without affecting release behavior.
- Fixed the onboarding test flow so release validation is stable across Windows and Linux.
- Updated the app version metadata to `1.7.8`.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

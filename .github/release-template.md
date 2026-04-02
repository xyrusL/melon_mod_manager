## Melon Mod Manager 1.7.2

This 1.7.2 update refreshes Melon's auto-update timing so checks can run on practical hourly schedules without drifting into long monthly gaps.

### Fixes and improvements

- Auto-update checks now support hourly, daily, and weekly frequencies.
- The default check interval is now every 8 hours.
- Added new quick presets: 1 hour, 3 hours, 8 hours, 12 hours, 1 day, 2 days, and 1 week.
- Custom frequency now uses a value plus unit picker for hours, days, or weeks.
- Removed Off and monthly update checks.
- Custom intervals longer than 1 week are now rejected with a clear validation message.

### Included assets

- Windows installer (`MelonModManager-Win64-Setup-<version>.exe`)
- Portable Windows build (`melon_mod_manager_windows_portable.zip`)
- Linux package (`MelonModManager-Linux-Setup-<version>.tar.gz`)
- Checksums (`SHA256SUMS.txt`, `SHA256SUMS-linux.txt`)

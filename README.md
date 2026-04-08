# <img src="assets/logo/melon_logo.svg" alt="Melon Mod Manager logo" width="28" /> Melon Mod Manager

A desktop app to manage Minecraft mods, shaders, and resource packs in one place.

## App Preview

![Download from Modrinth Preview](assets/screenshots/download_mod.png)

## Feature Highlights

Melon Mod Manager helps you keep your Minecraft setup organized without digging through folders by hand.

- 🔎 Search Modrinth for mods, shaders, and resource packs from inside the app
- 📦 Install content directly to the right folder without leaving the manager
- 🧩 Detect required dependencies before install and add them automatically when available
- 🚀 Check for compatible updates and update tracked Modrinth installs in a few clicks
- 🗂️ Manage mods, shader packs, and resource packs from one desktop UI
- 🖱️ Add local `.jar` and `.zip` files with drag-and-drop or the file picker
- 🏷️ See which items came from Modrinth, which are external, and which can be updated
- 📁 Detect your Minecraft folder, game version, and supported mod loader to reduce setup guesswork
- 📤 Import and export zip bundles for backup, migration, or sharing
- 🛠️ Rebuild local metadata, review app update status, and export error details when troubleshooting

## Compatible Devices

- Operating System: Windows 10/11 (64-bit), Linux (x64)
- Minecraft Loaders: Fabric, Quilt, Forge, NeoForge
- Internet Required: Yes, for Modrinth search and downloads

## Why People Use It

- ✅ Keeps your Minecraft content in one place instead of spreading work across folders, browser tabs, and launchers
- ✅ Makes Modrinth downloads and updates easier to track
- ✅ Handles both Modrinth installs and manually added files in the same library
- ✅ Cuts down setup mistakes with version and loader-aware install flows

## About This Project

This is a personal open-source project built to make Minecraft mod management simpler and safer.

### Antivirus Note

Some antivirus tools may flag this app because it is a new or unsigned Windows application. This is a common false positive for small desktop apps.

You can verify the app by:

- Reviewing the source code in this repository
- Building it yourself from source
- Comparing downloaded files against the included SHA256 checksums

## Quick Start

1. Download the latest release from the [Releases page](https://github.com/xyrusL/melon_mod_manager/releases)
2. Windows: run `MelonModManager-Win64-Setup-<version>.exe` or extract the portable zip
3. Linux: extract `MelonModManager-Linux-Setup-<version>.tar.gz` and run `melon_mod_manager`
4. Launch Melon Mod Manager
5. Select your Minecraft folder
6. Start browsing and installing content

## For Developers

```bash
flutter pub get
flutter run -d windows
flutter run -d linux
flutter test
flutter analyze
```

## Important Notes

- Back up important saves before changing your mod setup

## Links

- Repository: https://github.com/xyrusL/melon_mod_manager
- Issues: https://github.com/xyrusL/melon_mod_manager/issues
- Modrinth: https://modrinth.com

## License

GNU GPL v3.0 License. See the [LICENSE](LICENSE) file for details.

Made for the Minecraft community

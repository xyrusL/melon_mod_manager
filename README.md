# <img src="assets/logo/melon_logo.svg" alt="Melon Mod Manager logo" width="28" /> Melon Mod Manager

A desktop app to manage your Minecraft mods, shaders, and resource packs all in one place. No more hunting through folders or manually checking for updates!

## App Preview

![Download from Modrinth Preview](assets/screenshots/download_mod.png)

## What Does This App Do?

**Melon Mod Manager** makes it easy to:
- **Browse & Download** mods, shaders, and resource packs directly from Modrinth
- **Update Everything** with one click - no need to check each mod individually
- **Auto-Detect** your Minecraft installation and loader type
- **Drag & Drop** files to quickly add new content
- **Manage All Your Content** - view, organize, and delete unwanted items
- **Import/Export** mod packs to share with friends or backup your setup

Think of it as a one-stop shop for keeping your Minecraft mods organized and up-to-date!

## Compatible Devices

- **Operating System:** Windows 10/11 (64-bit), Linux (x64)
- **Minecraft Loaders:** Fabric, Quilt, Forge, NeoForge
- **Internet Required:** Yes (for downloading and checking updates from Modrinth)

## What's New in Beta 6

- ⚡ Faster browsing and search: latest-version results are cached in the Modrinth dialog, reducing repeated lookups.
- 🧠 Better instance detection: loader and Minecraft version detection now reuses shared instance-directory logic for Prism/MMC-style layouts.
- 🛡️ Safer bundle imports: resource pack and shader pack archives are validated before install, and bundle type mismatches are blocked.
- ✅ Improved file handling performance: icon extraction and file comparison now use more efficient streaming paths for large archives/files.
- 🧹 Smoother content list loading: pack metadata/icon loading is batched and filtered list results are cached for a more responsive UI.

## Key Features

✅ **Smart Detection** - Automatically finds your Minecraft folders and figures out which loader you're using  
✅ **One-Click Updates** - Check all your mods for updates and install them together  
✅ **Modrinth Integration** - Browse thousands of mods with easy search and filters  
✅ **Drag & Drop** - Just drag `.jar` or `.zip` files into the app to add them  
✅ **Mod Packs** - Export your mod list to share or import someone else's pack  
✅ **External Mods** - Works with mods from any source, not just Modrinth  
✅ **Error Logging** - If something goes wrong, easily export logs to get help

## About This Project

This is a **personal open-source project** created to make Minecraft modding easier for everyone. It's completely free to use and modify.

### ⚠️ Antivirus Note
Some antivirus software may flag this app as suspicious because it's a new/unsigned Windows application. This is a **false positive**. You can verify the app is safe by:
- Checking the [full source code](https://github.com/xyrusL/melon_mod_manager) - everything is open and transparent
- No data collection, no telemetry, no hidden behavior
- Built with Flutter - a trusted framework by Google

If you're concerned, feel free to review the code or build it yourself from source!

## Quick Start

1. Download the latest release from the [Releases page](https://github.com/xyrusL/melon_mod_manager/releases)
2. Windows: run `MelonModManager-Win64-Setup-<version>.exe` or extract portable zip
3. Linux: extract `MelonModManager-Linux-Setup-<version>.tar.gz` and run `melon_mod_manager`
4. Launch **Melon Mod Manager**
5. Select your Minecraft folder (it usually auto-detects!)
6. Start browsing and installing mods!

## For Developers

Want to build from source or contribute?

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run -d windows
flutter run -d linux

# Run tests
flutter test
dart analyze lib
```

## Important Notes

- Only mods downloaded through Modrinth can be auto-updated
- External mods (added manually) will appear in your list but won't receive automatic updates
- Always backup your saves before updating mods!

## Links

- **Repository:** https://github.com/xyrusL/melon_mod_manager
- **Issues:** https://github.com/xyrusL/melon_mod_manager/issues
- **Modrinth:** https://modrinth.com

## License

GNU GPL v3.0 License - Free to use, modify, and share under GPL-3.0 terms. See the [LICENSE](LICENSE) file for details.

Made with 💚 for the Minecraft community

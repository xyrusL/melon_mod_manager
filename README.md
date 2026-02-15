# Melon Mod Manager (Flutter Windows)

Melon Mod Manager helps you **download, install, and update Minecraft Fabric/Quilt mods** from one place.

It is built for players who want easy mod management without manually moving `.jar` files every time.

## What this app is for

- Keep your mods organized in one selected `mods` folder
- Install mods from Modrinth quickly
- Update supported mods safely
- Add external `.jar` files when needed

## Who should use it

- Players using official launchers
- Players using custom launchers
- Players using non-official/cracked launchers

As long as you can select the correct Minecraft `mods` folder, the app can manage that folder.

## Main features (simple view)

- First-time setup with saved mods path
- Auto-detect of default Windows Minecraft mods folder
- Mod list with name, version, source/provider, and last modified date
- Modrinth search + install flow
- Safe update flow (temp file + atomic replace)
- External install (`Add File`) for non-Modrinth `.jar` files

## Main goal

Make mod management easy for non-technical users:

1. Choose your mods folder once
2. See what is installed
3. Install new mods
4. Update mods with safer handling

## Quick start (Windows)

1. Install dependencies:

```bash
flutter pub get
```

2. Run desktop app:

```bash
flutter run -d windows
```

## Notes for users

- If updates are unavailable for a mod, it may not be linked to a Modrinth-managed install.
- Mods added manually still appear in the list and can be managed as local files.

## Developer info (optional)

### Project structure

- `lib/data`: API client, file/path/scanner services, repository implementations
- `lib/domain`: entities, repository interfaces, use cases
- `lib/presentation`: screens, dialogs, widgets, Riverpod viewmodels
- `lib/core`: dependency wiring, theme, error reporter

State management: `flutter_riverpod`

### Test

```bash
flutter test
```

### Windows symlink note

If `flutter pub get` fails with a symlink message, enable Windows Developer Mode:

```text
start ms-settings:developers
```

Then retry `flutter pub get`.

### Modrinth API configuration

- Base URL is set in `lib/data/services/modrinth_api_client.dart`
- Client is created in `lib/core/providers.dart` via `modrinthApiClientProvider`

### Update reliability model

Only mods installed via the app's Modrinth flow are marked as Modrinth-managed.

Mapping stored in Hive:
- key: jar filename
- value: `projectId`, `versionId`, optional hashes, install timestamp

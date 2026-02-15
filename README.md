# Melon Mod Manager (Flutter Windows)

Production-ready Flutter desktop app for managing Minecraft Fabric/Quilt mods from a user-selected `.minecraft/mods` folder.

## Features

- First-run setup with persisted mods path (`shared_preferences`)
- Auto-detect default Minecraft mods folder on Windows
- Incremental `.jar` scan with isolate-based metadata parsing
- Mod table with icon, name, version, provider, last modified
- Modrinth integration: search, install, and update
- External install (`Add File`) for non-Modrinth `.jar` files
- Safe update flow with temp file + atomic replace
- Local Modrinth mapping DB (`hive`) for reliable updates

## Architecture

- `lib/data`: API client, file/path/scanner services, repository implementations
- `lib/domain`: entities, repository interfaces, use cases
- `lib/presentation`: screens, dialogs, widgets, Riverpod viewmodels
- `lib/core`: dependency wiring, theme, error reporter

State management: `flutter_riverpod`

## Run

1. Install dependencies:

```bash
flutter pub get
```

2. Run on Windows desktop:

```bash
flutter run -d windows
```

3. Run tests:

```bash
flutter test
```

## Note for Windows symlink support

If `flutter pub get` fails with a symlink message, enable Windows Developer Mode:

```text
start ms-settings:developers
```

Then retry `flutter pub get`.

## Modrinth API configuration

- Base URL is set in `lib/data/services/modrinth_api_client.dart`:
  - `ModrinthApiClient(..., String baseUrl = 'https://api.modrinth.com/v2')`
- Client is created in `lib/core/providers.dart` via `modrinthApiClientProvider`.
- To change environments, update the provider constructor override or pass a custom `baseUrl` there.

## Update reliability model

Only mods installed via the app's Modrinth flow are marked as Modrinth-managed.

Mapping stored in Hive:
- key: jar filename
- value: `projectId`, `versionId`, optional hashes, install timestamp

For non-mapped mods, update is skipped with:

```text
Cannot update: not from Modrinth
```

# Melon Mod Manager (Flutter Windows)

Melon Mod Manager is a Flutter desktop app for Windows that helps Minecraft players manage Fabric/Quilt mods safely from a selected `.minecraft/mods` folder.

## Purpose

Provide a focused, reliable mod management tool so users can install, track, and update mods without manually handling `.jar` files every time, regardless of the Minecraft launcher/client they use.

## App Goals

- Make mod installation and updates simple for non-technical users
- Reduce broken mod setups with safer install/update flows
- Keep mod metadata visible and searchable in one place
- Support both Modrinth-managed mods and external `.jar` mods
- Work with any launcher setup (official, custom, or non-official) as long as users can select the correct mods folder path

## Features

- First-run setup with persisted mods path (`shared_preferences`)
- Auto-detect default Minecraft mods folder on Windows
- Incremental `.jar` scan with isolate-based metadata parsing
- Mod table with icon, name, version, provider, and last modified timestamp
- Modrinth integration for search, install, and update workflows
- External install (`Add File`) for non-Modrinth `.jar` files
- Safe update flow using temporary file + atomic replace
- Local Modrinth mapping DB (`hive`) to keep update detection reliable
- Riverpod-based state management for predictable UI state handling

## Goal in Practice

The app is designed to be the day-to-day control panel for Minecraft mod folders: choose your mods directory once, view what is installed, install new mods, and perform safer updates with clear feedback.

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

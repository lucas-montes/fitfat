# Overview

**fitfat** is a mobile-first calorie and exercise tracking app built with Flutter. The UI is developed first with mock data via Riverpod, then connected to a local database (Drift) in a later phase.

## Project

| Attribute | Value |
|-----------|-------|
| Name | fitfat |
| Tech | Flutter 3.38.3 (Dart 3.10.1) |
| Platforms | Android, iOS, Linux, macOS, Windows, Web (mobile-first) |
| State mgmt | Riverpod |
| Navigation | go_router |
| Theme | Material 3 (light + dark) |
| Charts | fl_chart (planned) |
| Storage | Local-only (Drift/SQLite in Phase 2) |

## Implementation phases

- **Phase 1 (current):** Build all screens with mock data via Riverpod providers. Iterate on UI freely.
- **Phase 2 (planned):** Replace mocks with Drift database, add barcode scanner and pedometer hardware integration.

## Current status

- `main.dart` — app entry point with `ProviderScope` wrapper; bootstrap includes `FlutterForegroundTask.initCommunicationPort()` for background-service messaging
- `lib/src/app.dart` — `FitFatApp` with `MaterialApp.router`
- `lib/src/app_theme.dart` — Material 3 light/dark themes (Indigo seed)
- `lib/src/router/` — GoRouter with 3 routes (diet, exercise, dashboard)
- `lib/src/screens/` — Diet tab has Meals/Ingredients tabs; Exercise tab has Exercises/Seances tabs; Dashboard shows daily/monthly nutrition + goals
- `lib/src/services/seance_foreground_service.dart` — NEW: Foreground service wrapper for background timer via `flutter_foreground_task`
- `lib/src/widgets/appbar_seance_indicator.dart` — NEW: AppBar action widget showing running-seance icon + elapsed time; visible on all tabs
- Platform changes: Android manifest (`FOREGROUND_SERVICE` permission), iOS plist/AppDelegate for background-task support

**Latest iteration (Session X - T01):**
- Implemented background timer + persistent notification for active seances
- Added AppBar indicator across all tabs (Diet, Dashboard, Exercise) showing seance progress
- Both Android (foreground service) and iOS (background task) platforms configured
- All Dart code analyzer-clean; widget tests passing
- Device testing pending (see `context/tmp/T01-implementation-summary.md`)

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

- `main.dart` — app entry point with `ProviderScope` wrapper
- `lib/src/app.dart` — `FitFatApp` with `MaterialApp.router`
- `lib/src/app_theme.dart` — Material 3 light/dark themes (Indigo seed)
- `lib/src/router/` — GoRouter with 4 routes (food, exercise, dashboard, settings)
- `lib/src/screens/` — Food tab has meal list + add/edit/delete flow; other tabs placeholder

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

- **Phase 1 (current):** Complete all remaining features — Goals simplification, tab order fix, fl_chart strength trend, Drift persistence.
- **Phase 2 (planned):** UI/UX polish pass — consistency, states, responsive layout — then validation and context sync.

## Current status

- `main.dart` — app entry point with `ProviderScope` wrapper; bootstrap includes `FlutterForegroundTask.initCommunicationPort()` for background-service messaging
- `lib/src/app.dart` — `FitFatApp` with `MaterialApp.router`
- `lib/src/app_theme.dart` — Material 3 light/dark themes (Indigo seed)
- `lib/src/router/` — GoRouter with 3 routes (diet, exercise, dashboard) — currently opens on Diet as default (T07 will change to Dashboard)
- `lib/src/screens/` — Diet tab has Meals/Ingredients tabs (full CRUD); Exercise tab has Exercises/Seances tabs (+ template library, create/edit/clone/start); Dashboard shows daily/monthly nutrition + goals
- `lib/src/services/seance_foreground_service.dart` — Foreground service wrapper for background timer via `flutter_foreground_task`
- `lib/src/widgets/appbar_seance_indicator.dart` — AppBar action widget showing running-seance icon + elapsed time; visible on all tabs
- Platform changes: Android manifest (`FOREGROUND_SERVICE` permission), iOS plist/AppDelegate for background-task support

**Completed features:**
- Diet CRUD (meals + ingredients with add/edit/delete)
- Exercise list, seance lifecycle (start/stop/add sets/timer/complete/history)
- Seance template system (create/edit/clone/start from template, repository pattern)
- Background timer with persistent notification (Android foreground service + iOS best-effort)
- AppBar seance indicator on all tabs
- Dashboard daily nutrition card with computed macro targets
- Goal system: sealed `Goal` types (`StrengthGoal | BodyWeightGoal`) with user profile (age/sex/height/weight/activity) and TDEE-based macro computation (Mifflin-St Jeor)
- Goal type selector dialog (Gain Strength / Change Body Weight) with read-only computed macros
- Strength/bodyweight trend charts (placeholder implementations)

**Next up:** Tab order fix (T07), fl_chart strength trend (T08), Drift persistence (T09), UI/UX polish (T10), validation (T11).

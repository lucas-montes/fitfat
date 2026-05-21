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
| Charts | fl_chart (in use — strength trend) |
| Storage | Local-only (Drift/SQLite in Phase 2) |

## Implementation phases

- **Phase 1 (done):** All features complete — diet CRUD, exercise seance + templates + timer, goals system, charts, Dashboard tabs.
- **Phase 2 (done):** UI/UX polish — Diet Add Ingredient title, Dashboard goals tabs + multi-goal, Exercise tab reorder + Current Seance tab, stop/cancel, seance flow redesign.
- **Phase 3 (done):** Post-MVP polish — birthdate profile, maintenance macros, goal UX, template editing, seance navigation improvement.

## Current status

- `main.dart` — app entry point with `ProviderScope` wrapper; bootstrap includes `FlutterForegroundTask.initCommunicationPort()` for background-service messaging
- `lib/src/app.dart` — `FitFatApp` with `MaterialApp.router`
- `lib/src/app_theme.dart` — Material 3 light/dark themes (Indigo seed)
- `lib/src/router/` — GoRouter with 3 routes (diet, dashboard, exercise) — opens on Dashboard as default, bottom nav order: Diet / Dashboard / Exercise
- `lib/src/screens/` — Diet tab has Meals/Ingredients tabs (full CRUD); Exercise tab has Exercises/Seances tabs (+ template library, create/edit/clone/start); Dashboard has Overview + Goals tabs with nutrition, charts, and goal management
- `lib/src/services/seance_foreground_service.dart` — Foreground service wrapper for background timer via `flutter_foreground_task`
- `lib/src/widgets/appbar_seance_indicator.dart` — AppBar action widget showing running-seance icon + elapsed time; visible on all tabs
- Platform changes: Android manifest (`FOREGROUND_SERVICE` permission), iOS plist/AppDelegate for background-task support

**Completed features:**
- Diet CRUD (meals + ingredients with add/edit/delete)
- Exercise list, seance lifecycle (start/stop/add sets/timer/complete/history)
- Seance template system (create/edit/clone/start from template, repository pattern)
- Background timer with persistent notification (Android foreground service + iOS best-effort)
- AppBar seance indicator on all tabs
- Dashboard split into Overview (nutrition + charts) and Goals (goal management) tabs
- Goal system: `GoalsData` holding one `BodyWeightGoal?` + N `StrengthGoal`s (one per exercise) with TDEE-based macro computation
- Per-goal add/edit/delete with confirmation dialogs
- Strength trend chart (fl_chart `LineChart` with per-exercise curves + period selector) with per-goal progress bars
- Bodyweight trend chart (placeholder implementation)
- Exercise tab: Seances/Exercises/Current Seance tabs (3 static tabs), user can navigate while seance runs
- Stop/cancel seance buttons in AppBar (all tabs) and CurrentSeanceScreen
- UI polish: Diet Add/Edit Ingredient screen title, Dashboard tabs, Exercise seance flow redesign (inline template cards, popup menus, cleaner creation flow)

**Next up:** T09 — Drift persistence (deferred; all current functionality works with in-memory data).

# FitFat — Architecture

## App Shell (T01)

The app uses a single-activity, multi-tab structure built with GoRouter's `StatefulShellRoute.indexedStack`.

### Navigation

```
MaterialApp.router
 └─ GoRouter
     └─ StatefulShellRoute.indexedStack
         ├─ StatefulShellBranch: /dashboard  → DashboardTab
         ├─ StatefulShellBranch: /exercise   → ExerciseTab
         ├─ StatefulShellBranch: /diet       → DietTab
         └─ StatefulShellBranch: /settings   → SettingsTab
```

Bottom navigation uses Material 3 `NavigationBar`. Tab state is preserved when switching via `indexedStack`.

### Theme

- Material 3 with teal seed color
- Light theme only (dark mode out of scope)
- Defined in `lib/src/app/theme.dart`

### Key files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/src/app/app.dart` | `MaterialApp.router` widget |
| `lib/src/app/router.dart` | GoRouter config + `_ShellWithNavBar` |
| `lib/src/app/theme.dart` | Theme definition |
| `lib/src/app/tabs/*.dart` | Placeholder tab screens |

### GoRouter shell behavior

Each tab branch is a `StatefulShellBranch`. Tapping the same tab again resets it to its initial location. The `_ShellWithNavBar` widget renders the `NavigationBar` and delegates body rendering to `StatefulNavigationShell`.

---

## Database (T02)

Local SQLite database managed by [Drift](https://drift.simonbinder.eu/).

### Schema overview

```
ingredients ──┐
               ├── meal_ingredients ── meals
exercises  ──┐
              ├── workout_exercises ── workouts
              │         └── exercise_sets
              └── (direct FK to workout_exercises)
```

7 tables total. See [database/schema.md](database/schema.md) for full column definitions.

### Key file locations

| File | Purpose |
|------|---------|
| `lib/src/database/app_database.dart` | `AppDatabase` class, connection setup |
| `lib/src/database/tables.dart` | Drift table definitions with `@DataClass` |
| `lib/src/database/tables.g.dart` | Generated row classes, companions, table infos |
| `lib/src/database/app_database.g.dart` | Generated database class |

### Domain models

Separate plain Dart classes in `lib/src/models/` mirror the database rows. Repositories convert between Drift-generated rows and domain models.

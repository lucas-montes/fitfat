# Architecture

## Layer diagram

```mermaid
flowchart TD
    UI["UI Layer<br/>Screens & Widgets"]
    State["State Layer<br/>Riverpod Providers (streams)"]
    DB["Data Layer<br/>Drift (SQLite)"]
    Models["Domain Models<br/>Dart classes"]
    Router["Navigation Layer<br/>go_router"]

    UI --> State
    State --> DB
    DB --> Models
    UI --> Router
```

## Folder structure

```
lib/
├── main.dart                        # Entry point, ProviderScope, FlutterForegroundTask init
└── src/
    ├── app.dart                     # FitFatApp (MaterialApp.router)
    ├── app_theme.dart               # Material 3 theme (light/dark)
    ├── router/
    │   └── app_router.dart          # GoRouter route definitions (StatefulShellRoute)
    ├── screens/
    │   ├── diet/                    # Diet tab shell + top TabBar
    │   ├── food/                    # Meals tab UI (MealsTab, AddMealScreen, CustomIngredientScreen, FoodEntryCard)
    │   ├── exercise/                # Exercise tab (ExercisesTab, SeancesTab, CurrentSeanceScreen, SeanceLibraryScreen, CreateSeanceScreen)
    │   └── dashboard/               # Progress dashboard tab (DailyNutritionCard, GoalsCard, StrengthTrendChart, BodyweightTrendChart)
    ├── database/
    │   ├── app_database.dart        # AppDatabase — Drift DB class with all query methods + seed data
    │   ├── app_database.g.dart      # Generated Drift code
    │   └── tables.dart              # All 13 Drift table definitions
    ├── providers/                   # Riverpod providers (migrating to DB-backed)
    │   ├── database_providers.dart  # databaseProvider (singleton AppDatabase)
    │   ├── food_providers.dart      # IngredientListNotifier, MealLogNotifier
    │   ├── exercise_providers.dart  # ActiveSeanceNotifier, SeanceHistoryNotifier
    │   ├── seance_providers.dart    # TemplateListNotifier, ActiveSeancePlanNotifier
    │   └── dashboard_providers.dart # GoalNotifier (Goal?), userProfileProvider, computedMacrosProvider (TDEE), legacyNutritionGoalProvider, chart period, nutrition/daily/monthly, seed data
    ├── models/                      # Domain model classes
    │   ├── food_models.dart         # MacroNutrients, Ingredient, IngredientPortion, MealEntry
    │   ├── exercise_models.dart     # ExerciseDefinition, ExerciseSet, ExerciseEntry, Seance
    │   ├── seance_models.dart       # ExerciseTemplate, SeanceTemplate, ExerciseHistoryItem
    │   └── dashboard_models.dart    # Goal (sealed), UserProfile, Sex, ActivityLevel, BodyWeightDirection, ComputedMacros, NutritionGoal (legacy), StrengthDataPoint, WeightDataPoint, ChartPeriod
    ├── services/
    │   ├── seance_foreground_service.dart   # FlutterForegroundTask wrapper for background timer
    │   └── seance_notification_service.dart  # Notification helpers
    ├── repositories/
    │   ├── seance_repository.dart           # Abstract SeanceRepository port
    │   └── in_memory_seance_repository.dart # In-memory implementation
    └── widgets/
        └── appbar_seance_indicator.dart     # AppBar action for active seance timer
```

## Routing

GoRouter with 3 top-level routes via StatefulShellRoute:
- `/diet` — `DietScreen` (Meals/Ingredients tabs; contextual add action in the `AppBar` switches between add meal and add ingredient)
- `/exercise` — `ExerciseScreen` (Exercises/Seances tabs; shows `CurrentSeanceScreen` when a seance is active)
- `/dashboard` — `DashboardScreen`

Default route: `/dashboard`. Bottom nav order: Diet / Dashboard / Exercise.

## State management

Riverpod (no codegen). Providers written manually.
Phase 1 (complete) used `Provider<T>` returning mock data.
Phase 2 (in progress) migrates to `StreamProvider` backed by Drift SQLite database.

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^3.3.1 | State management |
| go_router | ^17.2.3 | Declarative routing |
| intl | ^0.20.2 | Date/number formatting |
| fl_chart | ^1.2.0 | Charts (strength trend line chart, dashboard) |
| uuid | ^4.5.3 | Unique ID generation |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| flutter_foreground_task | ^9.2.2 | Background timer via foreground service (Android + iOS) |
| flutter_local_notifications | ^18.0.0 | Local notifications for seance updates |
| shared_preferences | ^2.5.5 | Key-value persistence (active seance) |
| drift | ^2.20.0 | SQLite ORM — local database |
| sqlite3_flutter_libs | ^0.5.0 | Native SQLite libraries |
| sqlite3 | ^2.4.0 | Dart SQLite bindings |
| path_provider | ^2.0.0 | File system paths for DB file |
| path | ^1.8.0 | Path manipulation |
| drift_dev | ^2.20.0 | Drift code generator (dev) |
| build_runner | ^2.4.0 | Codegen runner (dev) |

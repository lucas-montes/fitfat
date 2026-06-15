# Context Map

## Core files
- `README.md`: current high-level architecture diagram.
- `lib/main.dart`: app bootstrap, logging, and foreground task callback.
- `lib/src/app/router.dart`: route graph and bottom navigation shell.
- `context/ui/navigation.md`: bottom navigation localization notes (navDiet, navDashboard, navExercise)
- `lib/src/app/main.dart`: `MaterialApp.router` wrapper and theme wiring.

## Data and persistence
- `lib/src/database/tables.dart`: Drift schema for ingredients, meals, seances, templates, goals, and profile.
- `lib/src/database/providers.dart`: production and dev database providers.
- `lib/src/adapters/drift/`: database-backed repositories/adapters.
- `lib/src/adapters/drift/planned_workout_repository.dart`: `DriftPlannedWorkoutRepository` — CRUD + load-by-week + mark-completed for planned workouts. Exposed via `plannedWorkoutRepositoryProvider`.
- `lib/src/adapters/drift/seance.dart`: `DriftSeanceRepository` — template CRUD. Exposed via `seanceRepositoryProvider`.

## Domain models
- `lib/src/models/enums.dart`: shared enums (`Gender`, with `GenderLabel` extension).
- `context/exercise/seance-persistence.md`: seance save/load flow — DB schema, domain model hierarchy, save transaction, load queries, SharedPreferences for active seance, race condition guard.
- `context/exercise/workout-model.md`: new unified workout model — DB schema for all new tables plus domain model hierarchy and serialization.
- `lib/src/models/workout.dart`: new domain model classes — `Workout`, `WorkoutEntry`, `WeightSet`, `CardioDetail`, `PlannedWorkout`, `PlannedEntry`, `PlannedCardio` with `toJson`/`fromJson`.
- `lib/src/models/exercise.dart`: exercise definitions (also `type` + `met` fields), entries, sets, and active seance model.
- `lib/src/models/dashboard.dart`: user profile, goals, computed macros, chart periods.
- `lib/src/models/seance.dart`: workout templates and history data structures.
- `lib/src/exercise/services/seance_converter.dart`: migration adapter — converts old `Seance` → new `Workout` domain model (pure Dart, no DB).
- `lib/src/database/migrations/migrate_seances.dart`: Drift data migration — reads old tables (seances, exercise_entries, exercise_sets) and writes to new tables (workouts, workout_entries, workout_sets, cardio_details). Runs once on schema v11 upgrade.
- `lib/src/models/food.dart`: ingredients, meal entries, and macro calculations.

## Feature modules
- `lib/src/diet/`: meal log, ingredient editor (with advanced macros section), ingredient management (archive/restore), and related providers.
- `lib/src/dashboard/`: focused daily glance (calories, workout status, goals, streaks), Goals sub-tab, Settings sub-tab (profile, nutrition toggles, data export/delete).
- `lib/src/dashboard/screens/status_cards.dart`: shared compact card shell (`_StatusCard`) and 7-day mini bar chart (`_MiniBarChart`) for water/steps/weight cards.
- `lib/src/exercise/`: active workout flow (mixed weightlifting + cardio), Training tab (replace old Workouts tab), exercise history, templates, workout library (with search + category filters), training stats, heatmap, and trend charts.
- `lib/src/exercise/screens/training/`: Training tab widgets — `TrainingTab`, `StartWorkoutCard`, `CalendarStrip`, `WorkoutHistoryCard`, `QuickLogSheet`, `DayDetailSheet`, `CreatePlannedScreen`. See [context/exercise/training-tab.md](exercise/training-tab.md), [context/exercise/quick-log.md](exercise/quick-log.md), and [context/exercise/planned-workout-scheduling.md](exercise/planned-workout-scheduling.md).
- `lib/src/exercise/screens/stats/`: Stats tab — `StatsTab` with all-time stats, this-week stats, heatmap, cardio-by-week, and volume-by-exercise. Reads from `workoutHistoryProvider`. See [context/exercise/stats-tab.md](exercise/stats-tab.md).
- `lib/src/exercise/screens/seances/active/`: Active workout screen (`CurrentSeanceScreen`) with mixed entry types — weightlifting sets and cardio duration. See [context/exercise/active-workout-screen.md](exercise/active-workout-screen.md).
- `lib/src/exercise/providers/workout_provider.dart`: `ActiveWorkoutNotifier` — new model workout provider supporting weightlifting + cardio + quick-log + planned workout start.
- `lib/src/exercise/providers/history_provider.dart`: `WorkoutHistoryNotifier` — loads completed workouts from new tables, date-range filtering, aggregate stats (volume by exercise, cardio minutes by week).
- `lib/src/exercise/providers/planned_workout_provider.dart`: `PlannedWorkoutNotifier` — CRUD for planned workouts, create-from-template, load-by-week for calendar view, mark-completed linking.
- `lib/src/exercise/services/workout_services.dart`: pure Dart service classes — `WorkoutSessionService`, `ExerciseLibraryService`, `ProgressionService`. `ProgressionService` supports both old `ExerciseSet` and new `domain.WeightSet` for 1RM, volume, and PR calculations.
- `lib/src/app/theme.dart`: Material 3 theme with custom typography, card shapes, input decoration, and button styles.

## Product decisions
- The app is single-user and offline-first.
- Training and nutrition are equally important.
- User-facing terminology uses `workout` (not `seance`). Internal class/variable names retain `Seance` for backward compatibility.
- Settings live in the Dashboard tab as a sub-tab (Profile, Nutrition, Workout, Appearance, Data).
- Dashboard is a focused daily glance: calories/macros first, then workout status, goals, weight (conditional), and 7-day streaks.
- Exercise tab contains training stats, heatmap, and trend charts (moved from dashboard).
- Refactors should prioritize readability, testability, and bug reduction.

## Diet-specific notes
- Ingredients will track a `creator` (who added them) and an `isArchived`/hidden flag instead of immediate deletion.
- Support two ingredient kinds: atomic (single food items) and composite (recipes made from other ingredients). Composite ingredients are local by default and need not be shared.
- Ingredients should store a broad set of macros (sodium, fiber, sugars, saturated fat, cholesterol, etc.). The UI will show only the user-selected relevant macros.
- Meal list: month view with infinite scroll loading older meals as the user scrolls.
- Meals are grouped by day and show daily totals; detailed progress and graphs live on the dashboard (optionally a diet graphs tab can be added later).
- There will be a shared/common ingredient database concept for supermarket ingredients (design pending — likely optional download/sync while keeping app offline-first).
- User-selectable macro visibility is preferred; the initial visible set can stay small and user-configurable.
- `creatorId` should not depend on a brittle hardware identifier; use a local installation UUID or a future user/profile id for attribution.

## Localization
- **ARB-based generated localization** via `flutter gen-l10n`.
- `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` — string definitions.
- `lib/l10n/app_localizations.dart` — generated `AppLocalizations` class (do not edit).
- Configured via `l10n.yaml` at project root.
- Also uses `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations` delegates.
- The old manual `lib/src/l10n/app_localizations.dart` will be removed once all strings are migrated.

## Diet preferences
- `lib/src/diet/providers/diet_preferences.dart`: `dietPreferencesProvider` and `DietPreferencesNotifier` — persisted macro visibility toggles backed by `SharedPreferences`.

## Active plans
- `context/plans/exercise-domain-rethink.md`: unified activity model (weightlifting + cardio + quick-log), workout planning, Training tab replacing Workouts tab. Phase D–E — T10–T13 done. ✅ T01–T13 done
- `context/plans/profile-gender-uuid-fix.md`: extract shared Gender enum, rename sex→gender column, derive weight from BodyWeightEntries, use UUID v7 for profile ID. ✅ Done
- `context/plans/exercise-workout-fixes.md`: fix compile errors, make Seance.name non-nullable, add completedAt to ExerciseSets, fix race condition in history save, make Seances.completedAt non-nullable. ✅ Done
- `context/plans/exercise-screens-refactor.md`: split exercise screens into subdirectories (exercises/, seances/, stats/). ✅ Done
- `context/plans/i18n-arb-migration.md`: migrate from manual `_t()` localization to Flutter standard ARB-based generated localization across all 10 source files.
- `context/plans/dashboard-step-water-ingredient.md`: auto step tracking via pedometer, improved water card UX (tap/double-tap/long-press), structured ingredient macro chip layout. ✅ Done

## Supporting docs
- `doc/simple_db_example.md`: example database context.
- `doc/riverpod_crud_example.md`: example Riverpod CRUD pattern.

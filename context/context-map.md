# Context Map

## Plans

| File | Description |
|------|-------------|
| [plans/exercise-module-rewrite.md](plans/exercise-module-rewrite.md) | Completed rewrite plan: unified Workout model, DB schema, tasks T01-T09 |
| [plans/exercise-module-fixes.md](plans/exercise-module-fixes.md) | Completed fixes plan: foreground service, dashboard volume, exercise history |
| [plans/training-tab-redesign.md](plans/training-tab-redesign.md) | Active: redesign Training tab with three-section layout and active workout screen |
| [plans/exercise-module-refactor.md](plans/exercise-module-refactor.md) | Active: three-layer refactoring (interface, services, providers, widget extraction) |

## Architecture & overview

| File | Description |
|------|-------------|
| [overview.md](overview.md) | Project overview, domain modules, active work |
| [architecture.md](architecture.md) | Exercise module architecture: Workout model, DB tables, lifecycle |
| [glossary.md](glossary.md) | Terminology and definitions |

## Source code mapping

| Source path | Context |
|-------------|---------|
| `lib/src/models/workout.dart` | All core models: Workout, WeightSet, CardioSet, ExerciseDefinition, enums |
| `lib/src/database/tables.dart` | Drift table definitions (13 tables) |
| `lib/src/database/app_database.dart` | DB singleton, schema v12, migrations v1-v12, CRUD helpers |
| `lib/src/adapters/drift/workout_repository.dart` | DriftWorkoutRepository implements WorkoutRepository — CRUD for Workout, WeightSet, CardioSet |
| `lib/src/adapters/interfaces/workout_repository.dart` | WorkoutRepository interface — abstract contract for workout data access |
| `lib/src/adapters/drift/goals.dart` | DriftGoalRepository |
| `lib/src/adapters/drift/ingredient_repository.dart` | DriftIngredientRepository |
| `lib/src/adapters/drift/meals.dart` | DriftMealRepository |
| `lib/src/adapters/drift/profile.dart` | DriftProfileRepository |
| `lib/src/exercise/providers/exercises.dart` | ExerciseListNotifier — loads exercise library from DB |
| `lib/src/exercise/providers/rest_timer.dart` | RestTimerNotifier — rest countdown timer |
| `lib/src/exercise/providers/active_workout.dart` | ActiveWorkoutNotifier — current workout, DB-only persistence |
| `lib/src/exercise/providers/workout_list.dart` | WorkoutListNotifier — scheduled/upcoming workouts |
| `lib/src/exercise/providers/workout_history.dart` | WorkoutHistoryNotifier — completed workouts |
| `lib/src/exercise/providers/exercise_history.dart` | ExerciseHistoryData, exerciseHistoryProvider — per-exercise history with WeightSets |
| `lib/src/exercise/providers/exercise_detail.dart` | ExerciseDetailNotifier, exerciseDetailProvider — per-(workout,exercise) state for set management, rest timer, exercise navigation |
| `lib/src/exercise/services/workout_services.dart` | WorkoutSessionService, ExerciseLibraryService, ProgressionService — pure Dart |
| `lib/src/exercise/services/set_management_service.dart` | SetManagementService — loadSets, deriveExerciseIds, add/toggle/delete sets |
| `lib/src/exercise/services/workout_lifecycle_service.dart` | WorkoutLifecycleService — resume, startFreeform, startScheduled, complete, cancel |
| `lib/src/exercise/services/providers.dart` | Riverpod providers for all 5 services |
| `lib/src/exercise/screens/main.dart` | Tab bar entry point (Training/Exercises/Stats) |
| `lib/src/exercise/screens/workout/list.dart` | WorkoutListTab — three-section layout: today's workout card (TodayCard), upcoming carousel (UpcomingCard), and history list (HistoryItem) |
| `lib/src/exercise/screens/workout/active_screen.dart` | ActiveWorkoutScreen — full-screen active workout with elapsed timer, exercise list grouped from sets (ExerciseGroupInfo), Add Exercise, Complete/Cancel |
| `lib/src/exercise/screens/workout/add_exercise_sheet.dart` | AddExerciseSheet — searchable bottom sheet for picking exercises from the library |
| `lib/src/exercise/screens/workout/exercise_detail_screen.dart` | ExerciseWorkoutDetailScreen — per-exercise set management via ExerciseDetailNotifier; widgets: WeightSetTile, CardioSetTile, RestElapsedCard, ExerciseSetForm |
| `lib/src/exercise/screens/workout/workout_summary_screen.dart` | WorkoutSummaryScreen — post-workout summary with duration, exercise summaries (ExerciseSummary), stat cards (StatCard); "Done" returns to Training tab |
| `lib/src/exercise/screens/workout/workout_history_detail_screen.dart` | WorkoutHistoryDetailScreen — read-only view of a completed workout's exercises and sets, navigated from history list |
| `lib/src/exercise/screens/workout/widgets/` | Shared workout widgets: WeightSetTile, CardioSetTile, RestElapsedCard, ExerciseSetForm, ElapsedTimerWidget, ExerciseGroupInfo, TodayCard, UpcomingCard, HistoryItem, StatCard, ExerciseSummary |
| `lib/src/exercise/screens/exercises/list.dart` | ExercisesListTab — exercise library with search |
| `lib/src/exercise/screens/exercises/history/` | Exercise history: screen, summary, record cards |
| `lib/src/exercise/screens/stats/stats_tab.dart` | StatsTab — all-time stats, weekly stats, 84-day heatmap |
| `lib/src/widgets/appbar_seance_indicator.dart` | SeanceFloatingPill — floating timer pill for active workouts |
| `lib/src/dashboard/providers/dashboard.dart` | WorkoutDaySummary, WorkoutDashboardStats providers |

## Tests

| Path | Description |
|------|-------------|
| `test/src/exercise/models/workout_test.dart` | 38 tests — Workout states/duration/copyWith, WeightSet/CardioSet/ExerciseDefinition |
| `test/src/exercise/services/workout_services_test.dart` | 24 tests — WorkoutSessionService, ExerciseLibraryService, ProgressionService |

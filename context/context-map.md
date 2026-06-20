# Context Map

## Plans

| File | Description |
|------|-------------|
| [plans/exercise-module-rewrite.md](plans/exercise-module-rewrite.md) | Completed rewrite plan: unified Workout model, DB schema, tasks T01-T09 |
| [plans/exercise-module-fixes.md](plans/exercise-module-fixes.md) | Completed fixes plan: foreground service, dashboard volume, exercise history |
| [plans/training-tab-redesign.md](plans/training-tab-redesign.md) | Active: redesign Training tab with three-section layout and active workout screen |

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
| `lib/src/adapters/drift/workout_repository.dart` | DriftWorkoutRepository — CRUD for Workout, WeightSet, CardioSet |
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
| `lib/src/exercise/services/workout_services.dart` | WorkoutSessionService, ExerciseLibraryService, ProgressionService — pure Dart |
| `lib/src/exercise/screens/main.dart` | Tab bar entry point (Training/Exercises/Stats) |
| `lib/src/exercise/screens/workout/list.dart` | WorkoutListTab — three-section layout: today's workout card, upcoming carousel, and history list |
| `lib/src/exercise/screens/workout/active_screen.dart` | ActiveWorkoutScreen — full-screen active workout with elapsed timer, exercise list grouped from sets, Add Exercise, Complete/Cancel |
| `lib/src/exercise/screens/workout/add_exercise_sheet.dart` | AddExerciseSheet — searchable bottom sheet for picking exercises from the library |
| `lib/src/exercise/screens/workout/exercise_detail_screen.dart` | ExerciseWorkoutDetailScreen — per-exercise set management within active workout |
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

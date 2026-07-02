# Workout CRUD — Exercise Domain

Feature: create, read, update, and delete workouts. Supports a pending→active→completed workflow and logging actual set data.

## Files

| File | Purpose |
|------|---------|
| `lib/src/exercise/repositories/workout_repository.dart` | Drift DAO for `workouts` + `workout_exercises` + `exercise_sets` tables |
| `lib/src/exercise/providers/workouts.dart` | Riverpod providers (`workoutRepositoryProvider`, `workoutListProvider`, `workoutDetailProvider`) |
| `lib/src/exercise/screens/workout_list.dart` | ListView with status badges (Pending/Active/Completed), swipe-to-delete |
| `lib/src/exercise/screens/workout_form.dart` | Name, date picker, exercise multi-select with editable planned sets (reps/weight or duration) |
| `lib/src/exercise/screens/workout_detail.dart` | Exercises with sets, log actual values per set via dialog, Start/Complete buttons |

## Key behavior

- **Repository**: Transactional insert/delete across 3 tables. Loads full workout tree via batched queries. Supports `start()` (sets `startedAt`) and `complete()` (sets `completedAt`).
- **Rich result types**: `WorkoutWithDetails` (workout + `List<ExerciseBlock>`), `ExerciseBlock` (workout_exercise + `List<ExerciseSet>`).
- **Form**: Multi-select exercises with 3 default planned sets each. Adjustable per exercise (reps/kg for weightlifting, minutes for cardio). Uses `newWorkout()`, `newWorkoutExercise()`, `newPlannedSet()` factory helpers.
- **List screen**: Shows date + status badge. Exercise definitions accessible via AppBar action.
- **Detail screen**: Header card with status/date/duration. Exercise `ExpansionTile` showing set rows. Planned values shown strikethrough when actuals logged. Tappable rows open dialog to log actuals. Start/Complete buttons in AppBar.

## Workflow

```
Pending (startedAt=null) → Start → Active (startedAt=set) → Complete → Completed (completedAt=set)
```

## Wiring

The Exercise tab (`lib/src/app/tabs/exercise_tab.dart`) renders `WorkoutListScreen`. Exercise definitions are accessible via the AppBar action (`fitness_center` icon) which pushes `ExerciseListScreen`.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [database/schema.md](../database/schema.md), [exercise-crud.md](exercise-crud.md)

# Active Workout Screen

The active workout screen (`CurrentSeanceScreen`) is the full-screen session view accessible via `/current-seance` route. Defined in `lib/src/exercise/screens/seances/active/screen.dart`.

## Mixed activity type support

Supports two activity types side-by-side in the same workout:

### Weightlifting entries
- Added via `ActiveWorkoutNotifier.addExercise()`
- Detail view shows `AddSetForm` (reps + weight fields) and list of set cards
- Set cards (`GuidedSetCard` / `FreeformSetCard`) display each set with reps × weight, completion status, and optional PR trophy
- Rest timer (`RestTimerOverlay`) appears after completing a set during guided workouts — defaults to 60s

### Cardio entries
- Added via `ActiveWorkoutNotifier.addCardioEntry(exercise)` 
- Exercise type `'cardio'` is detected from `ExerciseDefinition.type`
- Detail view shows a duration text field + "Set Duration" button
- Calls `ActiveWorkoutNotifier.setCardioDuration(index, minutes)` to save
- Shows a confirmation card with the logged duration

## Exercise picker

- Search-based picker shows both weightlifting and cardio exercises
- Each result shows: type-specific icon (dumbbell / running figure), category, and a colored type badge
- Tapping a weightlifting exercise calls `addExercise()`; tapping a cardio exercise calls `addCardioEntry()`

## Provider

Uses `activeWorkoutProvider` (`ActiveWorkoutNotifier` from `workout_provider.dart`) — the new unified model with `domain.Workout`, `domain.WorkoutEntry`, `domain.WeightSet`, `domain.CardioDetail`.

See also: [workout-model.md](workout-model.md), [training-tab.md](training-tab.md), [context-map.md](../context-map.md)

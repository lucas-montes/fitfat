# Training Tab

Replaces the old `SeancesHistoryTab` as the primary Exercise tab. Defined in `lib/src/exercise/screens/training/`.

## Layout (top to bottom)

1. **StartWorkoutCard** — `lib/src/exercise/screens/training/start_workout_card.dart`
   - If active workout exists: shows running card with workout name, entry count, "View" and "Stop" buttons.
   - Otherwise: shows title + action button ("Follow today's plan" if planned workouts exist, "Start workout" otherwise) and a "Quick Log" pill button (placeholder snackbar until T12).

2. **CalendarStrip** — `lib/src/exercise/screens/training/calendar_strip.dart`
   - Swipeable `PageView.builder` showing 7-day weeks anchored to a reference Monday.
   - Day labels (Mon–Sun), selected-day highlight, dot indicators for days with planned workouts.

3. **Timeline** — Inline in `tab.dart`
   - Shows today's planned (non-completed) workouts with source-specific leading icons via `_plannedSourceIcon()`:
     - `coach` → `Icons.school` (indigo)
     - `from_template` → `Icons.description`
     - default → `Icons.schedule`
   - Shows today's completed workouts via `WorkoutHistoryCard` (includes a source-indicator icon in the header row via `_sourceIcon()`).
   - Falls back to "No workouts today" if both lists are empty.

4. **History** — Inline in `tab.dart`
   - Lists all past completed workouts via `WorkoutHistoryCard`.

## Providers consumed

- `activeWorkoutProvider` (`workout_provider.dart`) — active session state
- `plannedWorkoutProvider` (`planned_workout_provider.dart`) — planned workouts by week
- `workoutHistoryProvider` (`history_provider.dart`) — completed workout history

See also: [workout-model.md](workout-model.md), [context-map.md](../context-map.md)

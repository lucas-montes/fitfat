# Quick Log

One-tap workout logging accessible from the Training tab's `StartWorkoutCard` "Quick Log" button.

## Flow

1. User taps "Quick Log" → `showModalBottomSheet(QuickLogSheet)` opens
2. User searches/selects an exercise from the `exerciseListProvider`
3. Exercise type determines the input fields shown:
   - **Weightlifting** → reps + weight (kg) fields
   - **Cardio** → duration (minutes) field
4. Optional notes field
5. "Log Workout" button calls `ActiveWorkoutNotifier.quickLogWorkout()` — saves immediately with `source = 'quick_log'` and `endTime = startTime`
6. `workoutHistoryProvider.loadHistory()` refreshes the timeline
7. Snackbar confirms, sheet closes

## Widget

- `lib/src/exercise/screens/training/quick_log_sheet.dart` — `ConsumerStatefulWidget` bottom sheet
- Trigger: `lib/src/exercise/screens/training/start_workout_card.dart` line ~148

## Provider integration

Uses `activeWorkoutProvider.notifier.quickLogWorkout()` (defined in `workout_provider.dart`) and `workoutHistoryProvider.notifier.loadHistory()` for timeline refresh.

See also: [training-tab.md](training-tab.md), [workout-model.md](workout-model.md), [context-map.md](../context-map.md)

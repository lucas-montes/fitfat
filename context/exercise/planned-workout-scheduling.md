# Planned Workout Scheduling UI

Accessed by tapping a day on the Training tab's calendar strip. Defined in `lib/src/exercise/screens/training/`.

## Flow

Tap day → `DayDetailSheet` bottom sheet (`day_detail_sheet.dart`) shows:
- **If planned workout exists**: name, source-attribution chip (via `_sourceChip()`) for `coach` (`Icons.school`, "From coach") or `from_template` (`Icons.description`, "From template"), entry count, Start / Edit / Delete buttons
- **If empty**: "Add planned workout" CTA

**Start** → calls `ActiveWorkoutNotifier.startWorkoutFromPlanned(plan)` → navigates to `/current-seance` with pre-filled weights.

**Edit** → pushes `CreatePlannedScreen` in edit mode (`create_planned_screen.dart`) — full-screen form:
- Name field, date picker, exercise list with prescribed reps/weight (or cardio duration)
- "Copy from template" button → `SimpleDialog` picking from `templateListProvider` → pre-fills via `PlannedWorkoutNotifier.createFromTemplate()`
- Save calls `updatePlannedWorkout()` or `createPlannedWorkout()`

**Delete** → confirmation dialog → `PlannedWorkoutNotifier.deletePlannedWorkout()`

## Providers used
- `plannedWorkoutProvider` — CRUD: create, update, delete, loadByWeek, createFromTemplate
- `templateListProvider` — reads existing templates for copy flow
- `activeWorkoutProvider` — startWorkoutFromPlanned

See also: [training-tab.md](training-tab.md), [quick-log.md](quick-log.md), [context-map.md](../context-map.md)

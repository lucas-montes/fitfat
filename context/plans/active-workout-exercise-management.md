# Plan: Active workout exercise and set management

## Change Summary

Upgrade `ActiveWorkoutScreen` from a minimal timer display to a full workout-management screen where users can see selected exercises, add new exercises from the library, and manage sets (add, complete, edit, delete) via a dedicated exercise detail view.

## Mockup

```
┌─────────────────────────────────────┐
│  ← Workout Name         00:12:34    │  ← AppBar with name + live timer
├─────────────────────────────────────┤
│  Exercises (3)                      │
│  ┌─────────────────────────────────┐│
│  │ 💪 Bench Press         3 sets  ▸││  ← Tap → detail view
│  │ 🏃 Treadmill           1 set   ▸││
│  │ 💪 Squat               2 sets  ▸││
│  └─────────────────────────────────┘│
│  [+ Add Exercise]                   │  ← Opens bottom sheet picker
│                                     │
│  [        Complete Workout       ]  │
│  [        Cancel Workout         ]  │
└─────────────────────────────────────┘

Exercise Detail View (pushed on top):
┌─────────────────────────────────────┐
│  ← Bench Press                      │
├─────────────────────────────────────┤
│  Set 1: 10 × 80 kg      ✅ Done    │  ← Tap to toggle complete
│  Set 2:  8 × 85 kg      ⏳ Pending │  ← Long-press → edit/delete
│  Set 3:  6 × 90 kg      ⏳ Pending │
│                                     │
│  [+ Add Set]                        │  ← Opens inline add-set form
└─────────────────────────────────────┘

Add Exercise Sheet (bottom sheet):
┌─────────────────────────────────────┐
│  🔍 Search exercises...             │
│  ─────────────────────────────────  │
│  💪 Bench Press                   ▸ │  ← Tap → exercise detail view
│  💪 Squat                         ▸ │      (user adds sets there)
│  💪 Deadlift                      ▸ │
│  🏃 Treadmill                     ▸ │
│  ...                                │
└─────────────────────────────────────┘
```

## Success Criteria

- Active workout screen shows a list of exercises that have sets in the current workout
- Each exercise row shows name, type icon, set count; tap opens detail view
- "Add Exercise" button/fab opens a bottom sheet with searchable exercise library
- Tapping an exercise in the sheet adds a default set (1 set, planned = default values) and returns to active screen
- Exercise detail view shows all sets for that exercise in the current workout
- Tap a set to toggle completed/not-completed
- Long-press a set shows a popup menu with Edit and Delete options
- Edit opens a dialog to modify reps/weight (weight sets) or duration (cardio sets)
- Delete removes the set and refreshes the list
- "Add Set" in detail view adds a new set with default values
- Existing timer, Complete, and Cancel still work
- `dart analyze lib/` — 0 errors
- `flutter test test/src/exercise/` — 62/62 pass

## Constraints and Non-Goals

- **In scope**: New screens and widgets for exercise/set management during an active workout; bottom sheet exercise picker; tap/long-press set interactions; inline edit dialog
- **Out of scope**: Rest timer functionality; exercise history during workout; reordering sets or exercises; swipe gestures for set actions; creating new exercises on the fly (library-only)
- **Architecture decisions**: No new GoRouter routes — `ExerciseWorkoutDetailScreen` is pushed as a regular `Navigator.push(MaterialPageRoute)`; bottom sheet uses `showModalBottomSheet`; sets are fetched via `DriftWorkoutRepository.getById()` called from a new provider or directly

## Task Stack

- [x] T01: `Create ExerciseWorkoutDetailScreen` (status:done)
  - Task ID: T01
  - Goal: Create a screen that shows all sets for a given exercise within the active workout. Supports tap-to-complete, long-press-for-menu (edit, delete), and add-set functionality.
  - Boundaries (in/out of scope): In — new screen at `lib/src/exercise/screens/workout/exercise_detail_screen.dart`; accepts `workoutId` and `exerciseId` as constructor params; reads exercise definition from `exerciseListProvider`; reads sets via repository; tap toggles `completedAt`; long-press shows popup with Edit (dialog for reps/weight/duration + notes) and Delete (confirms then removes); "Add Set" button opens a form for user to enter real values. Out — rest timer integration; set reordering; swipe gestures.
  - Done when: Exercise detail screen shows all sets for exercise; tap toggles completion; long-press shows edit/delete; edit dialog saves changes; delete removes set; "Add Set" form creates a new set; `dart analyze lib/` passes with no new errors.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-19
  - **Files changed:**
    - lib/src/exercise/screens/workout/exercise_detail_screen.dart (created)
    - lib/src/models/workout.dart (added `notes` field to WeightSet + CardioSet)
    - lib/src/database/tables.dart (added `notes` column to WeightSets + CardioSets)
    - lib/src/database/app_database.dart (bumped to v13, added migration)
    - lib/src/adapters/drift/workout_repository.dart (added `getCardioSets` public method; updated mappings for `notes`)
    - lib/src/exercise/providers/active_workout.dart (added `notes` param to addWeightSet + addCardioSet)
  - **Evidence:** `dart analyze lib/` — 0 errors (4 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

- [x] T02: `Create AddExerciseSheet` (status:done)
  - Task ID: T02
  - Goal: Create a bottom sheet that shows the exercise library with a search bar. Tapping an exercise navigates to ExerciseWorkoutDetailScreen for that exercise.
  - Boundaries (in/out of scope): In — new widget at `lib/src/exercise/screens/workout/add_exercise_sheet.dart`; searchable list from `exerciseListProvider`; tap returns selected exercise, caller navigates to detail screen. Out — creating exercises on the fly; auto-creating default sets; adding multiple sets at once.
  - Done when: Sheet opens from active workout screen; search filters exercises; tap navigates to ExerciseWorkoutDetailScreen for that exercise; sheet shows weightlifting and cardio exercises with correct icons; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-19
  - **Files changed:**
    - lib/src/exercise/screens/workout/add_exercise_sheet.dart (created)
    - lib/src/exercise/screens/workout/active_screen.dart (added temp "Add Exercise" button + sheet opener)
  - **Evidence:** `dart analyze lib/` — 0 errors (4 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

- [x] T03: `Rewrite ActiveWorkoutScreen with exercise list` (status:done)
  - Task ID: T03
  - Goal: Rewrite `ActiveWorkoutScreen` to show elapsed timer in the app bar, a scrollable list of exercises grouped from sets in the workout, an "Add Exercise" button, and Complete/Cancel buttons.
  - Boundaries (in/out of scope): In — changes to `lib/src/exercise/screens/workout/active_screen.dart`; fetch all sets for the workout via repository; group sets by `exerciseId`; look up exercise definitions from `exerciseListProvider`; each exercise row shows name, type icon, set count; tap navigates to `ExerciseWorkoutDetailScreen`; "Add Exercise" opens `AddExerciseSheet`; existing timer and Complete/Cancel preserved. Out — changing route structure; modifying the floating pill or notification behavior.
  - Done when: Active workout screen shows exercise list; each exercise row is tappable and navigates to detail view; "Add Exercise" opens bottom sheet; timer updates live; Complete/Cancel work; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors (2 pre-existing infos); `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-19
  - **Files changed:**
    - lib/src/exercise/screens/workout/active_screen.dart (rewritten — exercise list, timer in app bar, set fetching/grouping)
  - **Evidence:** `dart analyze lib/` — 0 errors (2 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

- [x] T04: `Validation and cleanup` (status:done)
  - Task ID: T04
  - Goal: Run full analysis, test suite, remove any scaffolding, sync context files.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, review for unused imports/variables, update context files. Out — fixing unrelated infra test failures.
  - Done when: All checks pass, no dead code, context files reflect new screens.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-19
  - **Evidence:** see Validation Report below.

## Validation Report

### Commands run
- `dart analyze lib/` → exit 0, **0 errors** (4 info-level: 2 pre-existing diet, 2 pre-existing active_screen)
- `dart format --set-exit-if-changed lib/src/exercise/screens/workout/` → exit 0, **0 files changed**
- `flutter test test/src/exercise/` → exit 0, **62/62 passed**

### Scaffolding cleanup
- No temporary scaffolding remaining. The T02 temp "Add Exercise" button was replaced by the proper T03 layout.
- No unused imports or dead code found in new/modified files.

### Context sync
- `context/overview.md`: Updated schema version v12→v13 (from T01)
- `context/context-map.md`: Added entries for `add_exercise_sheet.dart` and `exercise_detail_screen.dart`; updated `active_screen.dart` description
- All root files (overview, architecture, glossary) verified against code truth — accurate

### Success-criteria verification
- [x] Active workout screen shows exercise list grouped from sets → `active_screen.dart`
- [x] Each exercise row is tappable → navigates to `ExerciseWorkoutDetailScreen`
- [x] "Add Exercise" opens bottom sheet → `AddExerciseSheet`
- [x] Timer updates live → existing `Timer.periodic` preserved
- [x] Complete/Cancel work → preserved from original implementation
- [x] Exercise detail screen shows sets, tap-to-complete, long-press edit/delete, add-set → `exercise_detail_screen.dart`
- [x] Add exercise sheet has searchable library → `add_exercise_sheet.dart`
- [x] `dart analyze lib/` — 0 errors
- [x] `flutter test test/src/exercise/` — 62/62 pass

### Residual risks
- None identified within plan scope. Old/unrelated files (`lib/src/exercise/screens/seances/`, `lib/src/exercise/providers/workout_provider.dart`, `lib/src/exercise/providers/history_provider.dart`) contain pre-existing compilation errors from the old model — these predate this plan and are unrelated.

## Resolved Decisions

1. **Adding an exercise via sheet** → No default auto-created set. Tapping an exercise in the sheet navigates to `ExerciseWorkoutDetailScreen` where the user explicitly adds sets with real values.
2. **Edit dialog fields** → Weight sets: reps + weight + notes. Cardio sets: duration + notes. Rest time is auto-calculated (not editable).
3. **Completed set styling** → Green checkmark icon + slightly faded/opacity on the row.

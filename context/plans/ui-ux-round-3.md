# Plan: ui-ux-round-3

Follow-up UI/UX changes after template-sets-seance-guard.

---

## Changes

### C01: Dashboard tabs — too low (status:done)
Moved the `TabBar` from a `Column` after `AppBar` into `AppBar.bottom`, matching the Exercise tab style.

**Files**: `lib/src/screens/dashboard/dashboard_screen.dart`

### C02: Date input — can't type '/' (status:done)
No code change needed — date pickers already use `showDatePicker()`, not manual text input. The profile birthdate, bodyweight goal date, and strength goal date all use proper picker dialogs, not TextFields.

### C03: Template creation — add exercise without default sets, tap to edit (status:done)
- `_addExerciseFromPreset` / `_addCustomExercise` now add exercises with `plannedSets: []` (no defaults).
- `_ExerciseTile` shows exercise name with "No sets configured — tap to edit" subtitle.
- Tap or edit icon opens `_SetsEditorDialog` with per-set rows (reps, weight, rest per set).
- Rest time moved from `ExerciseTemplate` to `PlannedSet.restSeconds`, so each set has its own rest.
- `_SetRowControllers` / `_ExerciseSettingsCard` replaced with `_ExerciseTile` + `_SetsEditorDialog`.

**Files**: `lib/src/models/seance_models.dart`, `lib/src/screens/exercise/create_seance_screen.dart`

### C04: Current Seance — no exercise list, just search + remove (status:done)
- Removed the separate "Exercises" section at the top — only added exercises show (with remove button + chevron to enter detail view).
- Added `removeExercise(index)` method to `ActiveSeanceNotifier`.
- Search box at bottom to add new exercises.
- AppBar title uses `seance.name` if set, falls back to `'Active Seance'`.

**Files**: `lib/src/models/exercise_models.dart` (Seance.name), `lib/src/providers/exercise_providers.dart` (removeExercise), `lib/src/screens/exercise/exercise_screen.dart`

### C05: Validation (status:done)
- `flutter analyze` — No issues found
- `flutter test` — 6/6 passed

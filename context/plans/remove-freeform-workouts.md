# Remove Free-Form Workouts — Planned-Only Workout Mode

## Change Summary

Remove the ability to start free-form (unscheduled) workouts. All workouts must be
scheduled/planned ahead of time. Add a minimal UI to create scheduled workouts.
Reset the database schema to a clean slate (no migration chain).

## Success Criteria

- No UI entry point exists to start a blank/free-form workout
- `Workout.scheduledDate` is required (non-nullable)
- `isFreeform` / `isScheduled` getters and all branching logic removed from codebase
- Existing DB migrations deleted; schema version reset to 1 with `scheduledDate` NOT NULL
- Minimal "Schedule Workout" creation flow exists: name, date, exercise selection with planned sets
- `dart analyze lib/` — 0 errors
- All existing exercise tests pass (after model updates)

## Constraints and Non-Goals

- **In scope**: Remove free-form workout model branching, remove free-form UI/entry points,
  reset DB schema, add minimal scheduled workout creation UI
- **Out of scope**: Fancy workout creation UI (e.g. drag-and-drop ordering, templates,
  coach integration) — keep it minimal
- **Out of scope**: Editing/deleting scheduled workouts from the list
- **Assumptions**: Existing data loss is acceptable (DB reset). User understands that all
  workouts must now be scheduled.

## Task Stack

---

- [x] T01: `Reset database schema to clean slate (v1, no migrations)` (status:done)
  - Task ID: T01
  - Goal: Delete all migration code in `app_database.dart`; set `schemaVersion` to 1;
    use only `onCreate: createAll` with no `onUpgrade`. ScheduledDate nullability deferred
    to T02 (kept nullable in DB for now to avoid compile error between model and Drift companion).
  - Boundaries (in/out of scope):
    In — `app_database.dart` migration strategy
    Out — `tables.dart` (no table changes in T01), other DB tables
  - Done when:
    - `schemaVersion` is 1
    - `onUpgrade` is removed
    - `onCreate` calls `m.createAll()` + seed data
    - `dart analyze lib/` passes
  - Verification notes: `grep -n "schemaVersion" lib/src/database/app_database.dart`
    shows version 1; Drift build runner regenerates `.g.dart` without errors;
    `flutter pub run build_runner build` succeeds.
  - **Completed:** 2026-06-30
  - **Files changed:** lib/src/database/app_database.dart, lib/src/database/app_database.g.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos); build runner — 1 output (112 total) ; `schemaVersion` = 1, no `onUpgrade`

- [x] T02: `Simplify Workout model — make scheduledDate required, remove isFreeform` (status:done)
  - Task ID: T02
  - Goal: Make `scheduledDate` a required non-nullable `DateTime` on `Workout`.
    Remove `isFreeform` and `isScheduled` getters. Remove `clearScheduledDate` from
    `copyWith`. Update DB column to NOT NULL. Update repository mappings.
  - Boundaries (in/out of scope):
    In — `lib/src/models/workout.dart`, `lib/src/database/tables.dart`,
    `lib/src/adapters/drift/workout_repository.dart`, Drift `.g.dart` regeneration
    Out — WeightSet/CardioSet, providers, screens (updated in later tasks)
  - Done when:
    - `Workout.scheduledDate` is `DateTime` (not `DateTime?`)
    - `isFreeform` getter removed
    - `isScheduled` getter removed
    - `clearScheduledDate` removed from `copyWith`
    - `tables.dart` column is `dateTime()` (NOT NULL)
    - `dart analyze lib/src/models/workout.dart` — 0 errors
  - Verification notes: `dart analyze lib/src/models/workout.dart` — 0 errors;
    Drift build runner regenerates `.g.dart` with 2 outputs.
  - **Completed:** 2026-06-30
  - **Files changed:** lib/src/models/workout.dart, lib/src/database/tables.dart,
    lib/src/database/app_database.g.dart
  - **Evidence:** `dart analyze lib/src/models/workout.dart` — 0 issues;
    `dart analyze lib/` — 7 errors (all expected downstream, 0 in model/DB/repo);
    build runner — 2 drift outputs (scheduledDate NOT NULL change);

- [x] T03: `Remove startFreeform from service and provider layers` (status:done)
  - Task ID: T03
  - Goal: Remove `startFreeform()` method from `WorkoutLifecycleService` and
    `ActiveWorkoutNotifier`. Remove `_generateId()` from `WorkoutLifecycleService`
    (unused after startFreeform removal).
  - Boundaries (in/out of scope):
    In — `workout_lifecycle_service.dart`, `active_workout.dart`
    Out — UI changes, creating-scheduled-workout flow
  - Done when:
    - No `startFreeform` method exists in either file
    - `_generateId()` removed from `WorkoutLifecycleService`
    - `grep -rn "startFreeform" lib/src/` — only returns `list.dart:114` (T04 scope)
  - Verification notes: `grep -rn "startFreeform" lib/src/` returns only list.dart:114
  - **Completed:** 2026-06-30
  - **Files changed:** lib/src/exercise/services/workout_lifecycle_service.dart,
    lib/src/exercise/providers/active_workout.dart
  - **Evidence:** `dart analyze lib/` — 8 errors (all expected downstream, 0 in T03 scope);
    0 warnings in T03 scope; `grep "startFreeform"` — only list.dart:114 (T04);

- [x] T04: `Update TodayCard and WorkoutListTab — remove free-form start button` (status:done)
  - Task ID: T04
  - Goal: Remove `onStartFreeform` callback from `TodayCard` and `WorkoutListTab`.
    Remove the "Start Blank Workout" button from the card's else-branch.
    Simplify the `WorkoutListTab` to no longer split free-form workouts.
  - Boundaries (in/out of scope):
    In — `today_card.dart`, `list.dart`
    Out — l10n strings (removed in T08), Add Exercise changes
  - Done when:
    - `TodayCard` has no `onStartFreeform` parameter
    - `TodayCard` else branch shows only "no planned workouts" text (no button)
    - `WorkoutListTab` no longer calls `onStartFreeform`
    - `list.dart` filters simplified (no null checks on `scheduledDate`)
    - `dart analyze lib/` — 0 errors/warnings in T04 files
  - Verification notes: `grep -rn "onStartFreeform\|startFreeform\|startBlank" lib/src/exercise/screens/` returns no results
  - **Completed:** 2026-06-30
  - **Files changed:** lib/src/exercise/screens/workout/widgets/today_card.dart,
    lib/src/exercise/screens/workout/list.dart,
    lib/src/exercise/screens/workout/widgets/upcoming_card.dart
  - **Evidence:** `dart analyze lib/` — 7 errors remaining (0 in T04 scope, all in T05-T10);
    0 warnings (down from 6); 3 infos (pre-existing);

- [x] T05: `Remove FreeFormExerciseForm and simplify exercise detail screen` (status:done)
  - Task ID: T05
  - Goal: Delete `FreeFormExerciseForm` widget. Update `ExerciseWorkoutDetailScreen`
    to always use planned form behavior: sets are added with planned values only
    (never auto-completed), no "+" chip to add exercises mid-workout.
  - Boundaries (in/out of scope):
    In — `free_form_exercise_form.dart`, `exercise_detail_screen.dart`
    Out — `PlannedExerciseForm` (keep, rename if desired), `AddExerciseSheet` (keep for creation UI)
  - Done when:
    - `free_form_exercise_form.dart` file deleted
    - `_addSetFromForm` no longer checks `isFreeform` — always saves planned-only (no auto-complete)
    - `_buildExerciseChips` no longer shows "+" add-exercise chip
    - `_buildExerciseForm` always returns `PlannedExerciseForm`
    - `dart analyze lib/` passes
  - Verification notes:
    - File `lib/src/exercise/screens/workout/widgets/free_form_exercise_form.dart` no longer exists
    - `grep -rn "FreeFormExerciseForm\|isFreeform" lib/src/exercise/screens/workout/exercise_detail_screen.dart` returns no results
    - **Completed:** 2026-06-30
    - **Files changed:** lib/src/exercise/screens/workout/widgets/free_form_exercise_form.dart (deleted),
      lib/src/exercise/screens/workout/exercise_detail_screen.dart
    - **Evidence:** `dart analyze lib/` — 4 errors (all in T06/T07/T09 scope, 0 in T05);
      `grep` for FreeFormExerciseForm/isFreeform/_openAddExercise/add_exercise_sheet in
      exercise_detail_screen.dart — all clean; build runner — 30 outputs (2 drift) ✓

- [x] T06: `Remove Add Exercise button from ActiveWorkoutScreen` (status:done)
  - Task ID: T06
  - Goal: Remove the `if (workout.isFreeform)` block that renders the "Add Exercise"
    button from `ActiveWorkoutScreen`. Since all workouts are planned with fixed
    exercise lists, this button is unnecessary during an active workout.
  - Boundaries (in/out of scope):
    In — `active_screen.dart`
    Out — `AddExerciseSheet` widget (still used by creation UI)
  - Done when:
    - No "Add Exercise" button appears in `ActiveWorkoutScreen`
    - No reference to `isFreeform` or `workout.isFreeform` in `active_screen.dart`
    - `dart analyze lib/` passes
  - Verification notes: `grep -n "isFreeform\|addExercise\|Add Exercise" lib/src/exercise/screens/workout/active_screen.dart` returns no results
    - **Completed:** 2026-06-30
    - **Files changed:** lib/src/exercise/screens/workout/active_screen.dart
    - **Evidence:** `dart analyze lib/` — 3 errors (all in T07/T09, 0 in T06);
      `grep` for isFreeform/AddExercise/add_exercise_sheet in active_screen.dart — all clean ✓

- [x] T07: `Simplify WorkoutSummaryScreen — remove isFreeform branches` (status:done)
  - Task ID: T07
  - Goal: Remove the `isFreeform` conditional display logic in `WorkoutSummaryScreen`.
    Since all workouts now have planned values, always show the planned/actual
    comparison display (showing actual/planned volume, always showing sets as "X/Y sets").
  - Boundaries (in/out of scope):
    In — `workout_summary_screen.dart`
    Out — stat card widgets, ExerciseSummary model
  - Done when:
    - No `isFreeform` references in `workout_summary_screen.dart`
    - Summary display is consistent (planned/actual for all workouts)
    - `dart analyze lib/` passes
  - Verification notes: `grep -n "isFreeform" lib/src/exercise/screens/workout/workout_summary_screen.dart` returns no results
    - **Completed:** 2026-06-30
    - **Files changed:** lib/src/exercise/screens/workout/workout_summary_screen.dart
    - **Evidence:** `dart analyze lib/` — 1 error (T09 scope only, 0 in T07);
      `grep` for isFreeform in workout_summary_screen.dart — clean ✓

- [x] T08: `Remove freeformMode and startBlankSeance l10n entries` (status:done)
  - Task ID: T08
  - Goal: Remove `freeformMode` and `startBlankSeance` localizations from all locale
    files (en, fr, es) and the base `app_localizations.dart`.
  - Boundaries (in/out of scope):
    In — `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`,
    `app_localizations_es.dart`
    Out — other l10n strings, generated `.g.dart` files
  - Done when:
    - `startBlankSeance` getter removed from all locale files
    - `freeformMode` getter removed from all locale files
    - `dart analyze lib/` passes
  - Verification notes: `grep -rn "startBlankSeance\|freeformMode" lib/l10n/*.dart` returns no results
    - **Completed:** 2026-06-30
    - **Files changed:** lib/l10n/app_localizations.dart, app_localizations_en.dart,
      app_localizations_fr.dart, app_localizations_es.dart
    - **Evidence:** `dart analyze lib/` — 1 error (T09 scope only, 0 in T08);
      `grep` for `freeformMode`/`startBlankSeance` in `.dart` l10n files — clean ✓

- [x] T09: `Add minimal planned workout creation UI` (status:done)
  - Task ID: T09
  - Goal: Add a screen/flow to create a scheduled workout with exercises and planned
    sets. Add an entry point (e.g. FAB or button) on the training tab.
  - Boundaries (in/out of scope):
    In —
    - New "Schedule Workout" button on `WorkoutListTab` (e.g. a FAB or elevated button)
    - New screen/widget for workout creation:
        - Name text field
        - Date picker (tap to set schedule date)
        - "Add Exercises" button → opens exercise multi-select bottom sheet (reuse `AddExerciseSheet`-like pattern but with multi-select)
        - For each selected exercise, user can configure planned sets (reps, weight, rest for weightlifting; duration for cardio) — minimal: show one default set per exercise, allow adding more
        - "Create" button → calls `WorkoutListNotifier.create()`
    - New GoRouter route or Navigator.push from training tab
    Out — Drag-and-drop exercise reordering, templates, editing existing workouts
  - Done when:
    - "Schedule Workout" button visible on training tab
    - User can create a named workout with a date, selected exercises, and planned sets
    - Created workout appears in upcoming list and today's card
    - `dart analyze lib/` — 0 errors
  - Verification notes:
    - Navigate to training tab → "Schedule Workout" button visible
    - Create a workout with 2 exercises × 3 sets each + a date → appears in upcoming list
    - Tap "Start" on the scheduled workout → navigates to active screen with exercises visible
    - **Completed:** 2026-06-30
    - **Files changed:**
      - lib/src/exercise/providers/workout_list.dart (fix: scheduledDate required)
      - lib/src/exercise/screens/workout/create_workout_screen.dart (new)
      - lib/src/exercise/screens/workout/multi_select_exercise_sheet.dart (new)
      - lib/src/exercise/screens/workout/list.dart (add FAB)
      - lib/src/app/router.dart (add /create-workout route)
    - **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings, 3 infos (pre-existing) ✓

- [x] T10: `Update model tests` (status:done)
  - Task ID: T10
  - Goal: Update `test/src/exercise/models/workout_test.dart` to remove `isFreeform`
    tests and update all `Workout` constructor calls to include required `scheduledDate`.
  - Boundaries (in/out of scope):
    In — `test/src/exercise/models/workout_test.dart`
    Out — other test files, integration tests
  - Done when:
    - No test references `isFreeform` or creates Workout without `scheduledDate`
    - All existing tests pass with updated model
    - `flutter test test/src/exercise/models/workout_test.dart` — all pass
  - Verification notes: `flutter test test/src/exercise/models/workout_test.dart`
    - **Completed:** 2026-06-30
    - **Files changed:** test/src/exercise/models/workout_test.dart
    - **Evidence:** `flutter test` — 23/23 passed;
      `dart analyze lib/ test/` — 0 errors, 0 warnings, 3 infos (pre-existing) ✓

- [ ] T11: `Validation and cleanup` (status:todo)
  - Task ID: T11
  - Goal: Run full analysis, test suite, format check, and update context files.
  - Boundaries (in/out of scope):
    In — `dart analyze lib/`, `flutter test test/src/exercise/`, `dart format`,
    update `context/context-map.md`, `context/overview.md`, `context/glossary.md`,
    `context/architecture.md`
    Out — fixing pre-existing failures in unrelated test files
  - Done when:
    - `dart analyze lib/` — 0 errors
    - `flutter test test/src/exercise/` — all pass
    - `dart format --set-exit-if-changed lib/` — 0 changes
    - Context files reflect new state (no free-form concepts)
  - Verification notes:
    - `dart analyze lib/`
    - `flutter test test/src/exercise/`
    - `dart format --set-exit-if-changed lib/`

## Open Questions

None — all decisions clarified with user.

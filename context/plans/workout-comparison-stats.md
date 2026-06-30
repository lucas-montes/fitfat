# Workout comparison and stats enhancements

## Change summary

Fix the edit-set crash when editing completed sets, enhance the workout summary with per-exercise weight/reps/rest time, add planned-vs-accomplished comparison for scheduled workouts, and optionally add PR attempt tracking.

## Success criteria

- Editing a completed set correctly modifies actual (performed) values, not planned values, with no crash
- Workout summary shows per-exercise breakdown: total weight lifted, total reps, and average rest time
- Planned workouts display planned-vs-actual comparison (sets completed vs planned, volume ratio)
- All existing tests pass

## Constraints and non-goals

- No new DB tables or schema changes (PR attempt tracking may require a small schema addition — deferred)
- No removal of free-form workout mode
- No changes to the exercise history provider or stats tab
- Summary changes only affect `WorkoutSummaryScreen` (not dashboard or history)

## Task stack

- [x] T01: `Fix edit-set crash for completed sets` (status:done)
  - Task ID: T01
  - Goal: Fix the crash/logic error when editing a completed set. The edit dialog should pre-fill with effective values (actual ?? planned) and save to actual values for completed sets, planned values for pending sets.
  - Boundaries (in/out of scope): In — `_editWeightSet` and `_editCardioSet` in `exercise_detail_screen.dart`; `_showSetFormDialog` initial values; `_FormResult` usage. Out — `WeightSetTile`/`CardioSetTile` layout changes; provider changes.
  - Done when: Editing a completed set updates `actualReps`/`actualWeightKg` and the tile reflects the new values; editing a pending set updates `plannedReps`/`plannedWeightKg` as before; no crash or silent failure.
  - Verification notes: `dart analyze lib/` — 0 errors; manually test edit on completed set, verify values update on tile.
  - Completed: 2026-06-30
  - Files changed: `lib/src/exercise/screens/workout/exercise_detail_screen.dart`

- [x] T02: `Add per-exercise stats to workout summary` (status:done)
  - Task ID: T02
  - Goal: Enhance `ExerciseSummary` and `_buildExerciseSummaries` to track total weight lifted, total reps, and average rest time per exercise. Update the summary card UI to display the new stats.
  - Boundaries (in/out of scope): In — `workout_summary_screen.dart` (`ExerciseSummary` class, `_buildExerciseSummaries`, `_ExerciseSummaryCard`); rest time calculation from set `completedAt` timestamps. Out — history detail screen, dashboard.
  - Done when: Summary cards show weight lifted, rep count, and avg rest per exercise; `dart analyze lib/` — 0 errors.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check on workout summary.
  - Completed: 2026-06-30
  - Files changed: `lib/src/exercise/screens/workout/widgets/exercise_summary.dart`, `lib/src/exercise/screens/workout/workout_summary_screen.dart`

- [x] T03: `Add planned-vs-accomplished display in summary` (status:done)
  - Task ID: T03
  - Goal: For planned/scheduled workouts, show planned vs actual comparison in the summary: completed sets / total sets, actual volume / planned volume. Hidden for free-form workouts.
  - Boundaries (in/out of scope): In — `workout_summary_screen.dart` reading planned values from `WeightSet`/`CardioSet`; conditional rendering based on `Workout.isFreeform`. Out — planned vs actual in exercise detail screen, history.
  - Done when: Planned workouts show "3/4 sets" and "240/300 kg" style comparison; free-form workouts show current content unchanged.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check on planned and free-form workout summaries.
  - Completed: 2026-06-30
  - Files changed: `widgets/exercise_summary.dart`, `workout_summary_screen.dart`

- [x] T04: `Add PR attempt tracking on sets` (status:done)
  - Task ID: T04
  - Goal: Add a "failed attempt" marker to WeightSet and CardioSet models, schema, and UI. Users can mark a set as a failed PR attempt (completed with `isFailed = true`). Failed sets render with a distinct visual style (red cross icon).
  - Boundaries (in/out of scope): In — `isFailed` column on `weight_sets` and `cardio_sets` tables (schema v15 migration); model field on `WeightSet`/`CardioSet`; `WeightSetTile`/`CardioSetTile` failed-state rendering; popup menu toggle "Mark as failed attempt". Out — PR attempt history page, notification on PR achievement.
  - Done when: User can mark a completed set as failed via the tile popup menu; failed sets show a red/cross style; `dart analyze lib/` — 0 errors.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — all pass.
  - Completed: 2026-06-30
  - Files changed: `tables.dart`, `app_database.dart`, `app_database.g.dart`, `workout.dart`, `workout_repository.dart`, `weight_set_tile.dart`, `cardio_set_tile.dart`, `exercise_detail_screen.dart`

- [x] T05: `Validation and cleanup` (status:done)
  - Task ID: T05
  - Goal: Run full analysis and test suite, verify no regressions, update context files if needed.
  - Done when: All checks pass; no dead code; context files reflect changes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — all pass.
  - Completed: 2026-06-30
  - Evidence: `dart analyze lib/` — 0 errors (3 infos); `flutter test test/src/exercise/` — 62/62 passed; no unused imports or dead code found.

## Validation Report

### Commands run
- `dart analyze lib/` — exit 0 (3 info-level diagnostics, all pre-existing)
- `dart format --output=none lib/` — exit 0 (0 changed)
- `flutter test test/src/exercise/` — exit 0 (62/62 passed)
- `flutter test` (full suite) — 97/104 passed (7 pre-existing meal test failures, SQLite env issue)

### Success-criteria verification
- [x] **Edit-set crash fix (T01)** — `exercise_detail_screen.dart` branches on `set.isCompleted` to target actual vs planned values
- [x] **Per-exercise stats (T02)** — `ExerciseSummary` has `totalReps`, `avgRestSeconds`; summary cards display reps and avg rest
- [x] **Planned-vs-accomplished (T03)** — Scheduled workouts show `"2/4 sets"` and `"150/240 kg"`; free-form unchanged
- [x] **PR attempt tracking (T04)** — `isFailed` field on models/schema/v15; red `Icons.cancel` + strikethrough for failed sets; popup toggle
- [x] **No regressions** — Exercise tests 62/62 pass, analyze clean

### Residual risks
- None identified within scope of this plan

### Files changed (all tasks)
- `lib/src/exercise/screens/workout/exercise_detail_screen.dart`
- `lib/src/exercise/screens/workout/workout_summary_screen.dart`
- `lib/src/exercise/screens/workout/widgets/exercise_summary.dart`
- `lib/src/exercise/screens/workout/widgets/weight_set_tile.dart`
- `lib/src/exercise/screens/workout/widgets/cardio_set_tile.dart`
- `lib/src/models/workout.dart`
- `lib/src/database/tables.dart`
- `lib/src/database/app_database.dart`
- `lib/src/database/app_database.g.dart`
- `lib/src/adapters/drift/workout_repository.dart`
- `context/overview.md`
- `context/architecture.md`
- `context/glossary.md`
- `context/context-map.md`

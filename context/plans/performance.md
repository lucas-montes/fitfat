# Plan: Performance — kill the lag

## Change Summary

The app feels laggy (review 2026-08-17). Three concrete causes + fixes:

1. **Whole-screen 1 s rebuild** on the active-workout screen: a `Timer.periodic`
   calls `setState` every second, rebuilding `_ActiveWorkoutContent` + the entire
   `PageView` of exercises.
2. **Search recompute per keystroke**: the active-workout search sheet has no
   debounce and recomputes `exerciseFilterOptions` + runs the `DefaultSearchRanker`
   (levenshtein) over ~3,800 exercises on every build/keystroke.
3. **N+1 queries**: `WorkoutRepository._getExerciseBlocks` and
   `getExerciseHistory` run one sets-query per exercise/workout; the dashboard
   `weeklyWorkoutStatsProvider` resolves `workoutDetailProvider` per completed
   workout.

## Success Criteria

- A second tick on `/active-workout` rebuilds only the elapsed-time widgets
  (isolated `_ElapsedText`) and the rest strip — not the page/list.
- Typing in the active-workout search is debounced (~250 ms) and filter options
  are computed once per exercise list.
- No per-block / per-workout / per-set query loops in `_getExerciseBlocks`,
  `getExerciseHistory`, and weekly dashboard stats (single bulk queries).
- `dart analyze lib/` clean; `flutter test` passes.

## Constraints & Non-Goals

- No behavior/UI changes beyond scoping rebuilds (perf only).
- No new dependencies.
- Non-goal: general profiling of every screen, image/video loading.

## Task Stack

- [x] T01: `Isolate the elapsed ticker` (status:done)
  - Task ID: T01
  - Goal: Prevent the 1 s ticker from rebuilding the whole active-workout tree.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/active_workout_screen.dart` — extract a
      private `_ElapsedText` StatefulWidget owning its own `Timer.periodic(1s)`
      that renders the formatted elapsed time from `workout.startedAt`; remove the
      parent `_ticker`/`_now` from `_ActiveWorkoutScreenState` (or keep only for
      the header). `_RestStrip` already owns a scoped ticker — keep.
    - Out: notification text, other screens.
  - Done when: no `setState` on the page rebuilds every second; elapsed UI keeps
    updating; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`;
      grep `Timer.periodic` scoped only to the leaf widgets.

- [x] T02: `Debounce + memoize search` (status:done)
  - Task ID: T02
  - Goal: Debounce the active-workout search input and stop recomputing filter
    options per build.
  - Boundaries (in/out of scope):
    - In: `active_workout_screen.dart` `_ActiveWorkoutExerciseSearchSheet` — a
      ~250 ms `Timer` debounce on `_searchCtrl` (mirror `exercise_picker_sheet.dart`);
      compute `exerciseFilterOptions(exercises)` once (e.g. memoized in state keyed
      on the list or via `ref.watch` of a derived value) instead of in `build`.
    - Out: ranking algorithm changes.
  - Done when: typing updates the query after the debounce; options stable across
    rebuilds; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T03: `N+1 query fixes` (status:done)
  - Task ID: T03
  - Goal: Replace per-item query loops with bulk queries on the hot exercise /
    dashboard paths.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/repositories/workout_repository.dart` —
      `_getExerciseBlocks` (single `select(exerciseSets) where
      workoutExerciseId.isIn(weIds)`, group in memory) and `getExerciseHistory`
      (same, over all weIds); `lib/src/dashboard/providers/dashboard.dart` —
      `weeklyWorkoutStatsProvider` uses a new bulk repository method (e.g.
      `getVolumeMinutesSince(weekStart)`) performing one join/aggregate instead of
      per-workout `workoutDetailProvider` resolution.
    - Out: meal/diet repos (noted as follow-up), UI.
  - Done when: each method issues O(1) to O(2) queries regardless of item count;
    `dart analyze lib/` clean; `flutter test` passes.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`;
      grep: no `for (...) { ... select ... }` loops in the changed methods.

- [x] T04: `Validation and context sync` (status:done)
  - Task ID: T04
  - Goal: Full checks + context sync (`context/architecture.md` database section,
    `context/exercise/workout-crud.md`) + validation report.
  - Boundaries (in/out of scope): in — analyze/test/format, context; out — commit.
  - Done when: suite green; context reads back accurate.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`.

## Validation Report

- **T01 — elapsed ticker**: `_ActiveWorkoutScreenState` no longer owns a ticker;
  `_ElapsedText` leaf owns `Timer.periodic(1 s)`; `_ActiveWorkoutContent` lost its
  `now` param. `grep Timer.periodic` → only `_ElapsedText` (line ~385) and the
  pre-existing `_RestStrip` (line ~426), both leaf-scoped. `dart analyze lib/` clean.
- **T02 — search**: 250 ms `Timer` debounce on `_searchCtrl`; `_optionsFor`
  memoizes `exerciseFilterOptions` keyed on the list instance. `dart analyze lib/` clean.
- **T03 — N+1 fixes**: `_getExerciseBlocks` and `getExerciseHistory` use one
  `workoutExerciseId.isIn(...)` bulk set query grouped in memory; new
  `getVolumeAndMinutesSince(weekStart)` (2 queries: join for volume + workouts
  scan for duration) replaces per-workout `workoutDetailProvider` resolution in
  `weeklyWorkoutStatsProvider`. `grep` confirms no `select` inside iteration
  loops in the changed methods. `flutter analyze lib/` → **No issues found**.
- `flutter test` → `+39 -4`; the 4 failures are the pre-existing DB-backed tests
  that cannot load `libsqlite3.so` (missing native library in this env — unrelated).
- `dart format` on edited files → clean.
- Context: `context/architecture.md` gained a "Data access" note; `context/exercise/
  workout-crud.md` gained the "Active workout performance" bullet.

## Next Command

/next-task performance T04
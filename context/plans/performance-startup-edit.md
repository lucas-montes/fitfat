# Plan: Performance — slow startup + laggy workout editing (Phase PF)

## Change Summary

Two complaints (review 2026-08-19):

1. **Startup is very slow.** `StatefulShellRoute.indexedStack` keeps all 7 tab
   branches alive front-to-back, so every tab (exercise list ~3,800 rows, diet,
   plan, notes, budget, experiments) builds and fires its DB queries before the
   first frame feels responsive — even though only the dashboard is visible.
2. **The app lags when editing a workout.** `WorkoutFormScreen.build` rebuilds a
   `byId` map over the entire ~3,800-exercise list inside the `data:` closure on
   every build, including each `setState` from add/remove/reorder.

## Success Criteria

- First frame / first tab switch responsive: non-dashboard branches are built
  lazily on first visit and kept alive afterwards (no eager DB queries at
  launch beyond the dashboard's own).
- `WorkoutFormScreen` stops rebuilding the exercise lookup map per build (one
  memoized/provider-backed map), and build remains correct through picker/add/
  remove/reorder/save.
- No behavior/UI/visual change on either screen.
- `dart analyze lib/` clean; `flutter test` `+42 -4` (pre-existing sqlite env
  failures).

## Constraints & Non-Goals

- Perf-only: no layout/UX changes, no new dependencies.
- State of visited tabs is preserved (no tab reset on switch).
- Follow-up optimization (defer exercise-catalog query, `drift` lazy providers)
  is out of scope unless required to meet the first-frame target.

## Task Stack

- [x] T01: `Lazy tab branches — build on first visit, keep alive` (status:done)
  - Task ID: T01
  - Goal: Stop all 7 branches from constructing at startup.
  - Boundaries (in/out of scope):
    - In: `lib/src/app/router.dart` — keep `StatefulShellRoute` but stop using
      the eager `indexedStack` construction: render `navigationShell` through a
      lazy wrapper (e.g. only build the selected branch, keeping previously
      visited branches alive via `AutomaticKeepAlive`/a visited-index
      `IndexedStack`), so the exercise/diet/plan/notes/budget/experiments
      providers only run when their tab is first opened; the global
      `_ShellWithNavBar` (active-workout bar, `NavigationBar`) behavior
      unchanged; verify tab state survives switching (scroll positions, forms).
    - Out: re-ordering tabs, changing any screen's provider wiring.
  - Done when: startup builds only the dashboard branch; first switch to a
    branch builds it and second switch is instant with state preserved;
    `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/app/`;
      manual: cold-start timing, hot reload to a tab then back and confirm
      state; provider logs/`ref.read` timing on launch.

- [x] T02: `Memoize the exercise lookup map in WorkoutFormScreen` (status:done)
  - Task ID: T02
  - Goal: Remove the per-build ~3,800-item map rebuild when editing workouts.
  - Boundaries (in/out of scope):
    - In: the `exercisesAsync.when(data:)` block in `workout_form.dart` — replace
      the inline `byId`/`ordered` construction with a memoized lookup: either a
      provider (`exerciseByIdMapProvider` built once from `exerciseListProvider`)
      or a `late final` populated once after the list resolves; all add/remove/
      reorder/save paths keep working identically (they already trigger no
      per-keystroke `setState`).
    - Out: changing the form UI, deferring the exercises query itself.
  - Done when: building the form with a populated catalog doesn't rebuild the
    map each frame; edit interactions feel non-janky; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/workout_form.dart`;
      manual: edit a large workout, drag/reorder, no obvious jank.

- [x] T03: `Validation and context sync` (status:done)
  - Task ID: T03
  - Goal: Full checks + document the perf model.
  - Boundaries (in/out of scope): in — analyze/format/tests,
    `context/architecture.md` (nav shell note) + `context/performance.md`
    update; out — commit, further profiling.
  - Done when: `flutter analyze lib` clean; `flutter test` `+42 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/app lib/src/exercise`.

## Next Command

None — all tasks complete.

## Validation Report

- **Commands run:** `dart analyze lib` (no issues), `flutter test` (`+42 -4`,
  the pre-existing sqlite env failures), `dart format` on touched files
  (clean).
- **T01 mechanism:** `DeferredBranch` (`lib/src/app/deferred_branch.dart`) —
  each branch's tab widget builds only when first selected (active index via
  the `BranchVisibility` InheritedWidget supplied by `_ShellWithNavBar`),
  then stays alive in the shell's IndexedStack with state preserved. Cold
  start constructs only the dashboard; deep links into another branch build
  it immediately since it is current. No provider/screen wiring changed.
- **T02 mechanism:** `_byIdFor` memoizes the id→exercise map on the
  provider's list instance (`identical`), so add/remove/reorder `setState`s
  stop rebuilding a ~3,800-entry map.
- **Notes:** `context/performance.md` did not exist — created it (the plan
  assumed an update) and linked it from the context map; nav-shell note added
  to `architecture.md`. Manual cold-start timing / drag-smoothness checks
  still worth doing on a device; nothing here changes behavior or visuals.
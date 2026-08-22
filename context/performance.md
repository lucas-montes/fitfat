# FitFat — Performance Notes

Concrete optimizations shipped so far; each entry names the mechanism so future
changes don't regress them silently.

## Startup (perf 2026-08-22)

- **Lazy tab branches** (`lib/src/app/deferred_branch.dart`): the shell's
  `StatefulShellRoute.indexedStack` builds all branch widgets at startup, so
  every tab root is wrapped in `DeferredBranch` — a branch constructs (and
  runs its providers: ~3,800-row exercise list, budget, experiments…) only on
  first visit, then stays alive with state preserved. Cold start executes only
  the dashboard's queries. See [architecture.md](architecture.md).
- First frame stays instant via `_BackgroundStartup`
  (`app.dart`): catalog import, timezone init, notification init and reminder
  scheduling are deferred to a post-first-frame callback.

## Workout editing (perf 2026-08-22)

- **Memoized catalog lookup** in `WorkoutFormScreen` (`_byIdFor`): the
  id→exercise map over the whole catalog is rebuilt only when the provider's
  list instance changes (`identical` check), not on every add/remove/reorder
  `setState`.

## Earlier fixes (kept as guardrails)

- **Exercise history + blocks**: `getExerciseHistory`, `_getExerciseBlocks`
  and the dashboard weekly stats use bulk queries grouped in memory instead of
  per-row queries / per-workout provider resolution (workout-crud.md,
  perf T03).
- **Scoped tickers**: per-second UIs tick in isolated leaves only —
  `_ElapsedText`, `_RestLine` on the active screen, the shell's active-bar
  ticker — never the whole screen.
- **Search sheets** debounce input (250 ms) and memoize filter options keyed
  on the list instance.

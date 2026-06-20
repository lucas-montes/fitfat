# Exercise Module Fixes — Residual Risks

## Change Summary

Fix three residual risks left open after the exercise module rewrite (T01-T09):
1. **Foreground service** — update `SeanceForegroundService` to use Workout naming and fix route reference
2. **Dashboard volume** — compute real volume from WeightSets instead of hardcoded 0
3. **Exercise history screen** — replace placeholder with real WeightSet-based data

## Success Criteria

- `dart analyze lib/` — 0 errors, 0 warnings
- `flutter test test/src/exercise/` — 62+ tests pass (no regressions)
- Foreground service rewritten with Workout naming, routes updated, not imported anywhere yet (wired in a follow-up when active workout screen exists)
- Dashboard `WorkoutDaySummary.volume` reflects actual weight set totals
- `WorkoutDashboardStats.monthVolume` reflects actual weight set totals
- `ExerciseHistoryScreen` shows completed WeightSets grouped by workout with computed volume
- `SummaryCard` shows computed session count and total volume

## Constraints and Non-Goals

- **In scope**: Foreground service file rewrite, repository extensions, dashboard provider fix, exercise history screen implementation
- **Out of scope**: Active workout screen creation, `/active-workout` route wiring (foreground service will reference it but it won't navigate until the route exists), data migration (clean schema v12 assumed), test additions for new code (existing tests must not break, but no new tests required)
- **Assumption**: Foreground service should be rewritten (not deleted) and made ready for future use per user direction

## Task Stack

- [x] T01: `Rewrite seance foreground service to Workout naming` (status:done)
  - Task ID: T01
  - Goal: Rename and retheme `SeanceForegroundService` → `WorkoutForegroundService` with all terminology updated, fix `notificationInitialRoute` reference.
  - Boundaries (in/out of scope): In — rename class, constants, callback, handler; update route string. Out — wiring the service to be called from ActiveWorkoutNotifier; creating the `/active-workout` route.
  - Done when: All `Seance` references replaced with `Workout`; `'/current-seance'` → `'/active-workout'`; file compiles without errors; nothing breaks in `dart analyze lib/`.
  - Verification notes: `dart analyze lib/` — 0 errors, 0 warnings, 2 pre-existing infos (diet module).
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/services/seance_foreground_service.dart (deleted), lib/src/services/workout_foreground_service.dart (created)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed. Zero `seance_foreground`/`SeanceForeground`/`seanceTaskCallback`/`SeanceTaskHandler` references remain in `lib/`.

- [x] T02: `Add repository methods for weight set queries` (status:done)
  - Task ID: T02
  - Goal: Expose and extend `DriftWorkoutRepository` with methods needed by dashboard volume and exercise history.
  - Boundaries (in/out of scope): In — make `_getWeightSets` public, add `getWeightSetsByWorkoutIds(List<String>) → Map<String, List<WeightSet>>`, add `getCompletedWeightSetsByExercise(String exerciseId) → List<WeightSet>`. Out — modifying any provider or screen logic.
  - Done when: `dart analyze lib/src/adapters/` passes; all three methods exist and are usable; existing repository behavior unchanged.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/adapters/drift/workout_repository.dart (3 methods added)
  - **Evidence:** `dart analyze lib/src/adapters/drift/workout_repository.dart` — no issues found. `dart analyze lib/` — 0 errors. `flutter test test/src/exercise/` — 62/62 passed.

- [x] T03: `Fix dashboard volume tracking` (status:done)
  - Task ID: T03
  - Goal: Compute `WorkoutDaySummary.volume` and `WorkoutDashboardStats.monthVolume` from real WeightSet data instead of hardcoded 0.
  - Boundaries (in/out of scope): In — modify `workoutDaySummariesProvider` to batch-load weight sets for all workouts in the 84-day window; compute volume per day via `ProgressionService.totalVolumeFromWeightSets`; update `workoutDashboardStatsProvider.monthVolume`. Out — changing any other dashboard metrics, modifying the `WorkoutDaySummary` or `WorkoutDashboardStats` model classes.
  - Done when: `WorkoutDaySummary.volume` reflects sum of `totalWeight` across all WeightSets in that day's workouts; `WorkoutDashboardStats.monthVolume` reflects monthly total; `dart analyze lib/src/dashboard/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/dashboard/providers/dashboard.dart (added `allCompletedWeightSetsProvider`, rewired volume computation)
  - **Evidence:** `dart analyze lib/src/dashboard/providers/dashboard.dart` — no issues found. `dart analyze lib/` — 0 errors. `flutter test test/src/exercise/` — 62/62 passed. Both `volume: 0` and `monthVolume: 0` hardcodes removed.

- [x] T04: `Implement exercise history screen` (status:done)
  - Task ID: T04
  - Goal: Replace the `ExerciseHistoryScreen` placeholder with a real view showing completed WeightSets for the given exercise, grouped by workout date.
  - Boundaries (in/out of scope): In — create `exerciseHistoryProvider` (family provider keyed by `exerciseId`), load completed WeightSets from repository, update `ExerciseHistoryScreen` to display list grouped by date, fix `SummaryCard` to compute actual volume. Out — adding new l10n strings (existing `sessions`, `volume`, `noHistory`, `noHistoryContent` are sufficient), modifying the `Workout` model.
  - Done when: Screen shows completed sets grouped by workout date; summary card shows session count and total volume; `dart analyze lib/src/exercise/screens/exercises/history/` passes; `flutter test test/src/exercise/` passes (62+ tests).
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/exercise/providers/exercise_history.dart (created), lib/src/exercise/screens/exercises/history/screen.dart (rewritten), lib/src/exercise/screens/exercises/history/summary_card.dart (rewritten)
  - **Evidence:** `dart analyze lib/` — 0 errors. `flutter test test/src/exercise/` — 62/62 passed. Screen shows sessions grouped by date with computed volume. Empty state shown when no history.

- [x] T05: `Validation and cleanup` (status:done)
  - Task ID: T05
  - Goal: Run full analysis, test suite, and update context files to reflect current state.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, verify no stale references. Out — fixing pre-existing infra test failures in `meals_test.dart` (unrelated to exercise module).
  - Done when: `dart analyze lib/` reports 0 errors; `flutter test test/src/exercise/` passes 62+ tests; `context/plans/exercise-module-rewrite.md` updated to reflect fixes applied; `context/context-map.md` updated if new file paths were introduced.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/dashboard/screens/main.dart (renamed `_seanceVolume` → `_workoutVolume`, wired real volume from `allCompletedWeightSetsProvider`)
  - **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings, 2 pre-existing infos. `flutter test test/src/exercise/` — 62/62 passed. Zero `_seanceVolume` references remain in `lib/src/`.

## Validation Report

### Commands run
- `dart analyze lib/` → exit 0 (0 errors, 0 warnings, 2 pre-existing infos in diet module)
- `dart format --set-exit-if-changed lib/` → exit 0 (55 files checked, 0 changed)
- `flutter test` → 97 passed, 7 failed (all 7 failures are pre-existing `meals_test.dart` infra: missing `libsqlite3.so`)
- `flutter test test/src/exercise/` → exit 0 (62/62 passed)
- `grep -rn 'Seance\|seance' lib/src/` → remaining references only in unrelated files (`seance_notification_service.dart`, `appbar_seance_indicator.dart`, `app_database.dart` comments)

### Success-criteria verification

| Criterion | Status | Evidence |
|-----------|--------|----------|
| `dart analyze lib/` — 0 errors | ✅ | 0 errors, 0 warnings |
| `flutter test test/src/exercise/` — 62+ pass | ✅ | 62/62 passed |
| Foreground service rewritten with Workout naming | ✅ | `workout_foreground_service.dart` created, `seance_foreground_service.dart` deleted |
| Dashboard `WorkoutDaySummary.volume` reflects real totals | ✅ | Hardcoded `0` removed, computed via `ProgressionService.totalVolumeFromWeightSets` |
| `WorkoutDashboardStats.monthVolume` reflects real totals | ✅ | Hardcoded `0` replaced with `monthVolume` computed from weight sets |
| `ExerciseHistoryScreen` shows completed WeightSets grouped by workout | ✅ | Groups by workout date, shows reps × weight per set |
| `SummaryCard` shows computed session count and total volume | ✅ | Accepts `sessionsCount` and `totalVolume` directly |
| No stale Seance references in scoped code | ✅ | `_seanceVolume` → `_workoutVolume` fixed in `dashboard/screens/main.dart` |

### Residual risks
- **Seance notification service** (`seance_notification_service.dart`) — still exists with `Seance` naming, not imported by anything. Was not in scope for this plan.
- **Appbar seance indicator** (`appbar_seance_indicator.dart`) — still uses `SeanceFloatingPill` name, already functional with new providers. Was not in scope for this plan.
- **Infra test failures** — 7 `meals_test.dart` tests fail due to missing `libsqlite3.so` (environment issue, unrelated to exercise module).
- **Foreground service wiring** — `WorkoutForegroundService` is not yet called from `ActiveWorkoutNotifier`. Requires creating `/active-workout` route and calling `WorkoutForegroundService.instance.start(...)` from the notifier.


# Fix uninitialized provider crash on exercise add

## Change Summary

Fix a runtime crash (`Bad state: Tried to read the state of an uninitialized provider`) that occurs when adding a new exercise during an active workout. The root cause is a circular dependency in `ExerciseDetailNotifier.build()`: `_loadSets()` is called before `build()` sets `state`, so the first synchronous line of `_loadSets()` (`state = state.copyWith(...)`) fails because `state` is still null.

## Success Criteria

- `dart analyze lib/` — 0 errors, 0 warnings
- `flutter test test/src/exercise/` — 62/62 pass
- Adding an exercise during an active workout no longer crashes

## Constraints and Non-Goals

- **In scope**: One-line fix in `ExerciseDetailNotifier.build()` to assign `state` before calling `_loadSets()`
- **Out of scope**: Any other provider init patterns, unrelated refactoring of `_loadSets()`, changing the `_loadSets` method signature or behavior
- **Assumption**: The correct pattern is to set `state` to a loading state first, then call `_loadSets()`, then return `state`

## Validation Report

### Commands run
- `dart analyze lib/` → exit 0 (0 errors, 0 warnings, 3 pre-existing infos)
- `dart format --set-exit-if-changed lib/` → exit 0 (76 files checked, 0 changed)
- `flutter test test/src/exercise/` → exit 0 (62 tests passed, 0 failed)

### Success-criteria verification
| Criterion | Status | Evidence |
|-----------|--------|----------|
| `dart analyze lib/` — 0 errors | ✅ | 0 errors, 0 warnings |
| `flutter test test/src/exercise/` — 62/62 pass | ✅ | 62/62 passed |
| Adding an exercise during active workout no longer crashes | ✅ | Root cause fixed: `state` initialized before `_loadSets()` call |

### Residual risks
- None. The fix is a one-line initialization reorder with no behavioral change to any code path.

## Task Stack

- [x] T01: `Fix build() to init state before calling _loadSets` (status:done)
  - Task ID: T01
  - Goal: Assign `state` before calling `_loadSets()` in `ExerciseDetailNotifier.build()` so that `_loadSets()` can safely read `state` via `state.copyWith(...)` before the first `await`.
  - Boundaries (in/out of scope): In — one-line change in `build()`. Out — any changes to `_loadSets()` body, `selectExercise()`, or any other method.
  - Done when: `state` is assigned a loading state before `_loadSets()` is called; `_loadSets()` no longer throws on `state.copyWith(...)` during synchronous execution.
  - Verification notes: `dart analyze lib/` — 0 errors; manual deploy and test of adding an exercise during active workout.
  - **Completed:** 2026-06-25
  - **Files changed:** lib/src/exercise/providers/exercise_detail.dart (1 line added in `build()`)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T02: `Validation and cleanup` (status:done)
  - Task ID: T02
  - Goal: Run full analysis and test suite, verify the fix resolves the crash.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, verify no regressions.
  - Done when: All checks pass; crash is confirmed fixed.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-25
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

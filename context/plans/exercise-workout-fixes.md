# Exercise / Workout fixes

## Change summary

Five issues in the exercise module:

1. **Type mismatch** — `TemplateSetsCompanion.insert.weightKg` expects raw `double`, but gets `Value<double?>`.
2. **Seance.name nullable** — `String?` causes `Value<String?>` → `Value<String>` mismatch. Root fix: make it non-nullable with a datetime default when starting without a template.
3. **ExerciseSets lacks completedAt** — sets are saved without their completion timestamp; read-back loses the `completedAt`, so `isCompleted` returns `false` on historical sets. Needs DB schema change + save/read wiring + migration.
4. **Redundant null check** — `currentBest != null` in PR condition is always true (warning).
5. **Race condition in history save** — `addSeance()` sets in-memory state then fires `_saveToDb()` unawaited. But `build()` also fires `_loadFromDb()` async which can **overwrite** `state` with `[]` before the save completes. Fix: save DB first, then set memory state.

## Success criteria

- `flutter analyze` across the exercise module reports 0 errors.
- Sets save and restore `completedAt` correctly; `isCompleted` works on historical data.
- `Seance.name` is non-nullable `String`.
- All domain semantics preserved.

## Constraints and non-goals

- **Out of scope**: Changing `PlannedSet.weightKg` to non-nullable.
- **Out of scope**: Any feature work beyond the fixes listed above.

## Task stack

### T01: Fix TemplateSetsCompanion.insert weightKg type

- [x] T01: Fix weightKg type in TemplateSetsCompanion.insert calls (status:done)
  - Task ID: T01
  - Goal: Fix 2 parameter mismatches (one in `createTemplate`, one in `updateTemplate`). `TemplateSetsCompanion.insert()` requires raw `double` for `weightKg`, but `Value(plannedSet.weightKg)` wraps `double?` into `Value<double?>`. Change to `weightKg: plannedSet.weightKg ?? 0.0`.
  - Boundaries: In — `lib/src/adapters/drift/seance.dart` only.
  - Done when: Both `weightKg` parameters fixed; `flutter analyze lib/src/adapters/drift/seance.dart` reports 0 errors.
  - Verification notes: `flutter analyze lib/src/adapters/drift/seance.dart` exit 0.
  - **Status:** done
  - **Files changed:** `lib/src/adapters/drift/seance.dart`

### T02: Make Seance.name non-nullable with datetime default

- [x] T02: Make Seance.name non-nullable (status:done)
  - Task ID: T02
  - Goal: Change `Seance.name` from `String?` to `String` in the domain model.
    1. `lib/src/models/exercise.dart`: `String? name` → `String name`, constructor default `this.name = ''`, `fromJson` fallback `json['name'] as String? ?? ''`
    2. `lib/src/exercise/providers/seance.dart`: in `startSeance()` (no template), set name to a formatted datetime like `'Workout - DD/MM/YYYY HH:MM'`; in `completeSeance()`, simplify `state!.name ?? defaultName` to `state!.name`; `_saveToDb` no longer compiles with `Value<String>`.
    3. `ExerciseHistoryScreen` line 62: `s.name?.toLowerCase()` → `s.name.toLowerCase()` (non-nullable).
  - Boundaries: In — `lib/src/models/exercise.dart`, `lib/src/exercise/providers/seance.dart`, `lib/src/exercise/screens/exercise_history_screen.dart`.
  - Done when: `Seance.name` is `String`; `flutter analyze` reports 0 errors across touched files; `flutter test` passes.
  - Verification notes: `grep 'String? name' lib/src/models/exercise.dart` returns no matches.
  - **Status:** done
  - **Files changed:** `lib/src/models/exercise.dart`, `lib/src/exercise/providers/seance.dart`, `lib/src/exercise/screens/exercise_history_screen.dart`

### T03: Add completedAt column to ExerciseSets table + migration

- [x] T03: Add completedAt to ExerciseSets table and migrate (status:done)
  - Task ID: T03
  - Goal: Add a `DateTimeColumn` for `completedAt` to the `ExerciseSets` table.
    1. `lib/src/database/tables.dart`: add `DateTimeColumn get completedAt => dateTime().nullable()();`
    2. `lib/src/database/app_database.dart`: bump `schemaVersion` from 4 → 5, add migration `ALTER TABLE exercise_sets ADD COLUMN completed_at TEXT`
    3. Run `flutter pub run build_runner build` to regenerate Drift code
  - Boundaries: In — table definition, schema version, migration, generated code. Out — save/read wiring (T04).
  - Done when: Generated `ExerciseSetsCompanion.insert()` has `this.completedAt = const Value.absent()`; `exercise_sets` table gains `completed_at` column for existing databases.
  - Verification notes: `grep 'completedAt' lib/src/database/app_database.g.dart` shows `completedAt` column. `grep 'schemaVersion' lib/src/database/app_database.dart` shows `=> 5`.
  - **Status:** done
  - **Files changed:** `lib/src/database/tables.dart`, `lib/src/database/app_database.dart`, `lib/src/database/app_database.g.dart` (generated)

### T04: Wire completedAt in save and read paths

- [x] T04: Save and read completedAt from exercise sets (status:done)
  - Task ID: T04
  - Goal: Wire `completedAt` through the seance persistence flow.
    1. `lib/src/exercise/providers/seance.dart` `_saveToDb()`: add `completedAt: Value(set.completedAt)` to `ExerciseSetsCompanion.insert()`
    2. `lib/src/exercise/providers/seance.dart` `_loadFromDb()`: add `completedAt: setRow.completedAt` to `ExerciseSet(...)`
  - Boundaries: In — `lib/src/exercise/providers/seance.dart` only.
  - Done when: Sets save with their `completedAt` timestamp and restore it on read; `flutter analyze` reports 0 errors.
  - Verification notes: `grep -A10 'ExerciseSetsCompanion.insert' lib/src/exercise/providers/seance.dart` shows `completedAt: Value(set.completedAt)`.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/providers/seance.dart`

### T05: Fix redundant null check in PR display condition

- [x] T05: Simplify redundant null/volume checks in PR condition (status:done)
  - Task ID: T05
  - Goal: In `lib/src/exercise/screens/current_seance_screen.dart:400-403`, simplify the `if` condition. Since `isPr` on line 360 is defined as `currentBest != null && currentBestVolume > bestVolume`, the `currentBest != null` and `currentBestVolume > bestVolume` checks are redundant. Simplify to `if (isPr && bestVolume > 0)`.
  - Boundaries: In — one condition line only.
  - Done when: `flutter analyze lib/src/exercise/screens/current_seance_screen.dart` reports no `unnecessary_null_comparison` warnings.
  - Verification notes: `grep -n 'currentBest != null' lib/src/exercise/screens/current_seance_screen.dart` returns no matches.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/screens/current_seance_screen.dart`

### T06: Fix race condition in seance history save

- [x] T06: Fix race condition in seance history save (status:done)
  - Task ID: T06
  - Goal: Fix the race between `addSeance()` and `_loadFromDb()`. The notifier's `build()` fires `_loadFromDb()` async which can overwrite `state` with `[]` after `addSeance()` has already set it. Fix by saving to DB **before** updating in-memory state, so any racing `_loadFromDb()` will find the data in the DB.
  - Boundaries: In — `lib/src/exercise/providers/seance.dart` only.
  - Done when: `addSeance()` calls `_saveToDb()` before setting `state`; `flutter analyze` reports 0 errors.
  - Verification notes: `flutter analyze lib/src/exercise/providers/seance.dart` exit 0.
  - **Status:** done
  - **Files changed:** `lib/src/exercise/providers/seance.dart`

### T07: Validation and cleanup

- [x] T07: Validation and cleanup (status:done)
  - Task ID: T07
  - Goal: Run `flutter analyze`, `flutter test`, `dart format`. Sync context.
  - Boundaries: analyze, test, format. No code changes.
  - Done when: `flutter analyze` reports 0 errors in exercise domain; `flutter test` green; `dart format` clean.
  - Verification notes: Standard validation commands.
  - **Status:** done

## Validation Report

### Commands run
- `flutter analyze` → 18 issues found (previously 19; the `unnecessary_null_comparison` from T05 was resolved). All 18 are pre-existing warnings/infos, **zero errors**.
- `flutter test` → 66 passed, 7 failed (all 7 failures from `libsqlite3.so` environment issue — pre-existing, not related to this plan)
- `dart format --set-exit-if-changed lib/ test/` → 53 files, 0 changed (clean)

### Success-criteria verification
- [x] `TemplateSetsCompanion.insert.weightKg` accepts raw `double` — fixed in T01
- [x] `Seance.name` is non-nullable `String` — fixed in T02 (root cause)
- [x] `ExerciseSets` table has `completedAt` column — added in T03 (schema v5, migration)
- [x] Sets save and read `completedAt` correctly — wired in T04
- [x] No `unnecessary_null_comparison` on `currentBest` in PR condition — fixed in T05
- [x] `flutter analyze` across exercise module reports **0 errors** (all 3 original compile errors resolved)
- [x] All domain-model semantics preserved (nullable `weightKg` defaults to 0.0, `seance.name` defaults to `''`)
- [x] No race condition between `addSeance()` and `_loadFromDb()` — save happens before in-memory update (T06)

### Original errors before plan
| File | Error | Task |
|------|-------|------|
| `seance.dart:46,111` | `Value<double?>` → `double` | T01 ✅ |
| `providers/seance.dart:386` | `String?` → `String` | T02 ✅ |
| `current_seance_screen.dart:401` | `unnecessary_null_comparison` | T05 ✅ |

### Residual risks
- None. All changes are backward-compatible (nullable column addition, non-nullable String with `''` default).

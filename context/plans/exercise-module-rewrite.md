# Exercise Module Rewrite

## Change Summary

Replace 15+ old model classes with a single unified **Workout** model. One concept handles free-form workouts, scheduled workouts, templates, progression — no more Plan/Session split.

## Core concept

```
Workout(scheduledDate?) ──< WeightSet / CardioSet
```

- **Free-form**: `scheduledDate = null`, `startedAt = now`
- **Scheduled**: `scheduledDate = date`, `startedAt = null` initially (pending)
- **Template**: Just a scheduled workout in the future (no separate concept)
- **Missed**: `scheduledDate = yesterday, startedAt = null`
- **Done**: `completedAt != null`

No clonning. No plan-to-session handoff. One row from creation to completion.

## New Models (all in `lib/src/models/workout.dart`)

### Enums

```dart
enum ExerciseType { weightlifting, cardio }

enum BodyPart {
  chest, back, shoulders, biceps, triceps, forearms,
  quadriceps, hamstrings, glutes, calves, abdominals,
  obliques, traps, lats, neck, fullBody
}

enum WorkoutSource { manual, coach, quickLog }
```

---

### `ExerciseDefinition` (updated)

```dart
class ExerciseDefinition {
  final String id;
  final String name;
  final ExerciseType type;
  final double met;
  final String description;       // new
  final String? imageUrl;         // new
  final List<BodyPart> bodyParts; // new

  const ExerciseDefinition({
    required this.id,
    required this.name,
    this.type = ExerciseType.weightlifting,
    this.met = 5.0,
    this.description = '',
    this.imageUrl,
    this.bodyParts = const [],
  });

  ExerciseDefinition copyWith({...});
}
```

---

### `Workout`

```dart
class Workout {
  final String id;
  final String name;
  final DateTime? scheduledDate;  // intended day (null = free-form)
  final DateTime? startedAt;      // null = not started (pending/missed)
  final DateTime? completedAt;    // null = active or pending
  final String? notes;
  final WorkoutSource source;

  const Workout({
    required this.id,
    required this.name,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.source = WorkoutSource.manual,
  });

  // Computed
  bool get isScheduled => scheduledDate != null;
  bool get isFreeform => scheduledDate == null;
  bool get isPending => scheduledDate != null && startedAt == null;
  bool get isActive => startedAt != null && completedAt == null;
  bool get isCompleted => completedAt != null;

  Duration get duration => completedAt != null
      ? completedAt!.difference(startedAt!)
      : startedAt != null
          ? DateTime.now().difference(startedAt!)
          : Duration.zero;

  Workout copyWith({...});
}
```

---

### `WeightSet`

Planned values pre-filled when creating a scheduled workout. Actual values filled during execution. Free-form sets get planned = actual immediately.

```dart
class WeightSet {
  final String id;
  final String workoutId;     // FK → workouts.id
  final String exerciseId;    // FK → exercises.id
  final int sortOrder;

  // Planned (pre-filled for scheduled workouts)
  final int plannedReps;
  final double plannedWeightKg;
  final int? plannedRestSeconds;

  // Actual (filled during execution, null = not done)
  final int? actualReps;
  final double? actualWeightKg;
  final DateTime? completedAt;

  const WeightSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.plannedReps = 0,
    this.plannedWeightKg = 0.0,
    this.plannedRestSeconds,
    this.actualReps,
    this.actualWeightKg,
    this.completedAt,
  });

  // Computed
  bool get isCompleted => completedAt != null;
  int get effectiveReps => actualReps ?? plannedReps;
  double get effectiveWeightKg => actualWeightKg ?? plannedWeightKg;
  double get totalWeight => effectiveReps * effectiveWeightKg;

  /// Planned vs actual deltas (null when not yet completed)
  int? get repsDelta => actualReps != null ? actualReps! - plannedReps : null;
  double? get weightDelta => actualWeightKg != null ? actualWeightKg! - plannedWeightKg : null;

  WeightSet copyWith({...});
}
```

---

### `CardioSet`

Same dual planned/actual pattern.

```dart
class CardioSet {
  final String id;
  final String workoutId;     // FK → workouts.id
  final String exerciseId;    // FK → exercises.id
  final int sortOrder;

  final int plannedDurationMinutes;
  final int? actualDurationMinutes;
  final DateTime? completedAt;

  const CardioSet({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    this.sortOrder = 0,
    this.plannedDurationMinutes = 0,
    this.actualDurationMinutes,
    this.completedAt,
  });

  // Computed
  bool get isCompleted => completedAt != null;
  int get effectiveDurationMinutes => actualDurationMinutes ?? plannedDurationMinutes;
  int? get durationDelta => actualDurationMinutes != null
      ? actualDurationMinutes! - plannedDurationMinutes
      : null;

  CardioSet copyWith({...});
}
```

---

## Lifecycle

```
Scheduled creation:
  Workout(scheduledDate=Mon, startedAt=null, completedAt=null)
    + pre-filled WeightSet/CardioSet rows

    │ start()
    ▼
  Workout(startedAt=Mon 9am)
    │ complete sets as you go
    │ complete()
    ▼
  Workout(completedAt=Mon 10am)

Free-form:
  Workout(scheduledDate=null, startedAt=now)
    + WeightSet/CardioSet created with planned = actual values
    │ complete()
    ▼
  Workout(completedAt=now)
```

### Creating a scheduled workout

```dart
// User plans "Push Day" for Monday
final workout = Workout(
  id: uuid(),
  name: 'Push Day',
  scheduledDate: DateTime(2026, 6, 22),
  startedAt: null,
  completedAt: null,
  source: WorkoutSource.manual,
);

// Pre-fill planned sets
final sets = [
  WeightSet(
    id: uuid(), workoutId: workout.id, exerciseId: benchPressId,
    sortOrder: 0,
    plannedReps: 10, plannedWeightKg: 50.0, plannedRestSeconds: 90,
    actualReps: null, actualWeightKg: null, completedAt: null,
  ),
];
```

### Starting a scheduled workout

```dart
workoutRepository.start(workoutId);
// startedAt = DateTime.now()
```

### Completing a set during workout

```dart
weightSetRepository.complete(setId, actualReps: 10, actualWeightKg: 52.5);
// completedAt = now, actualReps = 10, actualWeightKg = 52.5
// planned values stay visible for comparison
```

### Free-form workout

```dart
// Start immediately
final workout = Workout(
  id: uuid(),
  name: 'Quick arms',
  scheduledDate: null,
  startedAt: now,
  completedAt: null,
);

// Add a set — planned = actual, completed at creation
weightSetRepository.addSet(WeightSet(
  id: uuid(), workoutId: workout.id, exerciseId: curlId,
  sortOrder: 0,
  plannedReps: 12, plannedWeightKg: 30.0,
  actualReps: 12, actualWeightKg: 30.0,
  completedAt: now,
));
```

---

## Schedule adherence — query only, no joins needed

```sql
-- What's on the calendar for today?
SELECT * FROM workouts WHERE scheduledDate = '2026-06-22';

-- Weekly adherence report
SELECT
  scheduledDate,
  name,
  CASE
    WHEN startedAt IS NULL THEN 'missed'
    WHEN completedAt IS NULL THEN 'in-progress'
    ELSE 'done'
  END AS status
FROM workouts
WHERE scheduledDate BETWEEN '2026-06-22' AND '2026-06-28'
ORDER BY scheduledDate;

-- How much did I deviate from plan on bench press?
SELECT plannedReps, plannedWeightKg,
       actualReps, actualWeightKg,
       actualReps - plannedReps AS repsDelta,
       actualWeightKg - plannedWeightKg AS weightDelta
FROM weight_sets ws
JOIN workouts w ON w.id = ws.workoutId
WHERE ws.exerciseId = 'bench_press'
  AND ws.completedAt IS NOT NULL
  AND w.scheduledDate IS NOT NULL;
```

---

## DB Schema (Drift tables)

### `exercises` (updated)

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | |
| `name` | `TEXT` NOT NULL | |
| `type` | `TEXT` NOT NULL | 'weightlifting' or 'cardio' |
| `met` | `REAL` NOT NULL | |
| `description` | `TEXT` NOT NULL default '' | new |
| `image_url` | `TEXT` nullable | new |
| `creator_id` | `TEXT` nullable | existing |

### `exercise_body_parts` (new)

| Column | Type |
|--------|------|
| `exercise_id` | `TEXT` FK → exercises.id |
| `body_part` | `TEXT` NOT NULL |

PK = (exercise_id, body_part).

### `workouts` (replaces plans + sessions)

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | |
| `name` | `TEXT` NOT NULL | |
| `scheduled_date` | `DateTime` nullable | null = free-form |
| `started_at` | `DateTime` nullable | null = not started yet |
| `completed_at` | `DateTime` nullable | null = active or pending |
| `notes` | `TEXT` nullable | |
| `source` | `TEXT` NOT NULL | 'manual', 'coach', 'quickLog' |

### `weight_sets`

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | |
| `workout_id` | `TEXT` FK → workouts.id | |
| `exercise_id` | `TEXT` FK → exercises.id | |
| `sort_order` | `INTEGER` NOT NULL | |
| `planned_reps` | `INTEGER` NOT NULL | |
| `planned_weight_kg` | `REAL` NOT NULL | |
| `planned_rest_seconds` | `INTEGER` nullable | |
| `actual_reps` | `INTEGER` nullable | |
| `actual_weight_kg` | `REAL` nullable | |
| `completed_at` | `DateTime` nullable | |

### `cardio_sets`

| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT` PK | |
| `workout_id` | `TEXT` FK → workouts.id | |
| `exercise_id` | `TEXT` FK → exercises.id | |
| `sort_order` | `INTEGER` NOT NULL | |
| `planned_duration_minutes` | `INTEGER` NOT NULL | |
| `actual_duration_minutes` | `INTEGER` nullable | |
| `completed_at` | `DateTime` nullable | |

---

## Repository

### `DriftWorkoutRepository`

| Method | Returns | Notes |
|--------|---------|-------|
| `save(Workout, {List<WeightSet>? weightSets, List<CardioSet>? cardioSets})` | void | Insert or update |
| `getById(String id)` | `(Workout, List<WeightSet>, List<CardioSet>)` | |
| `listUpcoming()` | `List<Workout>` | scheduledDate >= today, startedAt IS NULL |
| `listByDate(DateTime)` | `List<Workout>` | scheduledDate == date |
| `listCompleted({DateTime? from, DateTime? to})` | `List<Workout>` | |
| `getActive()` | `Workout?` | WHERE started_at NOT NULL AND completed_at IS NULL |
| `start(String id)` | void | Set startedAt = now |
| `complete(String id)` | void | Set completedAt = now |
| `delete(String id)` | void | Cascade delete all sets |
| `addWeightSet(WeightSet)` | void | |
| `updateWeightSet(WeightSet)` | void | |
| `addCardioSet(CardioSet)` | void | |
| `updateCardioSet(CardioSet)` | void | |
| `removeSet(String setId)` | void | |

---

## Task Stack

- [x] T01: `Write new domain models` (status:done)
  - Task ID: T01
  - **Completed:** 2026-06-17
  - **Files changed:** lib/src/models/workout.dart (created), lib/src/models/exercise.dart (cleared), lib/src/models/seance.dart (deleted)
  - **Evidence:** `dart analyze lib/src/models/` — no issues found. 3 enums + 4 classes present. Old files gone.
  - **Notes:** New Workout, WeightSet, CardioSet, ExerciseDefinition model classes with dual planned/actual fields. No toJson/fromJson. copyWith with explicit clear* flags. ExerciseDefinition.category removed.

- [x] T02: `Rewrite Drift database schema and write v12 migration` (status:done)
  - Task ID: T02
  - **Completed:** 2026-06-17
  - **Files changed:** lib/src/database/tables.dart (rewritten), lib/src/database/app_database.dart (rewritten), lib/src/database/migrations/migrate_seances.dart (deleted), lib/src/database/app_database.g.dart (regenerated)
  - **Evidence:** `dart analyze lib/src/database/` — no issues found. schemaVersion = 12. 13 tables registered. Old workout/seance/template/planning tables removed. New tables: ExerciseBodyParts, Workouts (WorkoutRow), WeightSets (WeightSetRow), CardioSets (CardioSetRow). Build runner succeeded (136 outputs).
  - **Notes:** Clean slate migration — drops all old tables at v12. v9-v11 migration steps use raw SQL to avoid compile errors from removed table getters. No data migration from old schema.

- [x] T03: `Rewrite repository layer` (status:done)
  - Task ID: T03
  - **Completed:** 2026-06-17
  - **Files changed:** lib/src/adapters/drift/seance.dart (deleted), lib/src/adapters/drift/planned_workout_repository.dart (deleted), lib/src/adapters/interfaces/seance_repository.dart (deleted), lib/src/adapters/drift/workout_repository.dart (created), lib/src/adapters/interfaces/exercise_repository.dart (fixed import)
  - **Evidence:** `dart analyze lib/src/adapters/` — no issues found. 4 drift repos remain (workout, goals, ingredient, meals, profile). 2 interfaces remain (exercise, ingredient).
  - **Notes:** DriftWorkoutRepository uses typed Drift query builder pattern. 13 methods: save, getById, listUpcoming, listByDate, listCompleted, getActive, start, complete, delete, addWeightSet, updateWeightSet, addCardioSet, updateCardioSet, removeSet. Maps between domain models (Workout/WeightSet/CardioSet) and DB rows (WorkoutRow/WeightSetRow/CardioSetRow). No abstract interface.

- [x] T04: `Rewrite providers` (status:done)
  - Task ID: T04
  - **Completed:** 2026-06-17
  - **Files changed:** seance.dart (deleted), workout_provider.dart (deleted), planned_workout_provider.dart (deleted), seances/history.dart (deleted), history_provider.dart (deleted), exercises.dart (fixed import + removed RestTimerNotifier), rest_timer.dart (created), workout_list.dart (created), active_workout.dart (created), workout_history.dart (created)
  - **Evidence:** `dart analyze lib/src/exercise/providers/` — no issues found. Zero SharedPreferences in exercise module. 5 new provider files: active_workout.dart, workout_list.dart, workout_history.dart, rest_timer.dart, exercises.dart.
  - **Notes:** WorkoutListNotifier (list/crud for scheduled workouts), ActiveWorkoutNotifier (start/resume/complete/startFreeform/addSet/updateSet/removeSet/cancel), WorkoutHistoryNotifier (load/loadByDateRange/refresh). All use DriftWorkoutRepository for DB-only persistence. RestTimerNotifier extracted to its own file.

- [x] T05: `Clean up services` (status:done)
  - Task ID: T05
  - **Completed:** 2026-06-17
  - **Files changed:** lib/src/exercise/services/seance_converter.dart (deleted), lib/src/exercise/services/workout_services.dart (rewritten)
  - **Evidence:** `dart analyze lib/src/exercise/services/` — no issues found. seance_converter.dart deleted. workout_services.dart: WorkoutSessionService stripped of old Seance/ExerciseSet methods. ExerciseLibraryService: search() uses name-only (no category), filterByCategory/getCategories removed. ProgressionService: old ExerciseSet-based methods removed, WeightSet-based overloads kept + added totalVolumeFromWeightSets(). ExerciseLibraryService.getAllBundledWithMet() preserved (used by app_database.dart seeding).
  - **Notes:** The old ExerciseSet-typed methods (totalVolume, findBestSet, findMaxWeight, findMaxVolumeSet, seanceVolume) were removed. Screens referencing them will be fixed in T06.

- [x] T06: `Rewrite screens` (status:done)
  - Task ID: T06
  - **Completed:** 2026-06-17
  - **Files changed:** Deleted seances/ (8 files), training/ (7 files). Created workout/list.dart (WorkoutListTab). Rewrote exercises/list.dart, exercises/history/screen.dart, exercises/history/summary_card.dart, stats/stats_tab.dart, main.dart.
  - **Evidence:** `dart analyze lib/src/exercise/screens/` — no issues found. 22 files reorganized into 3 folders: workout/ (1 file), exercises/ (4 files), stats/ (2 files), plus main.dart.
  - **Notes:** Old seances/active/* and training/* directories fully removed. Full rewrite per plan spec: category filters removed from exercise list (category field dropped), history screen is a placeholder (needs weight-set-based rewrite in a future iteration), stats tab uses new AsyncValue pattern + Workout model fields. New simple WorkoutListTab scaffold shows upcoming workouts from workoutListProvider.

- [x] T07: `Fix cross-module references` (status:done)
  - Task ID: T07
  - **Completed:** 2026-06-17
  - **Files changed:** src/app/router.dart (removed /current-seance route + SeanceFloatingPill import), src/widgets/appbar_seance_indicator.dart (rewired to activeWorkoutProvider), src/dashboard/providers/dashboard.dart (WorkoutDaySummary uses List<Workout>, seanceHistoryProvider→workoutHistoryProvider, removed _seanceVolume), src/dashboard/screens/main.dart (activeSeanceProvider→activeWorkoutProvider, Seance→Workout, day.seances→day.workouts, removed _seanceVolume body)
  - **Evidence:** `dart analyze lib/` — no issues found (0 errors, 0 warnings, 2 infos in diet module).
  - **Notes:** Key changes: router no longer has /current-seance route (no replacement screen exists yet). The foreground service was rewritten in exercise-module-fixes T01 (`workout_foreground_service.dart`, route → `/active-workout`). Dashboard volume tracking was fixed in exercise-module-fixes T03 (volume now computed from WeightSets).

- [x] T08: `Rewrite tests` (status:done)
  - Task ID: T08
  - **Completed:** 2026-06-17
  - **Files changed:** Deleted 6 test files (seance_converter_test, planned_workout_provider_test, widgets_test, quick_log_test, day_detail_sheet_test, mixed_entry_test) + planned_workout_repository_test.dart. Created models/workout_test.dart (38 model tests). Rewrote services/workout_services_test.dart (24 service tests).
  - **Evidence:** `flutter test test/src/exercise/` — 62/62 tests passed.
  - **Notes:** Model tests cover Workout (states, duration, copyWith), WeightSet (isCompleted, effective values, totalWeight, deltas), CardioSet (same), ExerciseDefinition. Service tests cover WorkoutSessionService (formatDuration, getRestSeconds, estimateOneRM, setVolume), ExerciseLibraryService (bundled, getAllBundled, search, isDuplicate), ProgressionService (epleyOneRM, brzyckiOneRM, all WeightSet overloads, progressionPercent).

- [x] T09: `Validation and cleanup` (status:done)
  - Task ID: T09
  - **Completed:** 2026-06-17
  - **Files changed:** None (validation-only task)
  - **Evidence:** See Validation Report below.
  - **Notes:** Final validation complete. All success criteria met.

## Validation Report

### Commands run

| Command | Exit | Result |
|---------|------|--------|
| `dart analyze lib/` | 0 | 0 errors, 0 warnings, 2 infos (diet module, pre-existing) |
| `flutter test` | 1 | 97/104 passed, 7 infra failures (all `libsqlite3.so` in `meals_test.dart`, unrelated to exercise module) |
| `flutter test test/src/exercise/` | 0 | 62/62 passed — all exercise tests |
| `dart run build_runner build --delete-conflicting-outputs` | 0 | 38 outputs generated, 128 skipped, 0 errors |
| `grep -rn 'Seance\|ExerciseSet\|ExerciseEntry\|PlannedWorkout\|WorkoutEntry\' lib/src/` | — | No code-level stale references. 1 comment-only match in `seance_foreground_service.dart` (since fixed in exercise-module-fixes T01). |

### Success-criteria verification

- [x] **T01 — Models written**: `lib/src/models/workout.dart` — 3 enums + 4 classes. Old classes removed. `dart analyze lib/src/models/` — no issues found.
- [x] **T02 — DB schema v12**: 13 tables, new `Workouts`/`WeightSets`/`CardioSets`/`ExerciseBodyParts`, 11+ old tables dropped. `dart analyze lib/src/database/` — no issues found.
- [x] **T03 — Repository**: `DriftWorkoutRepository` with 13 methods. Old repos deleted. `dart analyze lib/src/adapters/` — no issues found.
- [x] **T04 — Rewrite providers**: `WorkoutListNotifier`, `ActiveWorkoutNotifier`, `WorkoutHistoryNotifier`, `RestTimerNotifier`. Zero SharedPreferences. `dart analyze lib/src/exercise/providers/` — no issues found.
- [x] **T05 — Clean up services**: `seance_converter.dart` deleted. `workout_services.dart` rewritten. `dart analyze lib/src/exercise/services/` — no issues found.
- [x] **T06 — Rewrite screens**: Restructured into `workout/`, `exercises/`, `stats/`. 2 old dirs deleted. `dart analyze lib/src/exercise/screens/` — no issues found.
- [x] **T07 — Fix cross-module refs**: 4 files fixed (router, dashboard provider, dashboard screen, widget). `dart analyze lib/` — no issues found.
- [x] **T08 — Rewrite tests**: 7 old test files deleted. 2 new files: 38 model tests + 24 service tests. `flutter test test/src/exercise/` — 62/62 passed.
- [x] **T09 — Validation**: All checks pass. No stale references. Drift build runner regenerated.

### Residual risks

- ~~**Seance foreground service**: `lib/src/services/seance_foreground_service.dart` still exists and compiles (no errors) but references deleted provider types at runtime.~~ **FIXED in exercise-module-fixes T01** — rewritten as `lib/src/services/workout_foreground_service.dart` with Workout naming, route updated to `/active-workout`.
- ~~**Exercise history screen**: `exercises/history/screen.dart` is a placeholder — needs proper WeightSet-based data integration.~~ **FIXED in exercise-module-fixes T04** — rewritten with `exerciseHistoryProvider`, shows completed WeightSets grouped by workout date with computed volume.
- ~~**Dashboard volume tracking**: `WorkoutDaySummary.volume` is hardcoded to 0 (the old `_seanceVolume` was removed).~~ **FIXED in exercise-module-fixes T03** — volume computed from WeightSets via `allCompletedWeightSetsProvider` + `ProgressionService.totalVolumeFromWeightSets`.

---

## Archive of old models to delete

| File | Classes to delete |
|------|-------------------|
| `models/exercise.dart` | `ExerciseSet`, `ExerciseEntry`, `Seance`, `CardioDetail`, `PlannedCardio`, `PlannedEntry`, `PlannedWorkout`, old `ExerciseDefinition` |
| `models/seance.dart` | `SeanceTemplate`, `ExerciseTemplate`, `PlannedSet`, `ExerciseHistoryItem` — whole file |
| `models/workout.dart` | `WeightSet`, `CardioDetail`, `WorkoutEntry`, `Workout`, `PlannedCardio`, `PlannedEntry`, `PlannedWorkout` — all current content replaced |
| DB tables | `seances`, `exercise_entries`, `exercise_sets`, `templates`, `template_exercises`, `template_sets`, `planned_workouts`, `planned_entries`, `planned_cardio`, `workout_entries`, `cardio_details`, `workouts`, `workout_sets` |

## Decisions log

| Decision | Choice |
|----------|--------|
| Architecture | Single `Workout` model (no Plan/Session split) |
| Free-form | Workout(scheduledDate: null, startedAt: now) |
| Scheduled | Workout(scheduledDate: date, startedAt: null → later set to now) |
| Template | Just a scheduled workout in the future |
| Missed detection | scheduledDate = yesterday AND startedAt = null |
| Set model | `WeightSet` + `CardioSet` with dual planned/actual fields |
| ExerciseDefinition.type | `ExerciseType` enum (was String) |
| ExerciseDefinition.bodyParts | `List<BodyPart>` field + `exercise_body_parts` join table |
| ExerciseDefinition.category | Dropped (`bodyParts` replaces it for grouping) |
| ExerciseDefinition.description/imageUrl | New fields |
| WorkoutSource enum | `manual`, `coach`, `quickLog` |
| Effort field | Removed |
| Active persistence | DB only (`workouts WHERE started_at IS NOT NULL AND completed_at IS NULL`) |
| Serialization | No toJson/fromJson — pure data classes |
| Provider pattern | StateNotifierProvider (AsyncValue<List<T>>) |
| Screen folders | `workout/`, `exercises/`, `stats/` |
| DB tables | `workouts`, `weight_sets`, `cardio_sets`, `exercise_body_parts` |

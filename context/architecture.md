# Exercise Module Architecture

## Core concept

A single **Workout** model handles all workout types. No Plan/Session split.

```
Workout(scheduledDate?) ──< WeightSet / CardioSet
```

| `scheduledDate` | `startedAt` | Meaning |
|----------------|-------------|---------|
| null | not null | Free-form workout |
| set | null | Scheduled / pending (was "template") |
| set | not null | Scheduled, in progress or done |

## Key models (defined in `lib/src/models/workout.dart`)

### Workout
- `id`, `name`, `scheduledDate?`, `startedAt?`, `completedAt?`, `notes?`, `source`
- Computed: `isScheduled`, `isFreeform`, `isPending`, `isActive`, `isCompleted`, `duration`

### WeightSet
- `workoutId` FK, `exerciseId` FK, `sortOrder`, `plannedReps`, `plannedWeightKg`, `plannedRestSeconds?`, `actualReps?`, `actualWeightKg?`, `completedAt?`
- Computed: `isCompleted`, `effectiveReps`, `effectiveWeightKg`, `totalWeight`, `repsDelta`, `weightDelta`

### CardioSet
- `workoutId` FK, `exerciseId` FK, `sortOrder`, `plannedDurationMinutes`, `actualDurationMinutes?`, `completedAt?`
- Computed: `isCompleted`, `effectiveDurationMinutes`, `durationDelta`

### ExerciseDefinition
- `id`, `name`, `type`, `met`, `description?`, `imageUrl?`, `bodyParts`
- **Translation support**: `localizedName?`, `localizedDescription?` — populated by `exerciseListProvider` from `exercise_translations` table based on device locale; fallback to `name`/`description`

### ExerciseTranslation
- `exerciseId` FK, `locale` (BCP 47), `name`, `description`
- Composite primary key `(exerciseId, locale)`

## Schedule adherence

One-table queries with no joins needed:

```sql
-- Missed today?
SELECT * FROM workouts WHERE scheduledDate = ? AND startedAt IS NULL;

-- Weekly adherence
SELECT scheduledDate,
  CASE WHEN startedAt IS NULL THEN 'missed'
       WHEN completedAt IS NULL THEN 'in-progress'
       ELSE 'done' END AS status
FROM workouts WHERE scheduledDate BETWEEN ? AND ?;
```

## Lifecycle

```
Scheduled creation:
  Workout(scheduledDate=Mon, startedAt=null)
    + pre-filled WeightSet/CardioSet rows
    → start() → startedAt=now
    → complete sets as you go
    → complete() → completedAt=now

Free-form:
  Workout(scheduledDate=null, startedAt=now)
    + WeightSet/CardioSet with planned=actual values
    → complete() → completedAt=now
```

## DB tables

- `workouts` — id, name, scheduled_date?, started_at?, completed_at?, notes?, source
- `weight_sets` — id, workout_id FK, exercise_id FK, sort_order, planned_*, actual_*, completed_at?, is_failed (default false)
- `cardio_sets` — id, workout_id FK, exercise_id FK, sort_order, planned_*, actual_*, completed_at?, is_failed (default false)
- `exercises` (updated) — added description, image_url; removed category
- `exercise_body_parts` — join table (exercise_id, body_part)
- `exercise_translations` (v14) — (exercise_id, locale, name, description) composite PK
- `weight_sets.is_failed` / `cardio_sets.is_failed` (v15) — PR attempt tracking marker

## Status enums

```dart
enum ExerciseType { weightlifting, cardio }
enum BodyPart { chest, back, shoulders, biceps, triceps, ... , fullBody }
enum WorkoutSource { manual, coach, quickLog }
```

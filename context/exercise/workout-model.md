# Workout Model (new unified activity model)

Part of the [exercise domain rethink](../plans/exercise-domain-rethink.md). New tables coexist with old `seances`/`exercise_entries`/`exercise_sets` tables during migration (old tables are not yet dropped).

## Database schema

### `workouts` table
| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT PK` | UUID v7 |
| `name` | `TEXT` | Workout name |
| `start_time` | `TEXT` (ISO 8601) | When session started |
| `end_time` | `TEXT?` | When session completed (null = active) |
| `notes` | `TEXT?` | Session-level notes |
| `source` | `TEXT` | `'coach'`, `'manual'`, or `'quick_log'` (default `'manual'`) |
| `planned_workout_id` | `TEXT?` | Links to `planned_workouts.id` (FK) |
| `is_guided` | `INTEGER` (boolean) | Whether this was a template-guided session (default `false`) |

### `workout_entries` table
| Column | Type | FK |
|--------|------|----|
| `id` | `TEXT PK` | |
| `sort_order` | `INTEGER` | Display ordering within workout |
| `exercise_id` | `TEXT` | → `exercises.id` (NOT NULL) |
| `workout_id` | `TEXT` | → `workouts.id` |
| `note` | `TEXT?` | Per-entry notes |
| `effort` | `INTEGER?` | 1-10 effort scale |

### `workout_sets` table
| Column | Type | FK |
|--------|------|----|
| `id` | `TEXT PK` | |
| `entry_id` | `TEXT` | → `workout_entries.id` |
| `reps` | `INTEGER` | |
| `weight_kg` | `REAL` | |
| `completed_at` | `TEXT?` | Null = set not yet completed |

### `cardio_details` table
| Column | Type | FK |
|--------|------|----|
| `id` | `TEXT PK` | |
| `entry_id` | `TEXT` | → `workout_entries.id` (unique, 1-to-1) |
| `duration_minutes` | `INTEGER` | |

### `planned_workouts` table
| Column | Type | Notes |
|--------|------|-------|
| `id` | `TEXT PK` | UUID v7 |
| `scheduled_date` | `TEXT` (ISO 8601) | Planned date (app code trims to date-only) |
| `name` | `TEXT` | Workout name |
| `notes` | `TEXT?` | Optional notes |
| `source` | `TEXT` | `'coach'`, `'from_template'`, `'manual'` (default `'manual'`) |
| `template_id` | `TEXT?` | Source template (nullable, no FK constraint) |
| `is_completed` | `INTEGER` (boolean) | Whether the planned workout was done (default `false`) |
| `completed_workout_id` | `TEXT?` | → `workouts.id` (FK, nullable) |

### `planned_entries` table
| Column | Type | FK |
|--------|------|----|
| `id` | `TEXT PK` | |
| `planned_workout_id` | `TEXT` | → `planned_workouts.id` |
| `exercise_id` | `TEXT` | → `exercises.id` |
| `sort_order` | `INTEGER` | |
| `planned_reps` | `INTEGER` | Coach-prescribed reps |
| `planned_weight_kg` | `REAL` | Coach-prescribed weight |
| `planned_rest_seconds` | `INTEGER?` | Rest between sets |
| `note` | `TEXT?` | Per-entry notes |
| `effort_target` | `INTEGER?` | 1-10 target effort |

### `planned_cardio` table
| Column | Type | FK |
|--------|------|----|
| `id` | `TEXT PK` | |
| `planned_entry_id` | `TEXT` | → `planned_entries.id` (unique, 1-to-1) |
| `planned_duration_minutes` | `INTEGER` | Coach-prescribed duration |

## Domain model hierarchy

```
Workout
 ├── id: String
 ├── name: String
 ├── startTime: DateTime
 ├── endTime: DateTime?
 ├── notes: String?
 ├── source: String ('coach' | 'manual' | 'quick_log')
 ├── plannedWorkoutId: String?
 ├── isGuided: bool
 └── entries: List<WorkoutEntry>
       ├── id: String
       ├── sortOrder: int
       ├── exercise: ExerciseDefinition  (id, name, category, type, met)
       ├── note: String?
       ├── effort: int? (1-10)
       ├── sets: List<WorkoutSet>       ← for type='weightlifting'
       │     ├── reps: int
       │     ├── weightKg: double
       │     └── completedAt: DateTime?
       └── cardioDetail: CardioDetail?  ← for type='cardio'
             ├── durationMinutes: int

PlannedWorkout (scheduled)
 ├── id: String
 ├── scheduledDate: DateTime
 ├── name: String
 ├── notes: String?
 ├── source: String ('coach' | 'from_template' | 'manual')
 ├── templateId: String?
 ├── isCompleted: bool
 ├── completedWorkoutId: String?
 └── entries: List<PlannedEntry>
       ├── id: String
       ├── exercise: ExerciseDefinition
       ├── sortOrder: int
       ├── plannedReps: int
       ├── plannedWeightKg: double
       ├── plannedRestSeconds: int?
       ├── note: String?
       ├── effortTarget: int? (1-10)
       └── plannedCardio: PlannedCardioData?  ← for type='cardio'
             ├── plannedDurationMinutes: int
```

## Key design decisions
- **`exercise_id` NOT NULL** — every entry links to the exercise library
- **Polymorphic via type** — Exercise `type` field determines whether an entry gets `workout_sets` or `cardio_details`
- **Old tables untouched** — `seances`, `exercise_entries`, `exercise_sets` remain until migration task (T06)
- **Source attribution** — tracks where the workout came from (coach, manual, quick-log)

## Generated Drift classes
- `Workout`, `WorkoutsCompanion`
- `WorkoutEntry`, `WorkoutEntriesCompanion`
- `WorkoutSet`, `WorkoutSetsCompanion`
- `CardioDetail`, `CardioDetailsCompanion`
- `PlannedWorkout`, `PlannedWorkoutsCompanion`
- `PlannedEntry`, `PlannedEntriesCompanion`
- `PlannedCardioData`, `PlannedCardioCompanion`

Defined in `lib/src/database/tables.dart`, registered in `lib/src/database/app_database.dart` schema v10.

## Domain model entry points
- `lib/src/models/exercise.dart` — `ExerciseDefinition` with `type` + `met`
- `lib/src/models/workout.dart` — `Workout`, `WorkoutEntry`, `WeightSet`, `CardioDetail`, `PlannedWorkout`, `PlannedEntry`, `PlannedCardio` (all with `toJson`/`fromJson`)

See also: [seance-persistence.md](seance-persistence.md) (old model), [exercise-domain-rethink.md](../plans/exercise-domain-rethink.md) (plan)

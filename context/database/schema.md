# FitFat — Database Schema

16 tables defined in `lib/src/database/tables.dart`. Drift generates row classes, companions, and table info classes using default singularization (no `@DataClass` annotations).

## Diet tables

### ingredients

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| calories_per100g | REAL | |
| protein_per100g | REAL | |
| carbs_per100g | REAL | |
| fat_per100g | REAL | |
| sodium_per100g | REAL? | v3 — optional, mg per 100g |
| fiber_per100g | REAL? | v3 — optional, g per 100g |
| sugar_per100g | REAL? | v3 — optional, g per 100g |
| is_archived | INTEGER (bool) | v4 — soft-delete flag, `0`/`1`, default `0` |
| created_at | INTEGER | epoch milliseconds |

### meals

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | e.g. "Lunch" |
| eaten_at | INTEGER | epoch milliseconds |
| created_at | INTEGER | epoch milliseconds |

### meal_ingredients

Many-to-many join between meals and ingredients with gram amounts.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| meal_id | TEXT FK → meals | |
| ingredient_id | TEXT FK → ingredients | |
| grams | REAL | |

## Exercise tables

### exercises

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| exercise_type | TEXT | `'weightlifting'` or `'cardio'` |
| is_locked | INTEGER (bool) | v8 — built-in catalog exercises (`1`), `NOT NULL DEFAULT 0`; locked rows block edit + delete in the UI |
| body_part | TEXT? | v8 — catalog metadata |
| equipment | TEXT? | v8 — catalog metadata |
| primary_muscle | TEXT? | v8 — catalog metadata |
| secondary_muscle | TEXT? | v8 — catalog metadata |
| instructions | TEXT? | v8 — JSON `string[]` |
| tips | TEXT? | v8 — JSON `string[]` |
| faqs | TEXT? | v8 — structured JSON `[{"q","a"},…]` (raw text fallback when unparseable) |
| keywords | TEXT? | v8 — JSON `string[]` |
| image_path | TEXT? | v8 — bundled asset path |
| video_path | TEXT? | v8 — bundled asset path |
| created_at | INTEGER | epoch milliseconds |

### workouts

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| date | INTEGER | epoch milliseconds |
| started_at | INTEGER? | nullable, set when workout begins |
| completed_at | INTEGER? | nullable, set when workout ends |
| notes | TEXT? | nullable |
| created_at | INTEGER | epoch milliseconds |

### workout_exercises

Links exercises to workouts with ordering.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| workout_id | TEXT FK → workouts | |
| exercise_id | TEXT FK → exercises | |
| sort_order | INTEGER | display order within workout |
| notes | TEXT? | v17 — exercise-level free-text note (active-workout card) |

### exercise_sets

Individual sets within a workout exercise. Supports both weightlifting (reps/weight) and cardio (duration/distance).

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| workout_exercise_id | TEXT FK → workout_exercises | |
| set_number | INTEGER | 1-based |
| reps | INTEGER? | planned reps (weightlifting) |
| weight_kg | REAL? | planned weight (weightlifting) |
| rest_seconds | INTEGER? | v5 — planned rest between sets in seconds; required at the form level, nullable in DB |
| actual_reps | INTEGER? | actual reps (weightlifting) or actual duration in minutes (cardio) |
| actual_weight_kg | REAL? | actual weight (weightlifting) |
| actual_rest_seconds | INTEGER? | v5 — actual rest taken after the set in seconds; null until a rest period starts and ends/cancels |
| completed_at | INTEGER? | v7 — epoch millis when the set's actuals were recorded (set done); null for planned-only sets |
| duration_minutes | INTEGER? | planned duration (cardio) |
| distance_meters | REAL? | planned distance (cardio) |
| notes | TEXT? | |

## Planner tables

### planner_items

Per-day planner tasks (daily todo list). Standalone table — no foreign keys.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| date | INTEGER | start-of-day epoch milliseconds (normalized `DateTime(y,m,d)`) |
| title | TEXT | |
| done | INTEGER | `0` or `1` |
| sort_order | INTEGER | display order within the day |
| due_date | INTEGER? | v3 — optional due date, epoch milliseconds |
| due_time_minutes | INTEGER? | v8 — optional due time-of-day, minutes since midnight |
| notes | TEXT? | v6 — optional free-text note |
| created_at | INTEGER | epoch milliseconds |

## Body metrics tables

### body_metrics

One row per day (keyed by start-of-day) holding optional weight and/or height. Added in v3.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| date | INTEGER | start-of-day epoch milliseconds |
| weight_kg | REAL? | optional |
| height_cm | REAL? | optional |
| created_at | INTEGER | epoch milliseconds |

## Experiments tables (v18)

### experiments

One row per self-tracking experiment. Added in v18.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| purpose | TEXT? | hypothesis / stated purpose |
| start_date | INTEGER | start-of-day epoch milliseconds (inclusive baseline start) |
| end_date | INTEGER? | null = open-ended |
| status | TEXT | `'planned' \| 'active' \| 'done' \| 'aborted'` (plain text, like `exercise_type`) |
| categories | TEXT | JSON `string[]` of linked categories: `workout \| diet \| body \| steps` |
| reminder_enabled | INTEGER (bool) | `NOT NULL DEFAULT 1` |
| reminder_time_minutes | INTEGER | minutes from midnight, `NOT NULL DEFAULT 1200` (20:00) |
| created_at | INTEGER | epoch milliseconds |

### experiment_checkins

Daily check-ins (rating 1–5 + optional note); one per experiment per day (unique constraint on `(experiment_id, day)`).

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| experiment_id | TEXT FK → experiments | |
| day | INTEGER | start-of-day epoch milliseconds |
| rating | INTEGER | 1..5 scale |
| note | TEXT? | optional |
| created_at | INTEGER | epoch milliseconds |
| UNIQUE(experiment_id, day) | | one check-in per experiment per day; repo `upsertCheckin` replaces in place |

## Key patterns

- All primary keys are UUID v7 strings (generated via the `uuid` package).
- Timestamps are stored as epoch milliseconds (integers) and converted to `DateTime` in domain models.
- `exercise_type` is stored as plain text rather than an enum to keep the schema simple.
- Schema version is 18. `AppDatabase` defines an explicit `MigrationStrategy`: `onCreate` runs `createAll()` (fresh installs); `onUpgrade` runs stepwise:
  - v1 → v2: creates `planner_items`.
  - v2 → v3: adds nullable `sodium_per100g`/`fiber_per100g`/`sugar_per100g` to `ingredients`, adds nullable `due_date` to `planner_items`, creates `body_metrics`, and deletes orphaned `meal_ingredients` rows (rows whose `meal_id` has no matching `meals` row — leftover from the pre-T02 new-meal bug). No data is dropped.
  - v3 → v4: adds `is_archived` to `ingredients` (`NOT NULL DEFAULT 0` — ingredient soft-archive). No data is dropped.
  - v4 → v5: adds nullable `rest_seconds` and `actual_rest_seconds` to `exercise_sets` (planned + actual rest per set). No data is dropped.
  - v5 → v6: adds nullable `notes` to `planner_items` (free-text task notes, app-polish-batch T04). No data is dropped.
  - v6 → v7: adds nullable `completed_at` to `exercise_sets` (set completion timestamp, app-polish-batch T08). No data is dropped.
  - v7 → v8: adds the catalog metadata columns to `exercises` (`is_locked`, `body_part`, `equipment`, `primary_muscle`, `secondary_muscle`, `instructions`, `tips`, `faqs`, `keywords`, `image_path`, `video_path`) and `due_time_minutes` to `planner_items`. No data is dropped.
  - v8 → v9: creates the free-form `notes` table (Notes tab). No data is dropped.
  - v9 → v10: adds the exercise canonicalization fields to `exercises` (`similar_to`, `tags`, `is_canonical`). No data is dropped.
  - v10 → v11: adds nullable `workout_id` to `planner_items` (planner workout linking). No data is dropped.
  - v11 → v12: adds nullable `tags` (JSON `string[]`) to `planner_items`. No data is dropped.
  - v12 → v13: adds `recurrence` (rule JSON) and `series_id` to `planner_items` (recurring tasks). No data is dropped.
  - v13 → v14: creates the budget tables — `accounts`, `transactions`, `receipts`, `fx_rates`. No data is dropped.
  - v14 → v15: adds `start_time_minutes`/`end_time_minutes` to `planner_items` (replaces the single due time); carries existing `due_time_minutes` into `start_time_minutes`. No data is dropped.
  - v15 → v16: adds nullable `actual_duration_minutes`/`actual_distance_meters` to `exercise_sets` (logged cardio actuals); carries existing effective duration/distance into the new actual columns. No data is dropped.
  - v16 → v17: adds nullable `notes` to `workout_exercises` (exercise-level note, active-workout redo T01). No data is dropped.
  - v17 → v18: creates the `experiments` + `experiment_checkins` tables (experiments tab). New tables only — no existing-table changes. No data is dropped.

## Generated code

Drift generates `app_database.g.dart` — table info classes, data classes (row classes), companions, and the `$AppDatabase` base class. All drift output is combined into this single part file (there is no `tables.g.dart`).

Build command: `flutter pub run build_runner build` (must run through `flutter pub`, not `dart run`, in the Nix environment).

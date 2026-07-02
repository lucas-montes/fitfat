# FitFat — Database Schema

7 tables defined in `lib/src/database/tables.dart` with Drift `@DataClass`.

## Diet tables

### ingredients

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| calories_per_100g | REAL | |
| protein_per_100g | REAL | |
| carbs_per_100g | REAL | |
| fat_per_100g | REAL | |
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

### exercise_sets

Individual sets within a workout exercise. Supports both weightlifting (reps/weight) and cardio (duration/distance).

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| workout_exercise_id | TEXT FK → workout_exercises | |
| set_number | INTEGER | 1-based |
| reps | INTEGER? | planned reps (weightlifting) |
| weight_kg | REAL? | planned weight (weightlifting) |
| actual_reps | INTEGER? | actual reps (weightlifting) or actual duration in minutes (cardio) |
| actual_weight_kg | REAL? | actual weight (weightlifting) |
| duration_minutes | INTEGER? | planned duration (cardio) |
| distance_meters | REAL? | planned distance (cardio) |
| notes | TEXT? | |

## Key patterns

- All primary keys are UUID v7 strings (generated via the `uuid` package).
- Timestamps are stored as epoch milliseconds (integers) and converted to `DateTime` in domain models.
- `exercise_type` is stored as plain text rather than an enum to keep the schema simple.
- The database uses Drift's `MigrateOnStartup` strategy (tables created automatically on first run).

## Generated code

Drift generates:
- `tables.g.dart` — table info classes, data classes (row classes), companions
- `app_database.g.dart` — the `$AppDatabase` base class with DAO methods

Build command: `flutter pub run build_runner build`

# FitFat — Database Schema

37 tables defined in `lib/src/database/tables.dart`. Drift generates row classes, companions, and table info classes using default singularization (no `@DataClass` annotations).

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
| brand | TEXT? | v20 — shopping metadata |
| barcode | TEXT? | v20 — as printed on the package; indexed via `idx_ingredients_barcode` (created idempotently in `beforeOpen`, so fresh installs and every upgrade path converge) |
| created_at | INTEGER | epoch milliseconds |

### stores

Shopping stores prices can be recorded at (v20).

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| created_at | INTEGER | epoch milliseconds |

### ingredient_pictures

Multiple pictures per ingredient (like receipts; v20).

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| ingredient_id | TEXT FK → ingredients | |
| image_path | TEXT | local filesystem path (`<docs>/ingredient_pictures/<uuid>.ext`) |
| sort_order | INTEGER | gallery ordering; renumbered densely on reorder |
| created_at | INTEGER | epoch milliseconds |

### foods

A food is a named recipe: a collection of ingredients with amounts. Introduced in v34, replacing `ingredient_components`. It holds **no nutrition columns of its own** — see `Food` for why.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7; derived foods use `"i:" + ingredientId` |
| name | TEXT | copied from the ingredient for derived foods, free-text for user recipes |
| created_at | INTEGER | epoch milliseconds |
| archived_at | INTEGER? | set when archived; the row is kept so logged meals keep resolving |

### food_ingredients

The composition of a food (v34). Composite PK `(food_id, ingredient_id)`, so the same ingredient cannot appear twice in one food — the schema enforces it rather than the repository.

| Column | Type | Notes |
|--------|------|-------|
| food_id | TEXT PK/FK → foods | `ON DELETE CASCADE` |
| ingredient_id | TEXT PK/FK → ingredients | **no cascade** — a part is never implicitly detached |
| amount | REAL | absolute amount in the batch; the sum is the denominator of the food per-100g figures |

No `sort_order`: components carry no meaningful order and are presented alphabetically by ingredient name.

**Foods carry no macros.** `food_per100g = Σ(ingredient.per100g × amount) / Σ(amount)`, resolved on every read by `food_nutrition.dart`. A stored copy would go stale the moment an ingredient is edited.

**Derived foods.** Every ingredient gets a 1:1 food (`id = "i:" + ingredientId`) with one component at `amount = 100`, so it stays individually loggable. `IngredientRepository` is the only writer; `FoodRepository` rejects derived ids so the pair cannot drift.

### ingredient_prices

Price history per ingredient per store (v20) — enables "same product sold at different stores" tracking and cost-per-100g.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| ingredient_id | TEXT FK → ingredients | |
| store_id | TEXT FK → stores | renames of the store propagate to all price rows |
| price | REAL | in the currency it was observed in |
| currency_code | TEXT | ISO-4217-ish, same semantics as transactions |
| package_grams | REAL? | null when unknown — cost-per-100g cannot be computed then |
| recorded_at | INTEGER | start-of-day epoch milliseconds |
| created_at | INTEGER | epoch milliseconds |
| UNIQUE(ingredient_id, store_id, recorded_at) | | one observation per product/store/day; repo `upsertPrice` replaces in place |

### meals

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | e.g. "Lunch" |
| eaten_at | INTEGER | epoch milliseconds |
| created_at | INTEGER | epoch milliseconds |

### meal_foods

One food logged in a meal, with the portion snapshot (v34). Replaces `meal_ingredients`.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| meal_id | TEXT FK → meals | `ON DELETE CASCADE` |
| food_id | TEXT FK → foods | **no cascade** — an archived food stays referenced so its snapshot keeps rendering |
| amount | REAL | grams of this food eaten |
| calories, protein, carbs, fat | REAL | **snapshot of the portion**, resolved at log time and read verbatim |
| sodium, fiber, sugar | REAL? | nullable; null only when no component ever provided a value |

The snapshot makes history reads flat — a meal is replayed without touching the ingredient graph, and the dashboard total is one `SUM`. It is a cache rather than an independent record: `MealResnapshot` re-derives the affected rows when an ingredient or a food changes, so editing one does move the numbers on meals already logged. A food that stops resolving is left at its last known figures rather than zeroed. The food **name** is deliberately not snapshotted — it is joined live, so renaming a recipe shows up in old meals.

## Exercise tables

### exercises

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| name | TEXT | |
| exercise_type | TEXT | `'weightlifting'` or `'cardio'` |
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
| routine_id | TEXT? | v21 — replay lineage shared by all occurrences of the same routine (indexed via `idx_workouts_routine`, created idempotently in `beforeOpen`); null when never replayed |
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

### tasks

Per-day planner tasks. The table was called `planner_items` until v25, when
experiments moved back out into their own tables and the remaining rows were
renamed to `tasks`. Experiments were removed entirely in v37 (see below).
Standalone table — no foreign keys.

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID v7 |
| date | INTEGER | start-of-day epoch milliseconds (normalized `DateTime(y,m,d)`) |
| title | TEXT | |
| done | INTEGER | `0` or `1`; kept in sync with `task_status` (`done == task_status == 1`) |
| task_status | INTEGER? | v25 — `0` pending \| `1` done \| `2` cancelled |
| carry_over | INTEGER (bool) | v25 — `NOT NULL DEFAULT 1`; pending tasks move to today, otherwise roll over to cancelled |
| sort_order | INTEGER | display order within the day |
| due_date | INTEGER? | v3 — optional due date, epoch milliseconds |
| due_time_minutes | INTEGER? | v8 — optional due time-of-day (retained; new tasks use start/end below) |
| notes | TEXT? | v6 — optional free-text note |
| start_time_minutes / end_time_minutes | INTEGER? | v15 — optional time-of-day span, minutes since midnight |
| workout_id | TEXT? | v11 — linked workout |
| workout_template_id | TEXT? | v28 — template occurrence that generated the task |
| recurrence | TEXT? | v13 — repeat rule JSON |
| series_id | TEXT? | v13 — groups occurrences of one recurring series |
| created_at | INTEGER | epoch milliseconds |
| deleted_at | INTEGER? | v36 — soft-delete tombstone, pushed to the server |

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

## Experiments (removed in v37)

The experiments feature was deleted from the app, server and desktop UI. v37
drops its tables (`experiment_checkins`, `experiment_tags`, `task_experiments`,
`experiment_goals`, `experiment_notes`, `experiments`) with
`DROP TABLE IF EXISTS`, so devices that skipped an intermediate version still
land on the same schema. No code reads or writes them any more.

## Key patterns

- All primary keys are UUID v7 strings (generated via the `uuid` package).
- Timestamps are stored as epoch milliseconds (integers) and converted to `DateTime` in domain models.
- `exercise_type` is stored as plain text rather than an enum to keep the schema simple.
- Schema version is 37. `AppDatabase` defines an explicit `MigrationStrategy`: `onCreate` runs `createAll()` (fresh installs); `beforeOpen` idempotently creates the barcode, routine and recipe-component lookup indexes; `onUpgrade` runs stepwise:
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
  - v18 → v19: adds nullable `manual` to `fx_rates` (`NOT NULL DEFAULT 0` — flags rates set by hand, fx-display T01). No data is dropped.
  - v19 → v20: adds nullable `brand`/`barcode` to `ingredients` and creates `stores`, `ingredient_pictures`, `ingredient_prices` (ingredient-metadata T01). New tables + additive columns only — no data is dropped.
  - v20 → v21: adds nullable `routine_id` to `workouts` (replay lineage, workout-replay T01; indexed in `beforeOpen`). Additive column only — no data is dropped.
  - v21 → v22: rebuilds `fx_rates` around a daily-snapshot dimension — adds `rate_date` (`'YYYY-MM-DD'`, default `'0001-01-01'`) and a composite PK `(code, base_code, rate_date)` so sync can keep per-day history instead of overwriting the latest rate. Existing rows are backfilled as a single `'0001-01-01'` snapshot. No data is dropped.
  - v22 → v23: drops `exercises.is_locked` (the bundled exercise catalog is gone — data now arrives via the sync client). Drift cannot drop a column in place, so `exercises` is rebuilt via rename → recreate → backfill → drop-old. Only the dead column is removed.
  - v23 → v24: folds experiments into `planner_items` — adds `kind` (`'task'` default), `end_date`, `purpose`, `status`, `categories` (JSON), `reminder_enabled`, `reminder_time_minutes`, and child-link `experiment_id`; copies each `experiments` row into a `planner_items` row **preserving ids** (`date = start_date`, open-ended rows get `end_date = start_date + 7d`); rebuilds `experiment_checkins` without its FK to the dropped table; then drops `experiments`. No data is lost.
  - v24 → v30: (undocumented here — see `lib/src/database/app_database.dart` `onUpgrade`: tasks/goals/tags/templates/link-table + note-audio steps).
  - v30 → v31: creates the selective-sync catalog tables — `exercise_catalog` (`id`, `name`) and `ingredient_catalog` (`id`, `name`, nullable `barcode`). New tables only — no existing-table changes. No data is dropped.
  - v31 → v32: adds `has_image` (`NOT NULL DEFAULT 0`) to `exercise_catalog` so the picker can skip thumbnail fetches for imageless rows. Additive column only — no data is dropped.
  - v32 → v33: creates `ingredient_components` for composite (recipe) ingredients. Superseded by v34 below.
  - v33 → v34: **destructive and intentional.** Replaces the composite-ingredient design with `meal → food → ingredient`: creates `foods`, `food_ingredients` and `meal_foods` (carrying a portion macro snapshot), and drops `ingredient_components` and `meal_ingredients`. Existing meals and recipes are not carried over — the user confirmed there is nothing to migrate.
  - v34 → v35: backfills `sodium`/`fiber`/`sugar` to `0` wherever they are null (`ingredients` and `meal_foods`). The columns stay nullable in SQLite but the Dart getters are non-nullable; no table rebuild.
  - v35 → v36: adds a nullable `deleted_at` tombstone to every top-level personal entity (`meals`, `workouts`, `workout_templates`, `tasks`, `notes`, `goals`, `body_metrics`, `accounts`, `transactions`, `receipts`). Local deletes stamp the row instead of removing it, so a push can report the deletion. Children follow their parent's liveness and carry no marker of their own.
  - v36 → v37: creates the `sync_deletes` outbox (hard-deleted child ids awaiting push) and drops the experiments tables (`experiment_checkins`, `experiment_tags`, `task_experiments`, `experiment_goals`, `experiment_notes`, `experiments`) now that the feature is gone. New table + dropped tables only — no data loss beyond the removed feature.

## Selective-sync catalog tables (v31)

Lightweight available-data index for selective import (selective-sync-catalog T01). No FK to user tables; no media stored here (picker thumbnails are live server fetches; offline assets are written only on bulk sync / selective import).

### exercise_catalog

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | server row id |
| name | TEXT | display name |
| has_image | INTEGER (bool) | v32 — server `has_image` hint; picker skips thumbnail fetch when false |

### ingredient_catalog

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | server row id |
| name | TEXT | display name |
| barcode | TEXT? | nullable — selective match key alongside name |

Repositories (`lib/src/sync/repositories/catalog_repository.dart`): `getAll` (name-ordered), `upsertAll` (whole-cache replace in one batch transaction), `clear`, and `searchHideImported(query)` — a single SQL query (`NOT IN` subquery against `exercises` / `ingredients`, `LIKE ... ESCAPE '\'` matching picker `contains` semantics) returning picker-ready rows (ingredient subtitle = barcode, no stored image paths; exercise entries carry `hasImage`, added to the table in v32).

## Sync outbox (v37)

### sync_deletes

Tombstones for rows that are **hard-deleted** locally and therefore have no
row left to carry a `deleted_at`. Repositories insert here in the same
transaction as the delete; `DataPushService` drains the matching entity rows
into the push payload and clears them only after the server acknowledges.

| Column | Type | Notes |
|--------|------|-------|
| entity | TEXT | local table name: `workouts`, `workoutExercises`, `exerciseSets`, `workoutTemplates`, `workoutTemplateExercises`, `workoutTemplateSets`, `exercises` |
| id | TEXT | deleted row id |
| deleted_at | INTEGER | epoch milliseconds, diagnostic only |

Composite PK `(entity, id)`. Top-level rows (workout/template/task/note/…)
instead use their own `deleted_at` column, which rides the pushed row itself.
Undo (`WorkoutRepository.restore`) clears the matching outbox rows so a
restored child is not announced as deleted.

## Generated code

Drift generates `app_database.g.dart` — table info classes, data classes (row classes), companions, and the `$AppDatabase` base class. All drift output is combined into this single part file (there is no `tables.g.dart`).

Build command: `flutter pub run build_runner build` (must run through `flutter pub`, not `dart run`, in the Nix environment).

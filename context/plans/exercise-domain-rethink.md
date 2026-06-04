# Exercise Domain Rethink: Unified Activity Model + Planning

## Change Summary

Rethink the exercise module from a weights-only "seance" system into a **unified activity model** supporting weightlifting, cardio, and freeform activities. Replace the "Workouts" tab with a **"Training" tab** that combines planning (weekly calendar), timeline (what you did), and history. Introduce **quick-log** for spontaneous sessions and **planned workouts** for coach-scheduled or self-scheduled sessions with prescribed weights.

The existing `Seance`/`seance` internal naming is preserved for backward compatibility but the user-facing and conceptual model shifts to `Workout`.

---

## Model Architecture

```mermaid
erDiagram
    EXERCISES {
        string id PK
        string name "e.g. Bench Press, Swimming, Skateboarding"
        string category "Chest, Back, Legs, Cardio, Sport..."
        string type "weightlifting | cardio"
        float met "MET value for calorie estimation"
        string creator_id "nullable"
    }

    WORKOUTS {
        string id PK
        string name "e.g. Saturday Fun, Push Day"
        datetime start_time "when session started"
        datetime end_time "nullable"
        string notes "nullable"
        string source "coach | manual | quick_log"
        string planned_workout_id "nullable → links to PLANNED_WORKOUTS"
        boolean is_guided "was this a guided template workout?"
    }

    WORKOUT_ENTRIES {
        string id PK
        int sort_order
        string exercise_id FK "NOT NULL → links to EXERCISES"
        string workout_id FK
        string note "nullable, per-entry notes"
        int effort "nullable, 1-10 scale"
    }

    SETS {
        string id PK
        string entry_id FK
        int reps
        float weight_kg
        datetime completed_at "nullable"
    }

    CARDIO_DETAILS {
        string id PK
        string entry_id FK "1-to-1"
        int duration_minutes
    }

    PLANNED_WORKOUTS {
        string id PK
        date scheduled_date
        string name
        string notes "nullable"
        string source "coach | from_template | manual"
        string template_id "nullable → FK to TEMPLATES, reference only"
        boolean is_completed "default false"
        string completed_workout_id "nullable → links to WORKOUTS"
    }

    PLANNED_ENTRIES {
        string id PK
        string planned_workout_id FK
        string exercise_id FK
        int sort_order
        int planned_reps
        float planned_weight_kg
        int planned_rest_seconds "nullable"
        string note "nullable"
        int effort_target "nullable, 1-10"
    }

    PLANNED_CARDIO {
        string id PK
        string planned_entry_id FK "1-to-1"
        int planned_duration_minutes
    }

    TEMPLATES {
        string id PK
        string name
        string notes "nullable"
    }

    TEMPLATE_EXERCISES {
        string id PK
        string template_id FK
        string exercise_id FK
        int sort_order
    }

    TEMPLATE_SETS {
        string id PK
        string template_exercise_id FK
        int reps
        float weight_kg "nullable"
        int rest_seconds
    }

    EXERCISES ||--o{ WORKOUT_ENTRIES : referenced
    WORKOUTS ||--o{ WORKOUT_ENTRIES : contains
    WORKOUT_ENTRIES ||--o{ SETS : "type = weightlifting"
    WORKOUT_ENTRIES ||--o| CARDIO_DETAILS : "type = cardio"
    PLANNED_WORKOUTS ||--o{ PLANNED_ENTRIES : prescribes
    PLANNED_ENTRIES ||--o| PLANNED_CARDIO : "type = cardio"
    PLANNED_WORKOUTS ||--o| WORKOUTS : completed
    TEMPLATES ||--o{ TEMPLATE_EXERCISES : defines
    TEMPLATE_EXERCISES ||--o{ TEMPLATE_SETS : structures
```

### Key design decisions
- **`exercise_id` is NOT NULL** on `workout_entries` — every logged activity references the exercise library
- **Exercise `type`** (weightlifting | cardio) determines whether the entry gets `sets` or `cardio_details`
- **`effort`** lives on `workout_entry` (not type-specific) — useful for both weightlifting and cardio
- **MET** on exercises enables calorie estimation from duration
- **Templates** stay as copyable presets — no FK link to planned workouts; you copy from template when creating a planned workout
- **Planned entries** have their own set/cardio tables so prescribed weights live independently of logged weights
- **Quick-log** = create a `WORKOUT` with source `quick_log` and a single entry — no plan involved

---

## Success Criteria

- A user can log any activity type (swim, skate, run, bench press, yoga) in under 10 taps
- Planned workouts show on a weekly calendar with prescribed weights from coach
- Starting a planned workout pre-fills the active session with prescribed weights
- Templates can be used to bootstrap new planned workouts
- The Training tab shows: start/resume card, weekly calendar, timeline, and history
- Existing data (old seances) is migrated and viewable in the new model
- Stats tab still works (heatmap, volume, 1RM for weightlifting data)

---

## Constraints and Non-Goals

- Non-goal: heart rate monitoring integration (first version)
- Non-goal: GPS route tracking for outdoor cardio
- Non-goal: Social features, sharing, leaderboards
- Non-goal: Complex periodization auto-progression engine
- Non-goal: Removing the old `Seance` class names from internal code (backward compat)
- Data migration must not lose existing completed workouts
- Must remain offline-first, single-user

---

## Phases and Tasks

### Phase A: Data Model Foundation

- [ ] T01: `Extend exercises table with type + MET + seed cardio exercises` (status:todo)
  - **Task ID**: T01
  - **Goal**: Add `type` (weightlifting/cardio) and `met` (float) columns to the Drift `exercises` table. Seed initial cardio/sport exercises (Swimming, Running, Cycling, Skateboarding, Football, Yoga, Walking, Hiking, Rowing, Jump Rope) with MET values.
  - **Boundaries**: In - schema migration, seed data. Out - any UI changes, provider changes.
  - **Done when**: New columns exist in DB schema; seed migration populates cardio exercises; existing exercises get `type='weightlifting'` with default MET; `flutter test` passes.
  - **Verification**: Check DB schema via Drift; verify new exercises in app exercise list; run existing tests.

- [ ] T02: `Create workouts + workout_entries + sets + cardio_details tables` (status:todo)
  - **Task ID**: T02
  - **Goal**: Add new Drift tables: `workouts`, `workout_entries`, `sets`, `cardio_details`. The old `seances`, `exercise_entries`, `exercise_sets` tables remain untouched for now (dual-write/migration in later task). New tables mirror the model architecture above.
  - **Boundaries**: In - new table definitions, Drift codegen. Out - any reads/writes to new tables, UI changes.
  - **Done when**: Drift generates classes for all 4 new tables; `flutter analyze` passes; `flutter test` passes.
  - **Verification**: Check generated Drift classes exist; `flutter analyze` clean; tests pass.

- [ ] T03: `Create planned_workouts + planned_entries + planned_cardio tables` (status:todo)
  - **Task ID**: T03
  - **Goal**: Add Drift tables for planning: `planned_workouts`, `planned_entries`, `planned_cardio`.
  - **Boundaries**: In - table definitions only. Out - UI for planning, scheduling logic.
  - **Done when**: Tables exist in schema; Drift codegen completes; `flutter analyze` passes.
  - **Verification**: Generated classes present; `flutter analyze` clean.

### Phase B: Data Migration + Domain Models

- [ ] T04: `Update domain models for new activity model` (status:todo)
  - **Task ID**: T04
  - **Goal**: Create/update Dart domain model classes: `Workout`, `WorkoutEntry`, `WeightSet`, `CardioDetail`, `PlannedWorkout`, `PlannedEntry`, `PlannedCardio`. Update `ExerciseDefinition` to include `type` and `met`. Keep old `Seance`/`ExerciseEntry`/`ExerciseSet` classes for backward compat during migration.
  - **Boundaries**: In - model classes, JSON serialization, copyWith. Out - providers, UI.
  - **Done when**: All new models defined with `toJson`/`fromJson`; old models untouched; `flutter analyze` passes.
  - **Verification**: `flutter analyze` clean; unit tests for model serialization.

- [ ] T05: `Write migration adapter from Seance → Workout` (status:todo)
  - **Task ID**: T05
  - **Goal**: Write pure Dart function(s) that convert old `Seance` objects to new `Workout` objects. Map exercise entries to workout entries, sets to weight sets. Cardio-type exercises get a default `CardioDetail` with 0 duration (prompts user to fill in later or in a follow-up migration). Build T05 on the dual-read approach: the system reads from old tables for now but can also produce new model objects.
  - **Boundaries**: In - conversion logic, test coverage. Out - writing to new tables, DB migration.
  - **Done when**: All old seance scenarios convert correctly (empty seance, guided, freeform, with/without completed sets); tests pass.
  - **Verification**: Unit tests covering conversion edge cases.

- [ ] T06: `Write data migration: copy old seances to new tables` (status:todo)
  - **Task ID**: T06
  - **Goal**: Write a one-time Drift migration that reads from old tables (`seances`, `exercise_entries`, `exercise_sets`) and inserts into new tables (`workouts`, `workout_entries`, `sets`, `cardio_details`). Cardio-type exercises in old data get `cardio_details` with 0 duration. Runs on app startup once.
  - **Boundaries**: In - DB migration function, migration version bump, guard flag to run once. Out - dropping old tables.
  - **Done when**: Running the migration produces identical workout data in new tables; all old data preserved; tests verify round-trip fidelity.
  - **Verification**: Unit test: insert old-style data → run migration → verify new table contents. Manual: check history shows same workouts after migration.

### Phase C: Provider Rewrite

- [ ] T07: `Rewrite active workout provider to use new model` (status:todo)
  - **Task ID**: T07
  - **Goal**: Rewrite `ActiveSeanceNotifier` → `ActiveWorkoutNotifier`. Uses `Workout` domain model. Supports both weightlifting (with sets) and cardio entries. Persists via SharedPreferences JSON like before. Can start from a `PlannedWorkout` (pre-filling prescribed weights). Add `quickLogWorkout(name, type, duration)` method.
  - **Boundaries**: In - provider rewrite, SharedPreferences persistence, planned-workout pre-fill. Out - UI changes, template integration.
  - **Done when**: Can start/work/complete a workout with mixed weightlifting + cardio entries; quick-log creates a single-entry workout; pre-fill from planned workout works; existing tests adapted and pass.
  - **Verification**: Provider unit tests; manual: start workout, add bench press sets, add swimming entry, complete, verify history.

- [ ] T08: `Rewrite history provider to use new model` (status:todo)
  - **Task ID**: T08
  - **Goal**: Rewrite `SeanceHistoryNotifier` → `WorkoutHistoryNotifier`. Loads from new `workouts` table. Returns `List<Workout>`. Filters by date range for timeline view. Exposes aggregate stats (volume by exercise, cardio minutes by week) from the new model.
  - **Boundaries**: In - provider rewrite, query logic, aggregate stats. Out - UI, stats tab integration.
  - **Done when**: History loads from new tables; old history provider still works for backward compat; tests pass.
  - **Verification**: Provider unit tests; manual: verify completed workouts appear in history.

- [ ] T09: `Create planned workout provider` (status:todo)
  - **Task ID**: T09
  - **Goal**: New provider `PlannedWorkoutProvider` managing `List<PlannedWorkout>`. CRUD operations (create from template, create manually, edit, delete, mark complete). Loads by week for calendar view. Links completed workout to planned workout.
  - **Boundaries**: In - provider, CRUD logic, date-range queries. Out - UI scheduling screens.
  - **Done when**: Can create/edit/delete planned workouts; can mark complete and link to real workout; tests pass.
  - **Verification**: Unit tests for all CRUD operations; date-range filtering.

### Phase D: UI — Training Tab

- [ ] T10: `Build Training tab layout` (status:todo)
  - **Task ID**: T10
  - **Goal**: Replace the old `SeancesHistoryTab` with a new `TrainingTab`. Structure from top to bottom: (1) Start workout card — shows "Follow today's plan" if a planned workout exists for today, or "Start workout" otherwise, plus a "Quick log" pill button; (2) Weekly calendar strip (7 days, swipeable) showing planned workouts per day; (3) Timeline — today's activities (planned + completed) grouped, then previous days; (4) History — paginated list of past workouts (same as old history card but uses new model).
  - **Boundaries**: In - tab layout, calendar strip widget, timeline widget, history list. Out - editing planned workouts from calendar, quick-log flow (separate task).
  - **Done when**: Training tab renders with all 4 sections; planned workouts visible on calendar; timeline shows today's entries; history shows past workouts.
  - **Verification**: Manual visual check; widget tests for each section.

- [ ] T11: `Refactor active workout screen for mixed activity types` (status:todo)
  - **Task ID**: T11
  - **Goal**: Update the active workout screen (was `CurrentSeanceScreen`) to handle mixed entry types. Weightlifting entries show set cards (reps/weight) with rest timer. Cardio entries show a duration log with start/stop or manual entry. Entries display with type-specific icons (dumbbell vs running figure). Exercise picker now shows both weightlifting and cardio exercises with type badges.
  - **Boundaries**: In - UI updates for mixed entry types, exercise picker filter by type, entry-type-specific cards. Out - quick-log flow, planned workout integration.
  - **Done when**: Active workout can contain both set-based and duration-based entries; UI correctly renders each type; rest timer only shows for weightlifting entries.
  - **Verification**: Manual: start workout, add bench press (see set cards), add swimming (see duration entry), verify both render and save correctly.

- [ ] T12: `Add quick-log flow` (status:todo)
  - **Task ID**: T12
  - **Goal**: When user taps "Quick log" (from Training tab or FAB), show a bottom sheet or minimal screen: pick exercise (or type name), select type (uses exercise default or manual override), enter duration (for cardio) or sets/reps/weight (for weightlifting), optional notes. Saves as a `Workout` with source `quick_log` and a single `WorkoutEntry`. Appears in timeline immediately.
  - **Boundaries**: In - quick-log sheet/UI, save flow, timeline refresh. Out - editing quick-logged entries, multiple entries per quick-log.
  - **Done when**: Quick-log saves a workout with one entry in < 5 taps; appears in timeline; works for both weightlifting and cardio.
  - **Verification**: Manual: quick-log "Swimming 30 min" → verify in timeline; quick-log "Bench Press 3x10@50kg" → verify in timeline.

### Phase E: Planning UI

- [ ] T13: `Build planned workout scheduling UI` (status:todo)
  - **Task ID**: T13
  - **Goal**: When user taps a day on the weekly calendar strip, show a detail panel: existing planned workout (if any) or "Add planned workout". Creating: pick name, pick exercises + sets + weights (prescribed), schedule for date. Option to "Copy from template" → shows template picker → copies template exercises/sets as starting point. Edit/delete planned workouts. Mark complete → starts the workout pre-filled.
  - **Boundaries**: In - scheduling panel, planned workout CRUD UI, template copy flow, pre-fill start. Out - template creation UI (uses existing), coach import.
  - **Done when**: Can schedule a planned workout on any date; can copy from template; can edit/delete/mark complete; starting a planned workout pre-fills weights.
  - **Verification**: Manual: plan workout for tomorrow → see it on calendar → start it → verify weights pre-filled.

- [ ] T14: `Add source tracking and coach attribution to workouts` (status:todo)
  - **Task ID**: T14
  - **Goal**: Wire up the `source` field end-to-end. Planned workouts from coach show a coach badge/icon. Quick-logged workouts show a lightning bolt icon. Manual workouts show a pencil icon. Planned workouts show the source in the detail view. Future-proof the `source` field for coach name/ID.
  - **Boundaries**: In - source badge UI, detail view source display. Out - actual coach import/sync mechanism.
  - **Done when**: Workout cards show source icon; planned workout detail shows "from coach" or "from template" attribution.
  - **Verification**: Manual check of workout cards in timeline and history.

### Phase F: Stats Adaptation

- [ ] T15: `Update stats tab for new model` (status:todo)
  - **Task ID**: T15
  - **Goal**: Update stats providers and UI to read from new `workouts`/`workout_entries`/`sets` tables. Weightlifting stats (volume, 1RM, max weight) continue working. Add cardio stats: total duration per week, duration by exercise type, cardio heatmap overlay. Heatmap now colors any day with activity (not just weightlifting sessions).
  - **Boundaries**: In - provider rewrites for new tables, cardio stats, unified heatmap. Out - new chart types, detailed cardio analytics.
  - **Done when**: All existing weightlifting stats work with new tables; cardio duration stats appear; heatmap shows all activity days.
  - **Verification**: Manual: compare old stats with new stats for weightlifting data; verify cardio activities appear in stats.

### Phase G: Cleanup

- [ ] T16: `Validation and cleanup` (status:todo)
  - **Task ID**: T16
  - **Goal**: Run full test suite, fix any failures. Remove temporary backward-compat code (old providers if fully migrated). Verify no dead code paths. Update context files (overview.md, glossary.md, context-map.md, exercise domain docs) to reflect new model. Audit for any remaining old terminology in user-facing strings.
  - **Boundaries**: In - test pass, dead code removal, context sync. Out - new features.
  - **Done when**: `flutter test` passes; `flutter analyze` clean; context files synced with current state.
  - **Verification**: `flutter test`, `flutter analyze`, manual review of context docs.

---

## Open Questions

- Template → PlannedWorkout copy: should it deep-copy (including weights) or only copy structure (exercises + set counts, leave weights blank)?
- Coach integration: wire protocol for importing planned workouts (placeholder for now, source field ready)
- Effort scale: 1-10 validated? Or free text? 1-10 is assumed for now.
- Cardio auto-duration: should there be a start/stop timer for cardio entries in the active workout screen, or only manual entry? First version = manual entry.

---

## How to Start

```bash
/next-task exercise-domain-rethink T01
```

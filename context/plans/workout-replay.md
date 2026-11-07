# Plan: Workout replay + session count tracking (Phase WR)

## Change Summary

Replace the "re-copy each time" flow with a real **replay** concept
(review 2026-08-19):

1. **Lineage**: workouts gain a `routineId` (schema v21) shared by all
   occurrences of the same routine, so replays stay linked and "times done"
   is countable.
2. **Replay** (not copy): from the completed-workout summary or the workout
   tile menu, create the next occurrence prefilled from the **previous
   completion's actuals** (or planned, per a new **setting**) so the next
   session starts where the last ended (progressive overload).
3. **Syncing progression to exercises**: actual values already live in each
   completed occurrence's sets; with history filtered to completed (active-workout
   T03) + the exercise-detail trends (exercise-detail-rework plan), progression
   surfaces on the exercises themselves — no dedicated routine screen this round.
4. The existing **Duplicate/Copy stays** as an independent, identity-fresh copy.

## Success Criteria

- Schema v21: `workouts.routine_id` (nullable TEXT, indexed) + migration;
  `flutter pub run build_runner build` regenerates.
- `replayWorkout` creates a new pending workout with the same exercises/sets,
  planned sets prefilled per the `settings_replay_prefill` value ('actuals' |
  'planned'), base name (trailing " #N" / " (Copy)" stripped), date = today, and
  the source's `routine_id` (a fresh UUID when the source has none).
- Replay is offered from the completed-workout summary ("Do again") and the
  workout tile menu; Duplicate/Copy still works; the new occurrence opens the
  editable workout form.
- Routine "done" count queryable per routine (grouped, single query).
- `flutter gen-l10n` exit 0; `flutter analyze lib/` clean; `flutter test`
  `+42 -4` (pre-existing sqlite env failures).

## Constraints & Non-Goals

- Schema bump v21 (after ingredient-metadata's v20).
- Non-goal: routine grouping/analytics screen, per-set Δ UI in replay (postponed
  to exercise-detail trends), automatic progressive-overload suggestions,
  server sync of lineages (see sync-contract plan).

## Task Stack

- [x] T01: `Schema v21 — workouts.routine_id + repository replay` (status:done)
  - Task ID: T01
  - Goal: Persist workout lineage and add the replay + count operations.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` — `Workouts.routineId` (TEXT?, indexed);
      `app_database.dart` (schemaVersion 21 + `from < 21` addColumn);
      build_runner; `WorkoutRepository`:
      `replayWorkout({required String sourceWorkoutId, String? prefill,
      DateTime? date})` — reads the source's completed sets, builds the new
      planned sets from actuals (or the source's planned when prefill !=
      'actuals' and actuals are absent it falls back to planned), strips
      trailing " #N"/" (Copy)" from the name, copies exercises/set metadata
      (note kept), assigns `routineId` (source's or fresh), `date` = today,
      inserts atomically, returns the new workout;
      `getRoutineCompletionCount(String routineId)` (single grouped `COUNT`
      over completed routines);
      `Workout`/`WorkoutWithDetails` domain gains `routineId`.
    - Out: UI (T02), settings state (T02).
  - Done when: replay inserts a correct lineage occurrence with prefilled plan,
    count query returns the completed total; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build --delete-conflicting-outputs`;
      `dart analyze lib/src/database/ lib/src/exercise/ lib/src/models/`.

- [x] T02: `Replay surface + replay-prefill setting` (status:done)
  - Task ID: T02
  - Goal: Offer Replay from summary + tile menu; add the prefill setting.
  - Boundaries (in/out of scope):
    - In: `SettingsState` + notifier gain `replayPrefill` (`'actuals'` default,
      `'planned'`), settings key `settings_replay_prefill`; Settings → General
      (or Workouts) dropdown; `workout_summary_screen.dart` AppBar action
      "Do again" → runs `replayWorkout` (reading the setting) and pushes the
      editable `WorkoutFormScreen` (initial = new occurrence) then invalidates
      `workoutListProvider`; `workout_list.dart` tile menu gains "Replay"
      (same flow) next to Duplicate; new l10n keys en/fr/es.
    - Out: pipeline from the tile directly into an active workout (form first).
  - Done when: Replay from both surfaces creates an editable prefilled
    occurrence; prefilled plan matches the setting; Duplicate still works;
    `flutter gen-l10n`; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/exercise/ lib/src/settings/`.

- [x] T03: `Validation and context sync` (status:done)
  - Task ID: T03
  - Goal: Full checks + document the replay model.
  - Boundaries (in/out of scope): in — build_runner, gen-l10n, analyze, format,
    tests, `context/database/schema.md` (v21), `context/exercise/` docs +
    `context/settings/settings.md`, glossary (routine/lineage), validation
    report; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+42 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - build_runner; gen-l10n; `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/exercise lib/src/settings lib/src/database lib/src/models`.

## Next Command

None — all tasks complete.

## Validation Report

- **Commands run:** `flutter pub run build_runner build
  --delete-conflicting-outputs` (regenerated `app_database.g.dart`),
  `flutter gen-l10n` (exit 0), `dart analyze lib` (no issues), `flutter test`
  (`+42 -4`, the pre-existing sqlite env failures), `dart format` on touched
  files (clean).
- **Success criteria:** met — schema v21 adds nullable indexed
  `workouts.routine_id`; `replayWorkout` inserts an atomically-created lineage
  occurrence prefilled per setting with base name + today's date;
  `getRoutineCompletionCount` is a single grouped COUNT; Replay offered from
  the summary appbar ("Do again") and the list tile long-press sheet;
  Duplicate still works unchanged.
- **Notes:**
  - The tile menu is a **long-press bottom sheet** (Replay / Duplicate) — the
    list previously used bare long-press = duplicate, and a trailing popup
    button would have cluttered the tile.
  - The replay-prefill dropdown lives on Settings → Profile (after Units);
    there is no General screen.
  - `restore()` (delete-undo snapshot) round-trips `routine_id`, so undoing a
    replayed workout's deletion keeps the lineage.
  - Progression display comes from the completed-only history (AW T03) +
    exercise-detail trends (Phase F) — no routine screen, as planned.
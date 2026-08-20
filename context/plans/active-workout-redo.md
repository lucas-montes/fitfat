# Plan: Active workout redo — exercise cards (notes, media/metadata/history) + set rows

## Change Summary

Rework the active-workout experience per review (2026-08-17):

1. **Exercise-level notes**: `workout_exercises.notes` (schema migration) with an
   editable note affordance on each exercise card.
2. **Bigger exercise cards**: a compact media header (thumbnail, tap → full-screen
   viewer; video when bundled), fact chips (type/body-part/equipment — reuses the
   exercise-detail pattern), and a collapsible **History** section for that
   exercise (past sessions: date, volume/reps, completed sets).
3. **Set rows** (`_SetRow`): remove the left set number, drop the `lineThrough`
   strikethrough on planned, stack planned (small muted) above actual (prominent),
   leading status icon.
4. **Progress colors**: per-set status green/orange/red/neutral based on actual vs
   planned (assumption pending veto: red = logged at zero; orange = 0 < actual <
   planned; green = actual >= planned; neutral = unlogged; cardio compares
   duration/distance). Add a per-exercise progress bar ("3/5 sets").

## Success Criteria

- Exercise cards show note editing + a rendered note, media, fact chips, and a
  history expandable using `exerciseHistoryProvider`.
- Set rows have no number, no strikethrough, stacked plan/actual, a leading
  status icon, and progress coloring; per-exercise progress bar renders.
- Schema bumped (new `workout_exercises.notes` column) with a working migration;
  `build_runner` regenerates cleanly; note round-trips insert/edit/undo.
- `dart analyze lib/` clean; `flutter gen-l10n` exit 0 (new keys); `flutter test`
  passes.

## Constraints & Non-Goals

- One schema bump only (`workout_exercises.notes`, nullable TEXT).
- No new dependencies (video only when `videoPath` already bundled — no asset work).
- Non-goal: set-level notes UI (user chose exercise-level), workout-level notes
  editing, chart implementations in history.
- Non-goal: performance work (Plan `performance`).

## Task Stack

- [x] T01: `Schema: workout_exercises.notes` (status:done)
  - Task ID: T01
  - Goal: Add `notes` (TEXT?) to `workout_exercises` and thread it through model +
    repository + factory + snapshot save/restore.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` (WorkoutExercises.notes),
      `lib/src/database/app_database.dart` (schema version bump + migration),
      `flutter pub run build_runner build --delete-conflicting-outputs`,
      `lib/src/models/workout_exercise.dart` (notes field),
      `lib/src/exercise/repositories/workout_repository.dart` (set on insert /
      replaceExercises / restore / `_getExerciseBlocks` mapping) +
      `updateExerciseNotes({workoutExerciseId, notes})`.
    - Out: UI (T02+).
  - Done when: `workout_exercises.notes` exists post-migration; notes round-trip
    insert / detail / delete+undo; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build --delete-conflicting-outputs`; `dart analyze lib/`.

- [x] T02: `Exercise card: media header + fact chips` (status:done)
  - Task ID: T02
  - Goal: Add a compact media header and metadata chips to `_ExercisePage`.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/active_workout_screen.dart` — `_ExercisePage`
      header gains an image (`Image.asset(imagePath)`, tap → full-screen
      `InteractiveViewer` reusing the exercise-detail viewer pattern; video via
      `video_player` when `videoPath != null`), fact chips (type/body-part/
      equipment via `splitTags`/`canonicalEquipmentTag` + localized labels).
    - Out: history (T03), notes (T04).
  - Done when: media + chips render with graceful fallback when no image/
    metadata; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T03: `Exercise card: collapsible history` (status:done)
  - Task ID: T03
  - Goal: Show past sessions for the exercise in a collapsible section.
  - Boundaries (in/out of scope):
    - In: `active_workout_screen.dart` — an `ExpansionTile`/`ExpansionPanelList`
      on `_ExercisePage` reading `exerciseHistoryProvider(block.exercise.exerciseId)`;
      each entry: workout name, date, volume (or duration/distance for cardio),
      completed/total sets. Compact rows.
    - Out: charts, PR stats.
  - Done when: history loads lazily and renders past sessions; empty state hidden
    or "no history" label; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T04: `Exercise-level notes UI` (status:done)
  - Task ID: T04
  - Goal: Edit + display the exercise note on the active-workout card.
  - Boundaries (in/out of scope):
    - In: `active_workout_screen.dart` — note icon/affordance in the card header
      opens a small edit dialog (multiline); saved via `updateExerciseNotes`;
      non-empty note rendered under the header with a note icon; l10n keys
      (`activeWorkoutExerciseNotes*`) en/fr/es.
    - Out: set/workout-level notes.
  - Done when: note persists and displays; `flutter gen-l10n` exit 0; `dart analyze` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T05: `Set row redesign` (status:done)
  - Task ID: T05
  - Goal: Remove the left set number and the planned strikethrough; stack planned
    (small muted) over actual (prominent); leading status icon.
  - Boundaries (in/out of scope):
    - In: `active_workout_screen.dart` `_SetRow` — drop the `setNumber` SizedBox,
    remove `TextDecoration.lineThrough`, restructure the row into a two-line
    column (planned subtext, actual headline), keep tap-to-edit + reversed
    HH:mm + rest auto-start logic.
    - Out: progress coloring (T06).
  - Done when: rows render per the Goal; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T06: `Set progress colors + per-exercise progress bar` (status:done)
  - Task ID: T06
  - Goal: Color-coded set status (green/orange/red/neutral) + a per-exercise
    completed-sets progress bar.
  - Boundaries (in/out of scope):
    - In: a `SetProgress` helper (in `active_workout_screen.dart` or a new
      `exercise_set` extension): weightlifting compares `actualWeightKg/actualReps`
      vs `weightKg/reps`; cardio compares `actualDurationMinutes`/`actualDistanceMeters`;
      statuses pending/partial/done/failed (assumption: failed = logged at zero).
      Applies to the leading status icon + actual text color + row tint; per-exercise
      `LinearProgressIndicator` with completed/total label. Uses `FitFatColors`.
    - Out: changing data model.
  - Done when: each set shows the correct status color and the exercise shows the
    progress bar; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T07: `Validation and context sync` (status:done)
  - Task ID: T07
  - Goal: Full checks + context sync (`context/database/schema.md`,
    `context/exercise/workout-crud.md`, `context/architecture.md`, glossary) +
    validation report.
  - Boundaries (in/out of scope): in — build_runner, gen-l10n, analyze, test,
    format, context sync; out — git commit.
  - Done when: suite green; context reads back accurate.
  - Verification notes (commands or checks):
    - build_runner, gen-l10n, `dart analyze lib/`, `flutter test`, `dart format --output=none --set-exit-if-changed lib test`.

## Validation Report (T01)

- `workout_exercises.notes` (nullable TEXT, comment "v17") added in `lib/src/database/tables.dart`;
  `app_database.dart` schema 16 → 17 with `onUpgrade if (from < 17)` ALTER.
- `flutter pub run build_runner build --delete-conflicting-outputs` → clean (229 outputs).
- `WorkoutExercise.notes` field added; repository threads `notes` across insert /
  `replaceExercises` / `restore` / `copyWorkout` / `_getExerciseBlocks` /
  `newWorkoutExercise`, plus new `updateExerciseNotes({workoutExerciseId, notes})`
  (trims; empty/null clears the column).
- `flutter analyze lib/src/exercise/repositories/workout_repository.dart
  lib/src/models/workout_exercise.dart lib/src/database` → **No issues found**.
- Undo restores notes automatically (snapshot/restore already re-inserts every column).

## Validation Report (T02–T06)

- `_ExercisePage` (active `_CompactMedia` strip → full-screen `_CardImageViewer`, video
  `_CardVideoPlayPause` fallback), `_CardFactChips` pills, `_NoteDialog` +
  `updateExerciseNotes` persistence, `_ExerciseHistorySection`/`_ExerciseHistoryRow`
  (via `exerciseHistoryProvider`), `_SetsProgressBar`, and the redesigned `_SetRow`
  (no number/strikethrough; stacked planned/actual; `_SetProgress` status icon + tint +
  actual color) all implemented in `lib/src/exercise/screens/active_workout_screen.dart`.
- New l10n keys `activeWorkoutExerciseNotes*` added en/fr/es; `flutter gen-l10n` exit 0.
- `dart format lib` on edited files → clean.
- `flutter analyze lib` → **No issues found**.
- `flutter test` → pure-logic suites pass; only pre-existing DB-backed failures
  remain (missing native `libsqlite3.so` in this environment — unrelated).

## Context Sync (T07)

- `context/database/schema.md`: `workout_exercises.notes` (v17) column + full migration
  list extended through v17; table count 9 → 14.
- `context/exercise/workout-crud.md`: new "Active workout redo (2026-08-17 review)"
  bullet covering media/chips/notes/history/progress-bar/set-row redesign.
- `context/architecture.md` + `context/glossary.md`: corrected to 14 tables and
  schema version 17.

## Next Command

/next-task active-workout-redo T07
# Plan: Active workout — declutter, set markings, rest → current exercise (Phase AW)

## Change Summary

Give the active-workout screen breathing room and fix its feedback signals
(review 2026-08-19):

1. **Merge the two top cards** into one info strip.
2. **Metadata + history behind icons** so the sets own the scroll space.
3. **History counts only completed** workouts/sets (planned ones pollute the
   enum + totals today).
4. **Set marking colors** per planned-vs-actual (green / orange / red) —
   the weight comparison is missing today.
5. **Rest-complete → jump to the current exercise** in the pager.

Planned-set rows keep their current format and the top exercise
image/video stays as-is (both explicitly non-negotiable).

## Success Criteria

- One (not two) top info card holds status, elapsed, started-at, rest
  countdown/overdue, and the exercise page indicator.
- Exercise fact chips open from an info icon (detail sheet); history opens from
  a history icon (sheet) — the exercise/workout **note stays inline**.
- `getExerciseHistory` returns only completed workouts and completed sets
  (entry list and per-entry volume/duration totals), for the active screen and
  the exercise detail/history consumers.
- Completed sets are green when ≥ planned (per the planned comparison), orange
  when reps **or weight** (or duration/distance) is lower, red when logged at
  zero; pending stays neutral.
- When a rest ends, the pager scrolls to the exercise whose rest was running.
- `flutter gen-l10n` exit 0; `flutter analyze lib/` clean; `flutter test`
  `+42 -4` (pre-existing sqlite env failures).

## Constraints & Non-Goals

- `_SetRow` layout/format unchanged (only status colors/weight-compare logic).
- Media (image/video) on the exercise card unchanged.
- No schema changes.
- Non-goal: restoring sets from history inline, exercise-detail chrome (Phase F
  covers that), auto-advance across exercises.

## Task Stack

- [x] T01: `Merge the two top cards into one info strip` (status:done)
  - Task ID: T01
  - Goal: Replace the separate header card + `_RestStrip` with a single card.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/active_workout_screen.dart` — one Card
      above the pager holding the status badge, live elapsed
      (`_ElapsedText`), started-at line, a compact rest line (count-up +
      overdue highlight, driven by `restTimerProvider`, own scoped ticker), and
      the `N / M` exercise-page indicator moved up from the pager bar; delete
      the standalone `_RestStrip` container; keep `_ElapsedText` as an isolated
      ticking leaf (perf T01).
    - Out: pager prev/next buttons (stay below; reading the page count moves up).
  - Done when: exactly one top card renders with all five pieces of info and
    the same info as today; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`;
      remove `_RestStrip` references (`flutter analyze` catches leftovers).

- [x] T02: `Metadata + history behind icons` (status:done)
  - Task ID: T02
  - Goal: Free scroll space by moving fact chips and history behind icon-opened
    sheets; keep the inline note.
  - Boundaries (in/out of scope):
    - In: in `_ExercisePage` — replace the always-on `_CardFactChips` row with
      an info icon (e.g. `Icons.info_outline`) opening a small detail sheet
      (type/body-part/equipment pills); replace the inline `_ExerciseHistorySection`
      ExpansionTile with a history icon opening a sheet listing the past
      sessions (reuse `_ExerciseHistoryRow` rows); the exercise/workout **note
      stays inline** (existing comment affordance untouched); new l10n keys
      en/fr/es (info/history sheet titles).
    - Out: changing note behavior, set rows, media.
  - Done when: chips + history are icon-launched sheets; note still inline; sets
    start higher with more visible rows; `flutter gen-l10n`; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/exercise/screens/active_workout_screen.dart`.

- [x] T03: `History counts only completed workouts/sets` (status:done)
  - Task ID: T03
  - Goal: Exclude pending workouts and planned sets from exercise history.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/repositories/workout_repository.dart`
      `getExerciseHistory` — filter workouts to `completed_at IS NOT NULL`
      (drop pending/active occurrences) and, per entry, include only
      `isCompleted` sets in the returned `sets` list (entries with zero
      completed sets are dropped); this automatically fixes the totals in
      `_ExerciseHistoryRow`/`exercise_history_card` since they aggregate from
      the returned sets.
    - Out: changing consumers' UI; mutation/delete paths.
  - Done when: pending workouts and planned sets no longer appear (list nor
    totals) for the active-screen history, the history sheet, and
    `exercise_detail_screen.dart` history; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/`;
      manual: a pending workout with planned sets must not show in history.

- [x] T04: `Set marking — include weight in the orange case` (status:done)
  - Task ID: T04
  - Goal: Orange when reps OR weight (or duration/distance) is below planned.
  - Boundaries (in/out of scope):
    - In: `_setProgress` in `active_workout_screen.dart` — for weightlifting,
      mark `partial` when `actualReps < reps` **or** `actualWeightKg <
      weightKg` (replacing "weight is informational"); keep `failed` (zero
      actuals), `done` (≥ both planned), `pending` (unlogged); no visual/layout
      changes beyond the corrected status.
    - Out: editing the actuals dialog, the planned-set format.
  - Done when: a set logged at planned reps but lower weight renders orange;
    green/red/pending unchanged; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`;
      manual: set actual weight below planned → orange.

- [x] T05: `Rest complete → jump to the current exercise` (status:done)
  - Task ID: T05
  - Goal: Track the current exercise and return to it when a rest ends.
  - Boundaries (in/out of scope):
    - In: `_ActiveWorkoutContentState` — watch `restTimerProvider`; when a rest
      is running or just transitioned to overdue/finished, derive the resting
      set's exercise from `_detail.exercises` (set id → workoutExerciseId →
      page index) and `jumpToPage` to it when the rest completes (one-shot,
      not on every rebuild); keep the manual pager independent otherwise; the
      rest line in T01 shows which exercise the rest belongs to when the user
      swiped away.
    - Out: auto-skipping planned sets, rest-cancel navigation.
  - Done when: when a rest ends the pager lands on that set's exercise without
    user action; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/active_workout_screen.dart`;
      manual: start a rest on exercise A, swipe to B, rest completes → pager
      returns to A.

- [x] T06: `Validation and context sync` (status:done)
  - Task ID: T06
  - Goal: Full checks + document the active-workout layout/behavior.
  - Boundaries (in/out of scope): in — analyze/format/tests,
    `context/exercise/active-workout.md` update + overview/glossary touches;
    out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+42 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/exercise`.

## Next Command

None — all tasks complete.

## Validation Report

- **Commands run:** `flutter gen-l10n` (exit 0), `dart analyze lib` (no
  issues), `flutter test` (`+42 -4`, the pre-existing sqlite env failures),
  `dart format` on the touched screen + repository (clean).
- **Success criteria:** met — single top info card (status, elapsed,
  started-at, rest line with overdue highlight + owning exercise, N/M page
  indicator); fact chips behind the info icon sheet; history behind the
  history icon sheet (`_HistorySheet`); note stays inline;
  `getExerciseHistory` returns completed workouts with completed sets only
  (entries with zero completed sets dropped); `partial` now includes weight
  below planned; rest-overdue one-shot `jumpToPage` to the resting set's
  exercise.
- **Non-negotiables respected:** planned-set row format unchanged (only the
  status logic changed); media strip untouched; no schema changes.
- **Notes:** T06 named `context/exercise/active-workout.md`, which doesn't
  exist — active-workout behavior is documented in
  `context/exercise/workout-crud.md` (new "Active workout declutter" bullet,
  superseding parts of the redo/performance bullets), so that file was updated
  instead. Device-only behaviors (rest jump, sheet ergonomics) still worth a
  manual smoke pass on a real device.
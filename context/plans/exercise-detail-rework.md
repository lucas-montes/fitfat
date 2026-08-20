# Plan: Exercise detail — history presentation rework (Phase F)

## Change Summary

Improve the per-workout history card on `ExerciseDetailScreen` (History tab):

- Right-aligned **summary row** (volume/duration, total reps, distance,
  sets completed) instead of stacked `_InlineMetric`s.
- A **Δ-vs-previous-workout** header (total-volume trend arrow / PR badge).
- Set rows become a **real column grid** — `# | Planned | Actual | Δ | Rest` —
  reusing the active-workout flex-column alignment, with **color-coded deltas**
  (green/red) instead of the neutral inline text.
- Add a **reps/weight trend line** alongside the existing volume-over-time chart.

## Success Criteria

- History card renders the aligned summary row + per-set grid; deltas are
  color-coded; PR/trend indicator present.
- New reps/weight trend chart renders from real history; empty/single-point
  cases handled.
- `flutter gen-l10n` exit 0; `flutter analyze lib/` clean; `flutter test`
  `+42 -4` (pre-existing sqlite env failures); touched files format-clean.

## Constraints & Non-Goals

- Presentation only — no schema/repo changes, no new dependencies
  (`fl_chart` already present).
- Reuse existing `ExerciseSet` getters (`totalVolume`, `effectiveReps`,
  `effectiveWeightKg`, `isCompleted`, rest fields).
- Non-goal: e1RM/1RM estimation, RPE/tempo, intra-card interactions.

## Task Stack

- [x] T01: `Workout history card — summary row + Δ-vs-previous header` (status:done)
  - Task ID: T01
  - Goal: Restructure the card header/summary and add the trend indicator.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/exercise_detail_screen.dart`
      `_WorkoutHistoryCard` — right-aligned summary row (replaces the `Wrap` of
      `_InlineMetric`), header gains Δ-vs-previous-workout (total-volume arrow
      + "new PR" badge when today's volume beats every prior workout); new l10n
      keys en/fr/es (trend/PR labels).
    - Out: set-row grid (T02), trend chart (T03).
  - Done when: card renders summary row + trend/PR indicator; `flutter analyze
    lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/exercise/screens/exercise_detail_screen.dart`.

- [x] T02: `Set rows — column grid with colored deltas` (status:done)
  - Task ID: T02
  - Goal: Replace the inline `"Set 1 · planned → actual"` text with aligned
    columns.
  - Boundaries (in/out of scope):
    - In: `_SetRow` rewrite — columns `# | Planned | Actual | Δ | Rest` using the
      flex-width column pattern from `active_workout_screen.dart` (tabular
      figures, wrapped text at large scales); Δ colored via `FitFatColors`
      success/error; completion icon retained.
    - Out: chart changes (T03), editing sets from history.
  - Done when: rows are aligned columns with colored deltas; `dart analyze lib/`
    clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/exercise/screens/exercise_detail_screen.dart`.

- [x] T03: `Reps/weight trend line chart` (status:done)
  - Task ID: T03
  - Goal: Add a second history trend beside the volume chart.
  - Boundaries (in/out of scope):
    - In: extend the history metrics to emit a reps (and best weight) trend over
      the same chronological workouts; render as a second `_HistoryChart`
      (best-weight line when the exercise uses weight, reps line otherwise);
      new l10n keys en/fr/es; ≥2-point guard like the volume chart.
    - Out: toggling series, PR dots on the chart.
  - Done when: trend chart renders for weighted and non-weighted exercises;
    `flutter analyze lib/` clean.
  - Verification notes (commands or checks):
    - `flutter gen-l10n`; `dart analyze lib/src/exercise/screens/exercise_detail_screen.dart`.

- [x] T04: `Validation and context sync` (status:done)
  - Task ID: T04
  - Goal: Full checks + document the presentation.
  - Boundaries (in/out of scope): in — analyze/format/tests,
    `context/exercise/exercise-crud.md` update; out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+42 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/exercise`.

## Validation Report

- **Commands run:** `flutter gen-l10n` (exit 0), `dart analyze lib` (no issues),
  `flutter test` (`+42 -4`, the 4 failures are the pre-existing sqlite env
  failures), `dart format` on the touched screen (clean after formatting).
- **Success criteria:** met — summary row renders; Δ-vs-previous header with
  PR badge present; set grid aligned with color-coded deltas; reps/weight
  trend chart renders with ≥2-point guard.
- **Notes:** pre-existing format drift in `exercise_detail_screen.dart` cleaned
  up as part of the touched-file reformat. `exerciseDetailVsPrevious` key was
  dropped as redundant with `exerciseDetailTrendSame`/`TrendDelta`.

## Next Command

None — all tasks complete.

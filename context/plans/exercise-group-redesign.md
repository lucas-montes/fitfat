# Plan: Exercise group redesign — workouts, exercises, detail screens (Phase EG)

**Status:** planned — design round 6 is out for picks; tasks T01–T03 can start now, T04–T08 wait on the open decisions below.

## Change Summary

Bring the Exercise tab onto the new design system (`context/ui/design-system.md`:
Inset style, palettes, `SectionHeader`, `FormScaffold`, `confirmDelete`,
`showAppSheet`, no loading/error states on local data) and implement the
layouts chosen in the design rounds
(proposals page: https://claude.ai/artifact/SjcVZMs4L9oVqCTm9sSTmm, rounds 4 and 6):

1. **Workouts list** (decided, round 4 "W2"): one card per workout — name,
   status badge, date · template, the first exercises with their top set,
   the workout note, and a Time / Sets / Volume (or Distance) stat row —
   grouped by calendar week under a **week summary card** (title, date range,
   a dot per training day, Workouts / Time / Volume).
2. **Exercises list** (decided, round 4 "B"): two-column **image grid**
   (exercise image or video poster, name, one line of metadata).
3. **Tab structure, starting a workout, grid filters, exercise detail,
   workout detail**: per the round 6 picks (open decisions below).

## Open decisions (round 6)

| # | Question | Options | Recommended default |
|---|---|---|---|
| D1 | Tab structure | A segmented Workouts · Exercises · Templates · B workouts + "Library" cards · C app-bar icons (today) | A |
| D2 | Starting a workout | A start sheet (empty + templates) · B "Start from" chips · C "Up next" from the planner | A (C can be added on top later) |
| D3 | Exercise grid filters / tile text | A body-part chips + filter button, tiles show body part · equipment · B filter button + applied chips, tiles show last set | B |
| D4 | Exercise detail | A media + History/Details tabs (restyled) · B one scroll, progress first, "How to" collapsed · C compact header, history-first | B |
| D5 | Workout detail (finished) | A stat tiles + exercise cards with the planned/actual/Δ grid · B compact rows with set chips | A |

Record the answers here (and in the decisions memory) before starting T04.

## Success Criteria

- Workouts list renders week summary cards + workout cards from **two
  aggregate queries** (no per-workout detail resolution), opens with data
  (no spinner), and keeps the active workout first with Continue.
- Exercises grid renders 200+ exercises smoothly (lazy `SliverGrid`, cached
  thumbnails) with search + the chosen filter UI; empty filter result shows the
  existing `exerciseFilterNoResults` empty state.
- Exercise detail and workout detail follow D4/D5; Edit lives in the ⋮ menu;
  Delete is a `DangerRow` at the bottom that goes through `confirmDelete`
  (cascade sheet lists sets / voice notes).
- Only theme colors (`ColorScheme`, `FitFatColors`) — no `Colors.*` literals in
  touched files; section labels use `SectionHeader`.
- `flutter gen-l10n` exit 0; `flutter analyze` clean; `flutter test` green;
  new widget tests for the list, grid and both detail screens.

## Constraints & Non-Goals

- **Active workout screen is out of scope.** Its planned-set rows and the
  exercise image/video stay exactly as they are (non-negotiable, see
  `active-workout-declutter.md`); only theme colors flow into it.
- Presentation and read-query work only: no schema change. New repository
  methods are read-only aggregates.
- Keep the existing exercise-history semantics: only completed workouts and
  sets count (`getExerciseHistory`).
- Keep the History tab content decided in `exercise-detail-rework.md` (PR
  summary, trend chart, per-workout set grid `# | Planned | Actual | Δ | Rest`)
  whatever D4 layout wraps it.
- Non-goals: e1RM-based programming, template editor redesign (templates list
  only gets restyled), workout form redesign beyond `FormScaffold` adoption.

## Data needed

| UI | Source today | Plan |
|---|---|---|
| Workout card: sets, volume/distance, first 2–3 exercises with top set | per-workout `workoutDetailProvider` | new `WorkoutRepository.getCardSummaries()` — one grouped query over workouts ⋈ workout_exercises ⋈ sets returning `{workoutId, setCount, volumeKg, distanceKm, minutes, topExercises: [(name, topSet)]}`; provider `workoutCardSummariesProvider` (keep-alive, warmed at startup like the lists) |
| Week summary: workouts, time, volume, training days | `getVolumeAndMinutesBetween` (current week only) | `getWeekSummaries()` — group by Monday-of-week over all weeks (or derive from the card summaries in Dart, which is cheaper for < a few hundred workouts) |
| Grid tile last set (D3=B) | `getExerciseHistory` per exercise | new `getLastSetPerExercise()` — one query, latest completed set per exercise id |
| Exercise detail stats: best set, last session, session count | computed in `_HistoryMetrics` from history | unchanged; reuse `_HistoryMetrics` |

## Task Stack

- [ ] T01: `Workout card + week summary aggregates` (status:todo)
  - Task ID: T01
  - Goal: Read everything the workouts list needs in two queries.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/repositories/workout_repository.dart`
      (`getCardSummaries`, week grouping), `lib/src/exercise/providers/workouts.dart`
      (`workoutCardSummariesProvider`, `workoutWeekSummariesProvider`), startup
      warm-up list in `lib/src/app/app.dart`; invalidation alongside
      `workoutListProvider`.
    - Out: UI.
  - Done when: unit tests on an in-memory DB cover a lift, a cardio-only and an
    active workout (volume vs distance, active excluded from totals).
  - Verification notes: `flutter test test/workout_card_summaries_test.dart`.

- [ ] T02: `Workouts list — week summary card + workout cards` (status:todo)
  - Task ID: T02
  - Goal: Rebuild `WorkoutListScreen` as the decided "W2" layout.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_list.dart` → large-title
      `CustomScrollView`; `_WeekSummaryCard` (title, range, day dots, stats) per
      week; `WorkoutCard` (name, `StatusBadge`, date · template, top exercises,
      note, stat row); active workout pinned first with Continue; tap →
      `/workout-summary/:id`; swipe/long-press actions removed in favour of the
      detail screen's ⋮ / danger row. Empty state keeps `EmptyState` with its CTA.
    - Out: tab switcher (T04), start flow (T05).
  - Done when: widget test renders two weeks of seeded workouts, active first.
  - Verification notes: screenshot check in Dracula + Alucard (golden-capture
    script used for the dashboard, `test/zz_screenshots_test.dart` pattern, not
    committed).

- [ ] T03: `Exercises grid (decided layout)` (status:todo)
  - Task ID: T03
  - Goal: Replace the exercise `ListTile` list with a two-column image grid.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/exercise_list.dart` — `SliverGrid`
      (2 columns, 4:3 media, name, meta line), image fallback tile with the
      exercise initial, existing search + filters kept functional (restyled in
      T06), sync menu unchanged.
    - Out: filter UI change (T06), last-set text (T06 if D3=B).
  - Done when: widget test finds tiles for seeded exercises; 200-item list
    scrolls without jank in profile mode (manual).

- [ ] T04: `Tab structure (D1)` (status:blocked on D1)
  - Task ID: T04
  - Goal: Implement the picked navigation between workouts, exercises and
    templates.
  - Boundaries: `lib/src/app/tabs/exercise_tab.dart`, `workout_list.dart`
    app bar, `workout_templates_screen.dart` (restyle list only). For D1=A a
    `SegmentedButton` under the large title with the selected section kept in a
    provider (survives tab switches); each section keeps its own search and FAB.
  - Done when: switching sections keeps scroll positions; deep links
    (`/exercise`) land on Workouts.

- [ ] T05: `Starting a workout (D2)` (status:blocked on D2)
  - Task ID: T05
  - Goal: One consistent way to start a workout.
  - Boundaries: FAB on the workouts section; D2=A uses `showAppSheet` with
    "Empty workout" + templates (search, "last done" from the card summaries);
    starts through the existing replay/template code path
    (`workout-replay.md`), no new start logic.
  - Done when: starting from a template and empty both land on
    `/active-workout`; widget test for the sheet.

- [ ] T06: `Exercise grid filters + tile text (D3)` (status:blocked on D3)
  - Task ID: T06
  - Goal: The picked filter presentation.
  - Boundaries: `exercise_list.dart` filter bar; D3=B adds
    `getLastSetPerExercise()` + provider and an applied-filter chip row with
    clear actions; filter sheet = `showAppSheet` with the four facets.
  - Done when: applying/removing filters updates the count line; test covers
    chip removal.

- [ ] T07: `Exercise detail (D4)` (status:blocked on D4)
  - Task ID: T07
  - Goal: Restructure `ExerciseDetailScreen` per D4.
  - Boundaries: `lib/src/exercise/screens/exercise_detail_screen.dart`
    (1,700 lines — split into `exercise_detail/` parts: media header, stats,
    chart, sessions, how-to). Reuse `_HistoryMetrics`, `_HistoryChart`, the
    per-workout set grid. Edit in ⋮; Delete as `DangerRow` → `confirmDelete`
    (cascade: workouts that use it). Remove `CircularProgressIndicator` loading
    scaffolds (local data).
  - Done when: widget tests for an exercise with history and one without (empty
    history shows a start action, not a blank chart).

- [ ] T08: `Workout detail (D5)` (status:blocked on D5)
  - Task ID: T08
  - Goal: Restyle `WorkoutSummaryScreen` (finished workouts) per D5.
  - Boundaries: `workout_summary_screen.dart` (+ `workout_detail.dart` if it is
    still reachable; otherwise fold it in and delete). Stat tiles, Do again as
    the primary button, exercise cards with the set grid, Edit in ⋮, Delete as
    `DangerRow` with cascade counts (sets, voice notes) via `confirmDelete`.
  - Done when: widget test covers a workout with a PR set and the delete
    cascade sheet.

- [ ] T09: `Context docs` (status:todo, last)
  - Task ID: T09
  - Goal: Update `context/exercise/workout-crud.md`,
    `context/exercise/exercise-crud.md` and `context/ui/design-system.md`
    (screen standards: list cards, grid, detail screens); move this plan's row
    in `context/context-map.md`.

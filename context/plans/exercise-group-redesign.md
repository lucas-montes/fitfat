# Plan: Exercise group redesign — workouts, exercises, detail screens (Phase EG)

**Status:** planned — all designs decided (2026-11-27); ready to implement T01–T08.

## Change Summary

Rebuild the Exercise tab around starting a workout, on the design system in
`context/ui/design-system.md` (proposals: https://claude.ai/artifact/SjcVZMs4L9oVqCTm9sSTmm,
rounds 6–10):

1. **Training home** — unfinished workout on top; a **Recent** row (each named
   workout once, Start) and a **Templates** row (Start), each with **All**; this
   week's summary card below.
2. **Weekly history** (Recent → All) — month chips + range sheet; one card per
   week with dates, day dots and totals; rows with ↻.
3. **Templates list** (Templates → All) — cards listing exercises and targets, Start.
4. **Workout detail** — summary (volume, time, sets, average rest, calories,
   volume split, PR line) + per-set plan bars with rest.
5. **Exercises** — search with four facet dropdowns; **exercise detail** with
   media + History / Details tabs.

## Direction (user feedback on round 6, 2026-11-27)

- The user moves between **workouts and templates**; the exercise library is
  rarely opened. The tab must make **starting a workout** the fastest path.
- Workouts are usually started by **repeating a past workout** (by name, e.g.
  "Skate", "Bench day"), or from a **new template created after a PR**.
- Exercises: a search field with filter options, better than the round 6
  proposals.

## Decisions

| # | Question | Status |
|---|---|---|
| D1+D2 | Training home | **direction decided (2026-11-27):** an unfinished workout pinned on top, then two horizontal rows — **Recent** (each named workout once, most recent first, Start on each card) and **Templates** (Start on each card) — each with an **All** link to a full list. Below the rows: **this week's summary card** (round 8 A, decided) |
| D1a | `All` recent workouts list | **decided: round 10 A** — one card per week: tinted header with the date range only, seven day dots on the right, totals underneath (time · volume · distance); workouts as rows inside the card with ↻; no week labels, no workout count, no active workout; **month chips + Range** filter (Range opens the calendar sheet with quick ranges) |
| D1b | `All` templates list | **decided: A** — a card per template listing its exercises with target sets, last done, New badge for PR templates, Start; edit/delete in the card ⋮ |
| D3 | Exercise search + filters | **decided: A** — search field with four facet dropdown chips (Body part, Equipment, Muscle, Type); each opens a small multi-select sheet with a live result count; applied values show inside the chip. Search results render as rows with the last set; browsing keeps the image grid |
| D4 | Exercise detail | **decided: A** — media + History / Details tabs, restyled (stat tiles, chart with Weight/Reps/Volume switch, sessions; Details as grouped rows + numbered instructions) |
| D5 | Workout detail | **decided: B, revised** — summary card (volume + change vs last time, time, sets, **average rest**, **calories burned**, volume split per exercise, one PR line); per exercise: sets · volume · **average rest**, then one bar per set (fill = reps done / planned, label weight × reps, Δ vs plan, PR in green) with the **rest after that set** on the right. No Do again button (↻ icon in the top bar), no set index numbers, **no Save-as-template card** (Save as template is in ⋮). Delete = danger row at the bottom |

## New capabilities implied

- **Repeat a past workout by name**: group completed workouts by name
  (case-insensitive), expose count + last date + last summary, and start a
  new workout prefilled from the most recent one (reuse the replay path in
  `workout-replay.md`).
- **Save as template from a workout**, offered when the workout contains a PR
  (PR = best weight for the reps, or best volume, per exercise history).

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
| Recent row: one card per named workout (most recent first) with last summary, count, last date | `workoutListProvider` (all workouts) | group completed workouts by `routineId` (replays share it), falling back to the case-insensitive name; one bulk aggregate per workout (below) supplies the summary line. Provider `recentRoutinesProvider` |
| Workout rows / week totals: duration, set count, volume or distance, PR flag | per-workout `workoutDetailProvider` | new `WorkoutRepository.getRowSummaries()` — one grouped query: `{workoutId, minutes, setCount, volumeKg, distanceKm, hasPr}`; `hasPr` = a completed set beating every earlier set of that exercise (weight for its reps, or volume) |
| Week cards: dates, training-day dots, time / volume / distance | — | derived in Dart from row summaries, grouped by `startOfCalendarWeek`; month filter = weeks overlapping the month, range filter = workouts inside the span |
| Templates: exercises + target sets, last done, New | `workoutTemplateDetailsProvider` per template | `WorkoutTemplateRepository.getAllWithExercises()` (one query) + last done = max `workouts.date` per `templateId`; **New** = never started and created in the last 14 days |
| Workout detail: rest per set, average rest, calories | `ExerciseSet.actualRestSeconds` / `restSeconds`; energy already computed on the summary screen | reuse; average rest = mean of completed sets' actual rest (fallback planned), excluding the last set of each exercise |
| Exercise search rows: last set per exercise | `getExerciseHistory` per exercise | new `getLastSetPerExercise()` — one query, latest completed set per exercise id |

Existing actions reused, not rewritten: `replayWorkout` (start again, routine-aware prefill),
`saveAsTemplate` (workout → template), template start via the existing template path.

## Task Stack

- [ ] T01: `Read aggregates for the training screens` (status:todo)
  - Task ID: T01
  - Goal: Everything the home, the history and the templates list need in a handful of queries.
  - Boundaries (in/out of scope):
    - In: `workout_repository.dart` (`getRowSummaries`, `getLastSetPerExercise`),
      `workout_template_repository.dart` (`getAllWithExercises`, last done per template),
      providers `workoutRowSummariesProvider`, `recentRoutinesProvider`,
      `templateCardsProvider`, `lastSetPerExerciseProvider` (keep-alive, warmed at
      startup in `app.dart`, invalidated with `workoutListProvider` /
      `workoutTemplateListProvider`).
    - Out: UI.
  - Done when: in-memory DB tests cover lift vs cardio, a PR set, replays grouped
    into one routine, template last-done and New.
  - Verification notes: `flutter test test/training_aggregates_test.dart`.

- [ ] T02: `Training home` (status:todo)
  - Task ID: T02
  - Goal: Replace `WorkoutListScreen` as the Exercise tab root with the training home.
  - Boundaries (in/out of scope):
    - In: new `lib/src/exercise/screens/training_screen.dart`, `exercise_tab.dart`.
      Large title "Training"; app bar: search (workouts) + dumbbell icon → exercises.
      Unfinished workout strip with Continue (only here). `SectionHeader`
      "Recent" + **All** → T03; horizontal row of routine cards (icon, name,
      summary, last date · count, **Start** → `replayWorkout`). `SectionHeader`
      "Templates" + **All** → T04; horizontal row of template cards (Start).
      Below: this week's summary card (dates, day dots, time / volume /
      distance). FAB → empty workout. Empty states: no workouts → one-line
      explanation + "Start a workout"; no templates → hint that a template can
      be saved from any workout.
    - Out: the active workout screen.
  - Done when: widget test with seeded data shows both rows, Start replays the
    routine, the active strip appears only with an active workout.

- [ ] T03: `Weekly history (All recent)` (status:todo)
  - Task ID: T03
  - Goal: Round 10 A.
  - Boundaries (in/out of scope):
    - In: new `workout_history_screen.dart` (replaces the old list screen; delete
      `workout_list.dart` once unreferenced). Month chips (All, then months
      that have workouts, newest first) + **Range** chip opening a calendar sheet
      (quick ranges 7 days / 30 days / 3 months / this year + start–end picking,
      workout days dotted, "Show N workouts"). One card per week: tinted header
      with the date range, seven day dots on the right, totals underneath
      (time · volume · distance when any); rows: type icon, name, PR badge,
      date · duration · volume-or-distance, ↻ (`replayWorkout`). Active workout
      excluded. Search field in the app bar filters by name.
    - Out: per-workout swipe actions (delete lives in the detail screen).
  - Done when: widget tests for month filtering, range filtering and ↻.

- [ ] T04: `Templates list` (status:todo)
  - Task ID: T04
  - Goal: Round 8 A — template cards with their exercise list.
  - Boundaries (in/out of scope):
    - In: `workout_templates_screen.dart` list part: card per template (name,
      New badge, ⋮ Edit / Delete via `confirmDelete`), "N ex · M sets · last X",
      exercises with target sets, **Start**. Search in the app bar, + to create.
      Template editing screen only adopts `FormScaffold`.
    - Out: recurrence/scheduling UI changes.
  - Done when: widget test shows exercises and Start for a seeded template.

- [ ] T05: `Workout detail` (status:todo)
  - Task ID: T05
  - Goal: D5 — summary + plan bars with rest and calories.
  - Boundaries (in/out of scope):
    - In: `workout_summary_screen.dart`. App bar: ↻ (replay) + ⋮ (Edit, Save as
      template). Summary card: date/time range + Completed, volume + change vs
      the previous workout of the same routine, Time / Sets / Avg rest / Burned,
      volume split bar per exercise, one PR line. Per exercise card: thumbnail,
      name, "N sets · volume · avg rest", one bar per set (fill = actual reps ÷
      planned, label "weight × reps", Δ vs plan, PR in success color) with the
      rest after it on the right (none after the last set); cardio sets show
      duration/distance instead. Bottom: `DangerRow` "Delete workout" with
      cascade counts (sets, voice notes) via `confirmDelete`; footer "From
      template X". No set index numbers, no big button, no save card.
      Fold `workout_detail.dart` in if it is still reachable.
    - Out: editing sets from this screen.
  - Done when: widget tests for a lifting workout with a short set and a PR,
    a cardio workout, and the delete cascade.

- [ ] T06: `Exercises: search + facet dropdowns` (status:todo)
  - Task ID: T06
  - Goal: D3 A, reached from the dumbbell icon.
  - Boundaries (in/out of scope):
    - In: `exercise_list.dart`. Search field; four dropdown chips (Body part,
      Equipment, Muscle, Type) each opening a multi-select sheet with a live
      "Show N exercises" button; applied values shown inside the chip; clear by
      long-press or the sheet's Clear. Browsing (no query, no filter) = two-column
      image grid; with a query or filter = rows with thumbnail, name, body part ·
      equipment and the last set on the right. Sync menu unchanged.
    - Out: favourites (not requested).
  - Done when: tests cover a facet selection, chip label and grid/rows switch.

- [ ] T07: `Exercise detail` (status:todo)
  - Task ID: T07
  - Goal: D4 A — media + History / Details tabs, restyled.
  - Boundaries (in/out of scope):
    - In: split `exercise_detail_screen.dart` (1,700 lines) into
      `exercise_detail/` parts. History: three stat tiles (Best, Last,
      Sessions), chart with a Weight / Reps / Volume segmented switch, sessions
      list (PR badge, volume, Δ vs previous) keeping the per-workout set grid on
      tap. Details: grouped rows (type, body part, equipment, muscles), numbered
      instructions, tips, FAQs. Edit in ⋮; Delete as `DangerRow` → `confirmDelete`.
      No loading scaffolds.
    - Out: media player behaviour.
  - Done when: tests for an exercise with history and one without (History shows
    a one-line empty state).

- [ ] T08: `Context docs + cleanup` (status:todo, last)
  - Task ID: T08
  - Goal: Update `context/exercise/workout-crud.md`, `context/exercise/exercise-crud.md`,
    `context/ui/design-system.md` (training screen standards); remove dead
    screens/strings; move this plan's row in `context/context-map.md`.

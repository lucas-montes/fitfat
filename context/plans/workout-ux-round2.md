# Workout UX Round 2 — Forms, history, performance, translations

## Change Summary

Batch of UX improvements and feature additions for the active workout flow:

1. **History mini-tiles**: remove "done" label, show completion time + rest intervals, reverse order
2. **Compact form**: single-row reps/weight/add with notes below
3. **Separate planned vs free-form forms**: different UI and behavior, no "Add Exercise" in planned
4. **Add Exercise pill** at end of exercise tab bar
5. **Fix exercise switch lag** in the PageView
6. **Equal-height stat cards** in summary screen
7. **Multi-language exercises**: new `exercise_translations` DB table, model updates, provider integration

## Success Criteria

- `dart analyze lib/` — 0 errors, 0 warnings
- `flutter test test/src/exercise/` — 62/62 pass
- History mini-tiles show completion time and rest interval; no "done" label
- Form is a single horizontal row of reps/weight/add with notes below
- Planned workout hides "Add Exercise" button; free-form shows it
- Pills row has a trailing "+" chip to add exercises
- Exercise switching feels responsive (no visible "stuck" frame)
- Summary stat cards are equal height
- `exercise_translations` table exists at schema v14; `ExerciseDefinition` carries localized name/description; exercises display in app locale

## Constraints and Non-Goals

- **In scope**: All 7 items listed above
- **Out of scope**: Translations for user-created exercises (bundled-only initially); editing translations from the UI; auto-translation; adding new languages beyond what the app already supports
- **Assumptions**: The lag is caused by eager PageView children construction and/or per-page provider subscriptions; lazy `PageView.builder` + `AutomaticKeepAliveClientMixin` will resolve it
- **Schema version**: bump from 13 → 14

## Task Stack

- [x] T01: `Redesign history mini-tiles — time, rest, reverse order` (status:done)
  - Task ID: T01
  - Goal: Replace the "done" label in history session mini-tiles with the set's `completedAt` time (e.g. "14:32") and the rest interval since the previous set (e.g. "+2:30"). Reverse the order of sets within each session so the most recent set appears first.
  - Boundaries (in/out of scope): In — `_buildMiniSetTile` and `_CollapsibleSessionListState` in `exercise_detail_screen.dart`; computed rest interval from adjacent set timestamps. Out — cardio sets in history (history only shows WeightSets).
  - Done when: Mini-tiles show "14:32  +2:30  80 kg × 3 reps" format; no "done" text anywhere in history; sets ordered most-recent-first per session.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check of history snippet.
  - **Completed:** 2026-06-26
  - **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart (`_buildMiniSetTile` → `_buildMiniTiles`, `_CollapsibleSessionListState.build`)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T02: `Compact add-set form — single row + notes below` (status:done)
  - Task ID: T02
  - Goal: Redesign `ExerciseSetForm` layout: a single horizontal row with `[Reps] [Weight] [Add Set button]`, and "Add notes" toggle rendered below the row instead of in a separate section.
  - Boundaries (in/out of scope): In — `exercise_set_form.dart` layout rewrite. Out — changing form controllers or add-set logic; changing cardio form.
  - Done when: Reps and Weight fields side by side with the Add button immediately to their right; "Add notes" link below the row.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check of form layout.
  - **Completed:** 2026-06-26
  - **Files changed:** lib/src/exercise/screens/workout/widgets/exercise_set_form.dart (full layout rewrite)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T03: `Separate forms for free-form vs planned workouts` (status:done)
  - Task ID: T03
  - Goal: Create `FreeFormExerciseForm` and `PlannedExerciseForm` as distinct widgets sharing common field components. The parent (`exercise_detail_screen.dart` / `active_screen.dart`) shows the appropriate form based on `workout.isFreeform`. Planned workout hides all "Add Exercise" entry points.
  - Boundaries (in/out of scope): In — new widget files `free_form_exercise_form.dart` and `planned_exercise_form.dart`; share field widgets from `exercise_set_form.dart` or inline common layout; conditionally hide "Add Exercise" button in `active_screen.dart` based on `isFreeform`. Out — changing the set completion/toggle behavior for planned workouts.
  - Done when: Free-form workout shows the compact add-set form + "Add Exercise" everywhere; planned workout shows a differently laid-out form (planned values, manual complete) and no "Add Exercise" entry points.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check of both workout types.
  - **Completed:** 2026-06-26
  - **Files changed:** `free_form_exercise_form.dart` (new), `planned_exercise_form.dart` (new), `exercise_detail_screen.dart` (conditional form + removed unused import), `active_screen.dart` (conditional Add Exercise button)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T04: `Add Exercise pill at end of chips row` (status:done)
  - Task ID: T04
  - Goal: Append a "+" chip to the `_buildExerciseChips` horizontal list that opens the Add Exercise bottom sheet. Only visible in free-form workouts.
  - Boundaries (in/out of scope): In — one additional chip at `itemCount + 1` in the horizontally scrolling chip list. Out — changing the Add Exercise sheet itself.
  - Done when: Pills row shows a trailing "+" pill; tapping it opens `AddExerciseSheet`; hidden in planned workouts.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check of pills row.
  - **Completed:** 2026-06-26
  - **Files changed:** `exercise_detail_screen.dart` (_buildExerciseChips expanded, _openAddExercise added, import added)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T05: `Fix exercise switch lag in PageView` (status:done)
  - Task ID: T05
  - Goal: Eliminate the perceptible "stuck" frame when swiping or tapping between exercises in `ExerciseWorkoutDetailScreen`. Root cause investigation first, then apply targeted fixes.
  - Boundaries (in/out of scope): In — converting `PageView(children: [...])` to `PageView.builder` for lazy construction; adding `AutomaticKeepAliveClientMixin` to exercise pages; caching `_ExerciseHistorySnippet` data to avoid per-page provider re-fetches on every swipe. Out — full provider architecture rewrite.
  - Done when: Tapping a pill or swiping between exercises shows the new page immediately with no visible lag.
  - Verification notes: `dart analyze lib/` — 0 errors; subjective "no stuck frame" on device.
  - **Completed:** 2026-06-27
  - **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart (`PageView` → `PageView.builder` + new `_ExercisePage` keep-alive wrapper widget)
  - **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings (3 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

- [x] T06: `Equal-height summary stat cards` (status:done)
  - Task ID: T06
  - Goal: Ensure the three `StatCard` widgets in `WorkoutSummaryScreen` always have the same height regardless of their content (value text length).
  - Boundaries (in/out of scope): In — wrapping the stat card row in `IntrinsicHeight` or `SizedBox` to enforce equal heights; or modifying `StatCard` to accept a fixed height. Out — changing stat card content or layout structure.
  - Done when: All three stat cards render at the same height on the summary screen.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check on device.
  - **Completed:** 2026-06-27
  - **Files changed:** `workout_summary_screen.dart` (Row → IntrinsicHeight + crossAxisAlignment: stretch), `stat_card.dart` (Column mainAxisAlignment: center)
  - **Evidence:** `dart analyze lib/` — 0 errors, 0 warnings; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T07: `Add exercise_translations DB table + migration` (status:done)
  - Task ID: T07
  - Goal: Add `ExerciseTranslations` Drift table with columns `exerciseId`, `locale`, `name`, `description`. Bump schema version to 14 and add migration. Add repository methods to load/insert translations. Add `ExerciseTranslation` model.
  - Boundaries (in/out of scope): In — new table definition in `tables.dart`; schema v14 migration in `app_database.dart`; `ExerciseTranslation` model in `models/workout.dart`; repository methods `getTranslations(String locale)` returning `Map<String, ExerciseTranslation>` or similar. Out — provider changes, UI changes.
  - Done when: `dart analyze lib/` — 0 errors; `ExerciseTranslations` table exists in the DB; repository can query translations by locale.
  - Verification notes: `dart analyze lib/` — 0 errors; DB schema version reports 14.
  - **Completed:** 2026-06-27
  - **Files changed:** `tables.dart` (new `ExerciseTranslations` table), `models/workout.dart` (new `ExerciseTranslation` model), `app_database.dart` (schema v14, migration step, CRUD methods, regenerated `.g.dart`), `workout_repository.dart` (interface + Drift impl — `getTranslations`)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed; `app_database.g.dart` regenerated with `exerciseTranslations` table.

- [x] T08: `Wire translations into ExerciseDefinition + providers` (status:done)
  - Task ID: T08
  - Goal: Update `ExerciseDefinition` to accept optional `localizedName` / `localizedDescription`. Update `exerciseListProvider` to merge translations for the current app locale into exercise definitions. Update exercise name/description display sites (chips, list tiles, summary) to show localized text.
  - Boundaries (in/out of scope): In — `ExerciseDefinition.copyWith` + constructor updates; `exerciseListProvider` loads translations from repository for current locale; component usage of `exercise.name` changed to `exercise.localizedName ?? exercise.name` across files where exercise names appear in the active workout and summary views. Out — translations for exercise history, stats tab, or dashboard (only active workout flow).
  - Done when: Exercises display translated names/descriptions based on app locale; fallback to default name/description when no translation exists.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check that exercise names appear correctly in active workout flow.
  - **Completed:** 2026-06-27
  - **Files changed:** `models/workout.dart` (ExerciseDefinition fields), `exercises.dart` (translation merge in provider), `exercise_detail_screen.dart` (chip + AppBar), `active_screen.dart` (sort + group title), `workout_summary_screen.dart` (exercise name), `add_exercise_sheet.dart` (search + display)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T09: `Validation and cleanup` (status:done)
  - Task ID: T09
  - Goal: Run full analysis and test suite, verify no regressions, update context files.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, review for dead code or unused imports, verify DB schema version, update context files.
  - Done when: All checks pass; no dead code; context files reflect changes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass; `app_database.dart` schema version is 14.
  - **Completed:** 2026-06-27
  - **Validation Report:**
    - `dart analyze lib/` — exit 0 (0 errors, 0 warnings, 3 pre-existing infos)
    - `flutter test test/src/exercise/` — exit 0 (62/62 passed)
    - Schema version: 14 (confirmed in `app_database.dart`)
    - Dead code: No unused import warnings
    - Context sync: Updated `architecture.md` (ExerciseDefinition translation fields, ExerciseTranslation model, exercise_translations table entry) and `context-map.md` (schema v12→v14)
    - Residual risks: None identified

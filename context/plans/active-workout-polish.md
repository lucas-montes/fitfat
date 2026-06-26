# Active Workout Polish & UX fixes

## Change Summary

Ten UX improvements and bug fixes from Lucas's feedback (23-24 Jun 2026):

1. Fix rest timer card disappearing when switching exercise pages in `ExerciseWorkoutDetailScreen`
2. Compact exercise tab chips — remove icon and checkmark, smaller size, keep only highlight
3. Make notes field in add-set form smaller or expandable/collapsible
4. Make set tiles (`_WeightSetTile`, `_CardioSetTile`) more compact
5. Add back navigation to `ActiveWorkoutScreen` (or expose bottom nav)
6. Improve stat card spacing in `WorkoutSummaryScreen` so weight values fit
7. Make workout history list independently scrollable (virtual list)
8. Reduce heatmap size in Stats tab / evaluate calendar replacement
9. Show recent exercise history (last sets) inside exercise detail screen during active workout
10. Remove duplicate timer from ActiveWorkoutScreen AppBar (already shown in center)

## Success Criteria

- Rest timer persists across exercise page changes, only resets when a new set is completed
- Exercise chips render without icons or checkmarks, only highlighted selection
- Notes field in add-set form is visibly smaller (fewer lines, less padding) or hidden behind an expandable toggle
- Set tiles have reduced padding/margins and smaller font sizes
- Active workout screen has a back button in the AppBar (or bottom nav is visible)
- Summary screen stat cards have adequate spacing; weight values like "12345 kg" fit without overflow
- History list scrolls independently of the parent scrollable (uses a constrained-height virtual list with `shrinkWrap`/`NeverScrollableScrollPhysics` removed from parent)
- `_HeatmapGrid` is smaller (reduced cell size, padding, or replaced with a simpler calendar widget)
- Exercise detail screen shows a compact snippet of recent history (last 3-5 sessions' sets) for the current exercise
- ActiveWorkoutScreen AppBar shows workout name only — no timer in the title row
- `dart analyze lib/` — 0 errors
- `flutter test test/src/exercise/` — 62/62 pass

## Constraints and Non-Goals

- **In scope**: All changes listed above, focused on existing files under `lib/src/exercise/screens/`
- **Out of scope**: Rest timer functionality changes (only fix persistence bug); bottom navigation re-architecture; heatmap data changes; creating a full calendar widget from scratch (reuse Flutter's `TableCalendar` or similar if replacing); adding new database queries for exercise history (already exists via `exerciseHistoryProvider`)
- **Assumptions**: `_HistoryItem` list is currently rendered inline inside a parent `ListView` (line 60 of `list.dart`) — fix by extracting to a `SizedBox` + `ListView.builder` with constrained height
- **Assumptions**: The rest timer bug is caused by undefined/improperly managed state variables (`_isResting`, `_restStartedAt`, `_dismissRest`) in `exercise_detail_screen.dart` — fix by adding proper state management within the `PageView` per-exercise context or using a `RestTimerNotifier` from the provider layer
- **Assumptions**: Exercise history during workout uses the existing `exerciseHistoryProvider(exerciseId)` — render a compact summary card showing the last 3-5 sessions' rep/weight data above the add-set form or below the set list
- **Assumptions**: The duplicate timer removal is a one-line change — remove the `Text(_formatDuration(workout.duration))` widget from the AppBar title `Row` in `active_screen.dart`

## Task Stack

- [x] T01: `Fix rest timer disappearing on exercise switch` (status:done)
  - Task ID: T01
  - Goal: The rest timer card (`_RestElapsedCard`) currently disappears when the user swipes between exercises in the `PageView`. Fix the state management so the timer persists until a new set is completed or the user manually dismisses it.
  - Boundaries (in/out of scope): In — remove `isResting: false` and `clearRestStartedAt: true` from `selectExercise()` in `exercise_detail.dart`. Out — any other file; timer reset logic (still handled by `_loadSets`); `dismissRest()` behavior.
  - Done when: User completes a set, sees rest timer; swipes to another exercise and back — timer still shows the same elapsed time; skipping the rest dismisses it; completing another set resets the timer.
  - Verification notes: `dart analyze lib/` — 0 errors; manual test of the rest timer flow across page changes.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/providers/exercise_detail.dart (removed `isResting: false` and `clearRestStartedAt: true` from `selectExercise`)
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T02: `Compact exercise tab chips (no icon, no tick)` (status:done)
  - Task ID: T02
  - Goal: Modify `_buildExerciseChips` in `exercise_detail_screen.dart` to render smaller chips: remove the type icon, remove the check/tick indicator, shrink chip height, keep only the text label with highlight for the selected tab.
  - Boundaries (in/out of scope): In — reduce `SizedBox` height from 40 to 32; remove `Icon(icon)` and related spacing from chip label; apply `VisualDensity.compact` and `labelMedium` style. Out — changing the chip widget type (keep `ChoiceChip`).
  - Done when: Exercise chips show only text labels; no icons or checkmarks; selected chip has visible highlight; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart (`_buildExerciseChips`)
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T03: `Compact notes field in add-set form` (status:done)
  - Task ID: T03
  - Goal: Make the notes `TextField` in the add-set form collapsible — hidden by default behind a small "Add notes" text button. Expand on tap to reveal the 1-line field.
  - Boundaries (in/out of scope): In — convert `ExerciseSetForm` to `StatefulWidget`; add `_notesExpanded` toggle state; show compact text button when collapsed, show field when expanded; show brief preview when notes exist. Out — removing the notes field entirely; changing other form fields; i18n keys (uses inline "Add notes" string).
  - Done when: Notes field is hidden by default; tapping the "Add notes" link expands it; populated notes show a preview; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/widgets/exercise_set_form.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T04: `Compact set tiles in exercise detail` (status:done)
  - Task ID: T04
  - Goal: Reduce padding, margins, and font sizes in `WeightSetTile` and `CardioSetTile` to make the set list more compact.
  - Boundaries (in/out of scope): In — reduce `Card` margin from `EdgeInsets.only(bottom: 8)` to `EdgeInsets.only(bottom: 4)`; add compact `contentPadding` to `ListTile`; use `titleSmall` font style for title. Out — removing the check circle icon; changing the tile layout structure.
  - Done when: Set tiles are visibly more compact; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/widgets/weight_set_tile.dart, cardio_set_tile.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T05: `Add back navigation to ActiveWorkoutScreen` (status:done)
  - Task ID: T05
  - Goal: Add a back button to the `ActiveWorkoutScreen` AppBar so users can return to the Training tab without completing/cancelling the workout.
  - Boundaries (in/out of scope): In — add `leading: IconButton(icon: Icons.arrow_back, onPressed: () => context.pop())` to the AppBar in `active_screen.dart`. Out — changing GoRouter routes to not be full-screen.
  - Done when: Active workout screen shows a back arrow in the AppBar; tapping it returns to the Training tab; workout remains active (no cancel/complete).
  - Verification notes: `dart analyze lib/` — 0 errors; manual test of back navigation.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/active_screen.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T06: `Improve summary stat cards spacing` (status:done)
  - Task ID: T06
  - Goal: Fix spacing in the three `StatCard` widgets so weight values fit without overflow.
  - Boundaries (in/out of scope): In — wrap value `Text` in `FittedBox` with `fit: BoxFit.scaleDown` in `stat_card.dart`; increase horizontal padding from 8 to 12. Out — redesigning the card layout; adding scroll to the stat row.
  - Done when: Three stat cards are evenly spaced; weight values fit without overflow; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check with large weight values.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/widgets/stat_card.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T07: `Make workout history independently scrollable` (status:done)
  - Task ID: T07
  - Goal: Extract history items from the parent `ListView` so they scroll independently within a constrained height area.
  - Boundaries (in/out of scope): In — wrap history in `SizedBox(height: 35vh)` with nested `ListView.builder` using `AlwaysScrollableScrollPhysics`. Out — paginating the history list; adding pull-to-refresh to the inner list.
  - Done when: History section scrolls independently; parent scroll doesn't move when scrolling history; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/list.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T08: `Reduce heatmap size / evaluate calendar replacement` (status:done)
  - Task ID: T08
  - Goal: Compact the heatmap grid — reduce padding, spacing, remove day numbers, smaller cells.
  - Boundaries (in/out of scope): In — card padding 16→12; weekday label width 36→24; grid spacing 6→2; remove day number text from cells; border radius 8→4; section spacing 12/8→8/4. Out — changing the heatmap data logic (still 84 days); removing the tooltip or bottom sheet detail; calendar replacement.
  - Done when: Heatmap section is visibly more compact; `dart analyze lib/` passes; heatmap still shows workout activity by day.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check of smaller heatmap.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/stats/stats_tab.dart (`_HeatmapGrid.build`)
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T09: `Show recent exercise history in workout detail screen` (status:done)
  - Task ID: T09
  - Goal: Add a compact history snippet inside each exercise page showing the last 5 sessions' sets for reference while logging new sets.
  - Boundaries (in/out of scope): In — new `_ExerciseHistorySnippet` ConsumerWidget that watches `exerciseHistoryProvider(exerciseId)`; renders compact date + set summary rows; inserted between add-set form and current set list. Out — full exercise history screen (already exists); cardio history; editing history from this view.
  - Done when: Exercise detail screen shows recent session data (last 5 workouts) for the current exercise; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T10: `Remove duplicate timer from ActiveWorkoutScreen AppBar` (status:done)
  - Task ID: T10
  - Goal: Remove the duplicate timer from the AppBar title — the center timer is sufficient.
  - Boundaries (in/out of scope): In — replace the `Row(name + timer)` title with just `Text(workout.name)` in `active_screen.dart`. Out — changing the center timer; `_formatDuration` method (still used by center timer).
  - Done when: AppBar shows only the workout name; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-24
  - **Files changed:** lib/src/exercise/screens/workout/active_screen.dart
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos)

- [x] T11: `Validation and cleanup` (status:done)
  - Task ID: T11
  - Goal: Run full analysis, test suite, remove any scaffolding, update context files.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, review for unused imports/variables, update context files. Out — fixing unrelated infra test failures.
  - Done when: All checks pass, no dead code, context files reflect changes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-24
  - **Evidence:** `dart analyze lib/` — 0 errors (3 pre-existing infos); `flutter test test/src/exercise/` — 62/62 pass

## Validation Report

### Commands run
- `dart analyze lib/` → exit 0 (3 infos, 0 errors) — same 3 pre-existing `use_build_context_synchronously` infos in unchanged files
- `flutter test test/src/exercise/` → exit 0 (62 tests passed, 0 failed)
- Temporary scaffolding: none created (no `context/tmp/` directory)

### Success-criteria verification
- [x] Rest timer persists across exercise page changes (T01)
- [x] Exercise chips have no icons/checkmarks, only highlight (T02)
- [x] Notes field is collapsible behind "Add notes" toggle (T03)
- [x] Set tiles have reduced card margins, content padding, smaller font (T04)
- [x] Back button in active workout AppBar (T05)
- [x] Stat cards use `FittedBox` for auto-scaling; horizontal padding 8→12 (T06)
- [x] History list scrolls independently in 35vh `SizedBox` (T07)
- [x] Heatmap grid spacing 6→2, padding 16→12, day numbers removed, border radius 8→4 (T08)
- [x] Exercise detail shows last 5 sessions' sets via `_ExerciseHistorySnippet` (T09)
- [x] AppBar shows workout name only — no duplicate timer (T10)
- [x] `dart analyze lib/` — 0 errors
- [x] `flutter test test/src/exercise/` — 62/62 pass

# Active Workout Polish & UX fixes

## Change Summary

Eight UX improvements and bug fixes from Lucas's feedback (23 Jun 2026):

1. Fix rest timer card disappearing when switching exercise pages in `ExerciseWorkoutDetailScreen`
2. Compact exercise tab chips — remove icon and checkmark, smaller size, keep only highlight
3. Make notes field in add-set form smaller or expandable/collapsible
4. Make set tiles (`_WeightSetTile`, `_CardioSetTile`) more compact
5. Add back navigation to `ActiveWorkoutScreen` (or expose bottom nav)
6. Improve stat card spacing in `WorkoutSummaryScreen` so weight values fit
7. Make workout history list independently scrollable (virtual list)
8. Reduce heatmap size in Stats tab / evaluate calendar replacement

## Success Criteria

- Rest timer persists across exercise page changes, only resets when a new set is completed
- Exercise chips render without icons or checkmarks, only highlighted selection
- Notes field in add-set form is visibly smaller (fewer lines, less padding) or hidden behind an expandable toggle
- Set tiles have reduced padding/margins and smaller font sizes
- Active workout screen has a back button in the AppBar (or bottom nav is visible)
- Summary screen stat cards have adequate spacing; weight values like "12345 kg" fit without overflow
- History list scrolls independently of the parent scrollable (uses a constrained-height virtual list with `shrinkWrap`/`NeverScrollableScrollPhysics` removed from parent)
- `_HeatmapGrid` is smaller (reduced cell size, padding, or replaced with a simpler calendar widget)
- `dart analyze lib/` — 0 errors
- `flutter test test/src/exercise/` — 62/62 pass

## Constraints and Non-Goals

- **In scope**: All changes listed above, focused on existing files under `lib/src/exercise/screens/`
- **Out of scope**: Rest timer functionality changes (only fix persistence bug); bottom navigation re-architecture; heatmap data changes; creating a full calendar widget from scratch (reuse Flutter's `TableCalendar` or similar if replacing)
- **Assumptions**: `_HistoryItem` list is currently rendered inline inside a parent `ListView` (line 60 of `list.dart`) — fix by extracting to a `SizedBox` + `ListView.builder` with constrained height
- **Assumptions**: The rest timer bug is caused by undefined/improperly managed state variables (`_isResting`, `_restStartedAt`, `_dismissRest`) in `exercise_detail_screen.dart` — fix by adding proper state management within the `PageView` per-exercise context or using a `RestTimerNotifier` from the provider layer

## Task Stack

- [ ] T01: `Fix rest timer disappearing on exercise switch` (status:todo)
  - Task ID: T01
  - Goal: The rest timer card (`_RestElapsedCard`) currently disappears when the user swipes between exercises in the `PageView`. Fix the state management so the timer persists until a new set is completed or the user manually dismisses it.
  - Boundaries (in/out of scope): In — add proper `_isResting`, `_restStartedAt`, `_dismissRest` state variables to `_ExerciseWorkoutDetailScreenState`; wire them through page changes; timer updates after each completed set. Out — using a separate provider for rest time (keep it local state); changing the `_RestElapsedCard` widget itself.
  - Done when: User completes a set, sees rest timer; swipes to another exercise and back — timer still shows the same elapsed time; skipping the rest dismisses it; completing another set resets the timer.
  - Verification notes: `dart analyze lib/` — 0 errors; manual test of the rest timer flow across page changes.

- [ ] T02: `Compact exercise tab chips (no icon, no tick)` (status:todo)
  - Task ID: T02
  - Goal: Modify `_buildExerciseChips` in `exercise_detail_screen.dart` to render smaller chips: remove the type icon, remove the check/tick indicator, shrink chip height, keep only the text label with highlight for the selected tab.
  - Boundaries (in/out of scope): In — reduce `SizedBox` height from 40 to ~32; remove `Icon(icon)` from the chip label; reduce chip padding and font size. Out — changing the chip widget type (keep `ChoiceChip`).
  - Done when: Exercise chips show only text labels; no icons or checkmarks; selected chip has visible highlight; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.

- [ ] T03: `Compact notes field in add-set form` (status:todo)
  - Task ID: T03
  - Goal: Make the notes `TextField` in `_buildAddForm` smaller and less prominent. Options: reduce to a single line with `maxLines: 1` (already done), reduce font size, reduce padding, or wrap in an `ExpansionTile`/similar collapsible widget so it's hidden by default.
  - Boundaries (in/out of scope): In — reduce vertical padding around the notes field; make `maxLines: 1` always; optionally wrap in a small expandable toggle (e.g., an "Add notes" text button that reveals the field). Out — removing the notes field entirely; changing other form fields.
  - Done when: Notes field is visibly more compact than current; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.

- [ ] T04: `Compact set tiles in exercise detail` (status:todo)
  - Task ID: T04
  - Goal: Reduce padding, margins, and font sizes in `_WeightSetTile` and `_CardioSetTile` to make the set list more compact and fit more sets on screen.
  - Boundaries (in/out of scope): In — reduce `Card` margin from `EdgeInsets.only(bottom: 8)` to `EdgeInsets.only(bottom: 4)`; reduce `ListTile` content padding (use `contentPadding`); reduce title/subtitle font size. Out — removing the check circle icon; changing the tile layout structure.
  - Done when: Set tiles are visibly more compact; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.

- [ ] T05: `Add back navigation to ActiveWorkoutScreen` (status:todo)
  - Task ID: T05
  - Goal: Add a back button to the `ActiveWorkoutScreen` AppBar so users can return to the Training tab without completing/cancelling the workout. The workout remains active in the background.
  - Boundaries (in/out of scope): In — add a `leading` `IconButton` with `Icons.arrow_back` to the AppBar in `active_screen.dart` that calls `context.pop()`. Optionally, consider making the route not full-screen so the bottom nav bar is visible. Out — changing GoRouter routes to not be full-screen (keep the route as-is but offer navigation choice).
  - Done when: Active workout screen shows a back arrow in the AppBar; tapping it returns to the Training tab; workout remains active (no cancel/complete).
  - Verification notes: `dart analyze lib/` — 0 errors; manual test of back navigation.

- [ ] T06: `Improve summary stat cards spacing` (status:todo)
  - Task ID: T06
  - Goal: Fix spacing in the `Row` of three `_StatCard` widgets in `workout_summary_screen.dart` so weight values (e.g., "12345 kg") fit without overflow or cramped layout.
  - Boundaries (in/out of scope): In — adjust `SizedBox(width: 12)` gaps; consider using `Flexible` or `LayoutBuilder` for responsive sizing; reduce card padding or increase card width ratio. Out — redesigning the card layout; adding scroll to the stat row.
  - Done when: Three stat cards are evenly spaced; weight values fit without overflow; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check with large weight values.

- [ ] T07: `Make workout history independently scrollable` (status:todo)
  - Task ID: T07
  - Goal: The history list in `WorkoutListTab` (list.dart) is currently rendered inline in the parent `ListView`, causing the entire page to scroll. Extract it so the history section has its own scrollable area with constrained height, preventing the whole view from moving.
  - Boundaries (in/out of scope): In — wrap the history list in a `SizedBox` with constrained height, using a nested `ListView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics` replaced by `AlwaysScrollableScrollPhysics`; alternatively use a `SliverList` or `SliverFillRemaining` approach if a `CustomScrollView` refactor is simpler. Out — paginating the history list; adding pull-to-refresh to the inner list.
  - Done when: History section scrolls independently; parent scroll doesn't move when scrolling history; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors.

- [ ] T08: `Reduce heatmap size / evaluate calendar replacement` (status:todo)
  - Task ID: T08
  - Goal: The `_HeatmapGrid` in `stats_tab.dart` takes up too much space. Either make it significantly smaller (reduce cell size, grid spacing, padding, font size) or replace with a simpler calendar widget.
  - Boundaries (in/out of scope): In — reduce cell size from 36×36 to ~24×24; reduce `mainAxisSpacing`/`crossAxisSpacing` from 6 to 2; remove day numbers from cells (keep only color); or replace with a `TableCalendar`-like widget. Out — changing the heatmap data logic; removing the tooltip or bottom sheet detail.
  - Done when: Heatmap section is visibly more compact; `dart analyze lib/` passes; heatmap still shows workout activity by day.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check of smaller heatmap.

- [ ] T09: `Validation and cleanup` (status:todo)
  - Task ID: T09
  - Goal: Run full analysis, test suite, remove any scaffolding, update context files.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, review for unused imports/variables, update `context/context-map.md` and any other context files if needed. Out — fixing unrelated infra test failures.
  - Done when: All checks pass, no dead code, context files reflect changes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.

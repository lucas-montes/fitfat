# Plan: Fix Training tab always showing full-screen empty state

## Change Summary

The Training tab (`WorkoutListTab`) always shows a full-screen centered empty state (icon + "no workouts yet" text + start button) when both upcoming and history lists are empty, instead of showing the expected three-section layout with each section gracefully handling its own empty/missing-data case.

## Root Cause (v2, corrected)

In `WorkoutListTab._buildBody()` (list.dart), the code had an `if (upcoming.isEmpty && history.isEmpty)` short-circuit that replaced the entire three-section layout with a monolithic `_emptyState` widget when both lists were empty. This meant:

1. **Today's Card** (which already handles `todayWorkout == null` by showing a free-form start prompt) was completely hidden
2. **Upcoming section** was hidden when `upcomingLater` was empty (via `if (upcomingLater.isNotEmpty)`)
3. **History section** was hidden when `history` was empty (via `if (history.isNotEmpty)`)

Additionally, the loading/error states returned bare `Center`/`CircularProgressIndicator` widgets which are not scrollable, potentially causing `RefreshIndicator` assertion errors in debug mode — though the primary visible issue was the full-screen empty state.

## What the user wants

The three-section layout must **always** be visible:
1. **Top card** — Shows today's scheduled workout with "Start" button, OR free-form prompt when none scheduled
2. **Upcoming carousel** — Horizontal scrollable cards, OR "no planned workouts" text when empty
3. **History list** — Completed workout entries, OR "no history yet" text when empty

## Success Criteria

- Three sections always render (today card, upcoming, history) — never replaced by a monolithic empty state
- Today's card shows scheduled workout with Start button when available, free-form prompt otherwise
- Upcoming section shows carousel when data exists, "no planned workouts" text when empty
- History section shows list when data exists, "no history yet" text when empty
- Loading state shows centered spinner (inside scrollable for RefreshIndicator compatibility)
- Error state shows centered error message (inside scrollable for RefreshIndicator compatibility)
- `dart analyze lib/` — 0 errors
- `flutter test test/src/exercise/` — 62/62 pass

## Constraints and Non-Goals

- **In scope**: Restructuring `_buildBody` to always show the three-section layout; adding empty-state placeholders for upcoming and history sections; removing early-return empty state
- **Out of scope**: Changing provider logic, data fetching, or DB layer; redesigning layout or adding features

## Task Stack

- [x] T01: `Always render three-section layout, remove full-screen empty state` (status:done)
  - Task ID: T01
  - Goal: Remove the `if (upcoming.isEmpty && history.isEmpty)` early-return so the three-section layout always renders. Add `else` branches to upcoming and history sections showing empty-state text when no data exists.
  - Boundaries (in/out of scope): In — restructure build method, remove `_emptyState` method, add localized empty placeholders (`l10n.noPlannedWorkoutsForDay`, `l10n.noHistory`). Out — touching provider logic, data layer, or other files.
  - Done when: Three sections always visible; empty placeholders show for empty sections; loading/error states wrapped in scrollable; unused `_emptyState` removed.
  - Verification notes: `dart analyze lib/` — 0 errors; visual check shows three sections with empty-state text when no data.

- [x] T02: `Validation and cleanup` (status:done)
  - Task ID: T02
  - Goal: Run full analysis, test suite, and synchronize context files.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, update context files. Out — fixing unrelated infra test failures.
  - Done when: All checks pass, context files reflect current state.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.

## Validation Report

### Commands run
- `dart analyze lib/src/exercise/screens/workout/list.dart` → exit 0 (no issues found)
- `dart analyze lib/` → exit 0 (0 errors, 4 infos — pre-existing)
- `flutter test test/src/exercise/` → exit 0 (62/62 passed)

### Success-criteria verification
- [x] Three-section layout **always** renders — no more `if (upcoming.isEmpty && history.isEmpty)` short-circuit
- [x] Today's card shows scheduled workout or free-form prompt (handled by `_TodayCard` which was already correct)
- [x] Upcoming section shows carousel when data exists, `l10n.noPlannedWorkoutsForDay` when empty
- [x] History section shows list when data exists, `l10n.noHistory` when empty
- [x] Loading state wrapped in `ListView` for scrollability
- [x] Error state wrapped in `ListView` for scrollability
- [x] Removed unused `_emptyState` method
- [x] `dart analyze lib/` — 0 errors
- [x] `flutter test test/src/exercise/` — 62/62 pass

### Files changed
- `lib/src/exercise/screens/workout/list.dart`
  - Removed `if (upcoming.isEmpty && history.isEmpty)` early-return branch
  - Removed `_emptyState()` method
  - Upcoming section: always renders with `else` branch showing "No planned workouts for this day"
  - History section: always renders with `else` branch showing `l10n.noHistory`
  - Loading/error states wrapped in `ListView` for `RefreshIndicator` compatibility

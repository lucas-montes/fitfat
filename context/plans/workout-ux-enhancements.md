# Plan: Workout UX Enhancements

## Change Summary

Six UX improvements to the workout flow: (1) auto-complete sets in free-form, show completed time, reverse display order (most recent first); (2) live timer on the Training tab's top card; (3) post-workout summary screen; (4) history workout detail view; (5) swipe between exercises in the detail screen; (6) elapsed rest timer showing time since last completed set.

## Success Criteria

- Free-form workout sets are auto-completed on creation (green check icon).
- The top card elapsed timer ticks every second while a workout is active.
- Completing a workout shows a summary screen with workout stats (duration, exercises, sets, volume) and a "Done" button that returns to the Training tab.
- Tapping a completed workout in history shows a detail view with exercises and sets.
- In the exercise detail screen, swiping left/right navigates between exercises of the active workout via tab-style chips at the top.
- After adding or completing a set, an elapsed rest timer shows time since the last completed set (no countdown, just elapsed time).
- Sets are displayed most-recent-first (reverse sort order), with each set showing its completion/creation time.
- `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — all pass.

## Design Decisions (confirmed with user)

1. **Exercises appear only when they have sets** — There is no separate exercise-workout mapping. An exercise is "in" a workout only when at least one set references it. This is a deliberate design constraint; no schema changes will be made to add a mapping table. To add an exercise without immediate sets, navigate to the detail screen via the Add Exercise sheet and use the inline form there.
2. **Removing exercises** is equivalent to deleting all its sets — this is already possible via individual set deletion (long-press → Delete in the detail screen). No dedicated "remove exercise" action is needed.
3. **Post-workout summary** includes: workout name, duration, exercise list with set counts, total volume. Has a "Done" button → goes to Training tab.
4. **Swipe header style**: tab-style chips row at the top showing exercise names, active one highlighted.
5. **Rest timer**: shows elapsed time since the last completed set (no countdown, just a live timer tracking rest duration).

## Constraints and Non-goals

- No new DB schema changes. New screens are pure UI.
- Minimize new localization strings (reuse existing).
- No changes to scheduled/guided workout logic.
- No live-ticking timer on history detail screen (static snapshot).
- No editing past workouts from history.

## Task Stack

### T01: Auto-complete sets, show time, reverse display order

- **Task ID:** T01
- **Goal:** Three changes to set display in `ExerciseWorkoutDetailScreen`:
  1. **Auto-complete**: New sets added via inline form are automatically marked completed (`actualReps=plannedReps`, `actualWeightKg=plannedWeightKg`, `completedAt=DateTime.now()` for weight; `actualDurationMinutes=plannedDurationMinutes` for cardio).
  2. **Show time**: Each set tile shows its completion time (e.g. "14:32" from `completedAt`).
  3. **Reverse order**: Sets display most-recent-first (currently oldest-first via `sortOrder ASC`; reverse the list after loading).
- **Boundaries (in/out of scope):** In — changes to `_addSetFromForm()`, `_WeightSetTile`, `_CardioSetTile`, and set list rendering in `lib/src/exercise/screens/workout/exercise_detail_screen.dart`. Out — affecting guided/scheduled workout sets; changing the edit dialog.
- **Done when:** Adding a set via inline form shows green check icon + completion time; sets appear most-recent-first; `dart analyze` passes.
- **Verification notes:** `dart analyze lib/` — 0 errors; add multiple sets, verify newest is first and shows time.
- **Status:** done
- **Completed:** 2026-06-20
- **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart
- **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

### T02: Live timer on Training tab top card

- **Task ID:** T02
- **Goal:** The `_TodayCard` currently shows a static snapshot of elapsed time. Extract the timer display into a small `StatefulWidget` with `Timer.periodic(Duration(seconds: 1))` that rebuilds the display every second.
- **Boundaries (in/out of scope):** In — changes to `lib/src/exercise/screens/workout/list.dart`. Out — changes to the active workout screen (already live); workout model changes.
- **Done when:** Top card elapsed time increments every second during an active workout; static when no workout is active; `dart analyze` passes.
- **Verification notes:** `dart analyze lib/` — 0 errors; start free-form, go to Training tab, watch timer tick.
- **Status:** done
- **Completed:** 2026-06-20
- **Files changed:** lib/src/exercise/screens/workout/list.dart
- **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

### T03: Post-workout summary screen

- **Task ID:** T03
- **Goal:** After completing a workout, navigate to a summary screen instead of popping back. Create `WorkoutSummaryScreen` showing: workout name, total duration, list of exercises with set counts, total volume. Add route `/workout-summary/:id`. Update `ActiveWorkoutScreen._complete()` to navigate to summary. "Done" button goes to `/exercise` (Training tab root).
- **Boundaries (in/out of scope):** In — new screen file; new GoRoute in `router.dart`; modify `_complete()` in `active_screen.dart`. Out — editing workout after completion; sharing/exporting.
- **Done when:** Completing a workout navigates to summary with correct stats; "Done" goes to Training tab; `dart analyze` passes.
- **Verification notes:** `dart analyze lib/` — 0 errors; complete a workout, verify summary screen appears with correct data.
- **Status:** done
- **Completed:** 2026-06-20
- **Files changed:** lib/src/exercise/screens/workout/workout_summary_screen.dart (new), lib/src/app/router.dart, lib/src/exercise/screens/workout/active_screen.dart
- **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

### T04: History workout detail view

- **Task ID:** T04
- **Goal:** Tapping a `_HistoryItem` in the history list navigates to a detail screen showing the completed workout's exercises and sets. Create `WorkoutHistoryDetailScreen` that loads the workout by ID and displays its sets grouped by exercise. Add route `/workout-history/:id`. Update `_HistoryItem.onTap` in `list.dart`.
- **Boundaries (in/out of scope):** In — new screen file; new GoRoute; update `_HistoryItem`. Out — edit/delete on history items.
- **Done when:** Tapping a history item shows workout's date, duration, exercises, and sets; `dart analyze` passes.
- **Verification notes:** `dart analyze lib/` — 0 errors; complete a workout, tap it in history, verify detail view.
- **Status:** done
- **Completed:** 2026-06-20
- **Files changed:** lib/src/exercise/screens/workout/workout_history_detail_screen.dart (new), lib/src/app/router.dart, lib/src/exercise/screens/workout/list.dart
- **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

### T05: Swipe between exercises in detail screen

- **Task ID:** T05
- **Goal:** In `ExerciseWorkoutDetailScreen`, wrap the body in a `PageView` that allows swiping left/right between exercises of the active workout. Add a horizontal tab-style chip row at the top showing exercise names (active one highlighted). Use `PageController` to sync tab selection with the current page.
- **Boundaries (in/out of scope):** In — modifications to `ExerciseWorkoutDetailScreen`; load all exercise IDs for the workout; implement `PageView` with chip tabs. Out — animated transitions beyond standard swipe.
- **Done when:** Swiping left/right navigates between exercises; each page shows the correct exercise's form + sets; chip row shows/highlights the active exercise; `dart analyze` passes.
- **Verification notes:** `dart analyze lib/` — 0 errors; add 2+ exercises with sets, navigate to detail screen, swipe between them.
- **Status:** done
- **Completed:** 2026-06-20
- **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart
- **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

### T06: Elapsed rest timer (time since last set)

- **Task ID:** T06
- **Goal:** After adding or completing a set in `ExerciseWorkoutDetailScreen`, show a live elapsed timer displaying how long the user has been resting since the last completed set. This is NOT a countdown — it counts **up** from the last set's `completedAt`. Display a persistent card at the top of the detail screen showing: "Rest: 1:23" (mm:ss format ticking every second), a "Skip" button to dismiss. Wire in the existing `restTimerProvider` but repurpose it for elapsed (count-up) mode. Store the last set's `completedAt` timestamp; on each tick, compute `DateTime.now().difference(lastCompletedAt)`. Stop the timer when the user adds/edits another set.
- **Boundaries (in/out of scope):** In — changes to `ExerciseWorkoutDetailScreen`; modify or extend `restTimerProvider` to support elapsed/count-up mode; show elapsed card. Out — per-exercise rest settings; countdown timer.
- **Done when:** Adding or completing a set shows "Rest: mm:ss" ticking up each second; "Skip" dismisses it; timer resets on next set action; `dart analyze` passes.
- **Verification notes:** `dart analyze lib/` — 0 errors; add a set, verify elapsed rest timer appears and ticks up; tap Skip to dismiss.
- **Status:** done
- **Completed:** 2026-06-20
- **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart
- **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

### T07: Validation and cleanup

- **Task ID:** T07
- **Goal:** Run full analysis and tests, verify all tasks are complete, update plan with evidence.
- **Boundaries (in/out of scope):** In — `dart analyze lib/`, `flutter test test/src/exercise/`, verify build succeeds. Out — new tests for new features.
- **Done when:** All checks pass; plan marked complete.
- **Verification notes:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — all pass; `flutter build apk --debug` — succeeds.

## Task Dependencies

```
T01 → T06 (elapsed rest timer needs completedAt on sets)
All other tasks (T02-T05) are independent of each other.

Recommended implementation order:
1. T01 — auto-complete sets + time + reverse order
2. T02 — live timer on top card
3. T03 — post-workout summary screen
4. T04 — history detail view
5. T05 — swipe between exercises
6. T06 — elapsed rest timer
7. T07 — validation

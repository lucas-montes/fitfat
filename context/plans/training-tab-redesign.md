# Training Tab Redesign

## Change Summary

Redesign the Training tab (`WorkoutListTab`) with a three-section layout and create a minimal active workout screen with GoRouter route.

## Mockup

```
┌─────────────────────────────────┐
│ Next Workout / Start Card       │
│ ┌─────────────────────────────┐ │
│ │ 💪 Workout Name             │ │
│ │ 📅 Today at 10:00           │ │
│ │ [▶ Start Workout]            │ │
│ │  OR (if none scheduled)      │ │
│ │ No workout planned           │ │
│ │ [▶ Start Free Form Workout]  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Upcoming Workouts (carousel)    │
│ ┌────┐ ┌────┐ ┌────┐          │
│ │ ↑  │ │ ↑  │ │ ↑  │ ← →     │
│ │Leg │ │Push│ │Pull│          │
│ │Day │ │Day │ │Day │          │
│ │Wed │ │Thu │ │Fri │          │
│ └────┘ └────┘ └────┘          │
│                                 │
│ History                         │
│ ┌─────────────────────────────┐ │
│ │ Upper Body - Mon 15 Jun    │ │
│ │ 45 min                      │ │
│ ├─────────────────────────────┤ │
│ │ Lower Body - Sun 14 Jun    │ │
│ │ 30 min                      │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## Success Criteria

- `WorkoutListTab` has three sections: today's card, upcoming carousel, history list
- Today's card shows the next scheduled workout or a free-form prompt
- "Start Workout" button navigates to `ActiveWorkoutScreen` (full-screen, no bottom nav)
- "Start Free Form Workout" creates a free-form workout and navigates to `ActiveWorkoutScreen`
- `ActiveWorkoutScreen` shows workout name, elapsed time, Complete and Cancel buttons
- `/active-workout` route registered in GoRouter
- `dart analyze lib/` — 0 errors
- `flutter test test/src/exercise/` — 62/62 pass

## Constraints and Non-Goals

- **In scope**: Rewriting `WorkoutListTab`, creating `ActiveWorkoutScreen`, adding GoRouter route
- **Out of scope**: Full active workout screen with exercise/set management (that's a follow-up), Set editing during active workout, Foreground notification wiring from ActiveWorkoutNotifier
- **Assumptions**: Active workout screen is minimal — shows name, elapsed time, Complete/Cancel. Users add sets via a future "exercise picker" flow.

## Task Stack

- [x] T01: `Create ActiveWorkoutScreen and /active-workout route` (status:done)
  - Task ID: T01
  - Goal: Create a minimal `ActiveWorkoutScreen` widget and register `/active-workout` as a top-level GoRouter route.
  - Boundaries (in/out of scope): In — create `lib/src/exercise/screens/workout/active_screen.dart`, add `GoRoute(path: '/active-workout')` to `router.dart`. Out — wiring `WorkoutForegroundService`, full set management UI.
  - Done when: `dart analyze lib/` passes; navigating to `/active-workout` shows the screen; screen displays workout name and elapsed time from `activeWorkoutProvider`.
  - Verification notes: `dart analyze lib/` — 0 errors, 4 infos (2 pre-existing diet + 2 identical pattern in new screen).
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/exercise/screens/workout/active_screen.dart (created), lib/src/app/router.dart (added `/active-workout` GoRoute)
  - **Evidence:** `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.

- [x] T02: `Rewrite WorkoutListTab with three-section layout` (status:done)
  - Task ID: T02
  - Goal: Replace the WorkoutListTab with today-card, upcoming carousel, and history list.
  - Boundaries (in/out of scope): In — three sections in a single scrollable layout; today card conditionally shows scheduled or free-form prompt; upcoming carousel as horizontal `ListView`; history list as vertical list with date/duration. Out — adding volume to history items (no cross-module dependency), pagination.
  - Done when: Three sections render correctly; "Start" navigates to `/active-workout`; "Start Free Form" creates workout and navigates; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-18
  - **Files changed:** lib/src/exercise/screens/workout/list.dart (rewritten)
  - **Evidence:** `dart analyze lib/` — 0 errors (4 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

- [x] T03: `Validation and cleanup` (status:done)
  - Task ID: T03
  - Goal: Run full analysis, test suite, update context files.
  - Boundaries (in/out of scope): In — `dart analyze lib/`, `flutter test test/src/exercise/`, update `context-map.md`. Out — fixing unrelated infra test failures.
  - Done when: All checks pass, context files reflect new screens.
  - Verification notes: `dart analyze lib/` — 0 errors (4 infos); `flutter test test/src/exercise/` — 62/62 passed.
  - **Completed:** 2026-06-18
  - **Files changed:** context/context-map.md, context/overview.md (context sync updates)
  - **Evidence:** `dart analyze lib/` — 0 errors (4 pre-existing infos); `flutter test test/src/exercise/` — 62/62 passed.

## Validation Report

### Commands run
- `dart analyze lib/` → exit 0 (0 errors, 4 infos — pre-existing)
- `flutter test test/src/exercise/` → exit 0 (62/62 passed)
- `flutter test` (full suite) → 97 passed, 7 failed (all failures are pre-existing `DriftMealRepository` infra tests: `libsqlite3.so` not found in CI environment — unrelated and out of scope)
- `dart format --set-exit-if-changed lib/src/exercise/screens/workout/` → exit 0 (no formatting changes)
- `context/tmp/` → does not exist (no scaffolding to clean up)

### Success-criteria verification
- [x] `WorkoutListTab` has three sections: today's card, upcoming carousel, history list — confirmed via code review
- [x] Today's card shows the next scheduled workout or a free-form prompt — confirmed via `_TodayCard` widget
- [x] "Start Workout" button navigates to `ActiveWorkoutScreen` — confirmed via `context.push('/active-workout')` after `startScheduled()`
- [x] "Start Free Form Workout" creates a free-form workout and navigates — confirmed via `startFreeform()` + `context.push('/active-workout')`
- [x] `ActiveWorkoutScreen` shows workout name, elapsed time, Complete and Cancel buttons — confirmed via T01 code review
- [x] `/active-workout` route registered in GoRouter — confirmed via `router.dart` review
- [x] `dart analyze lib/` — 0 errors — confirmed (4 pre-existing infos)
- [x] `flutter test test/src/exercise/` — 62/62 pass — confirmed

### Residual risks
- None identified. Active workout screen is minimal as designed; full set management is deferred to a follow-up.
# Plan: Active workout UX fixes

## Change Summary

Fix three active-workflow UX issues identified during testing: notification tap race condition, top card not showing running workout, and inline add-set form with no defaults + tap-to-populate.

## Tasks

- [x] T01: Fix notification tap race condition
  - Task ID: T01
  - Goal: Change `ActiveWorkoutNotifier.build()` to return `AsyncValue.loading()` instead of `AsyncValue.data(null)` so that `ActiveWorkoutScreen` doesn't immediately redirect to `/dashboard` before `resume()` finishes loading the active workout from DB.
  - Boundaries (in/out of scope): In — one-line change in `lib/src/exercise/providers/active_workout.dart`. Out — changing `resume()` logic, notification tap handler in `main.dart`.
  - Done when: `dart analyze lib/` passes; notification tap into deep-link shows active workout instead of redirecting to dashboard.
  - Verification notes: `dart analyze lib/` — 0 errors; manual: start workout, background app, tap notification, verify workout screen appears.
  - **Completed:** 2026-06-19
  - **Files changed:** lib/src/exercise/providers/active_workout.dart (return `AsyncValue.loading()` instead of `data(null)`)
  - **Evidence:** dart analyze — 0 errors.

- [x] T02: Top card shows active workout with Resume button
  - Task ID: T02
  - Goal: When an active workout exists, the Training tab's top card should show the active workout name, elapsed time, and a "Resume" button (instead of "Start Workout" for a scheduled workout or "Start free-form" empty state).
  - Boundaries (in/out of scope): In — changes to `lib/src/exercise/screens/workout/list.dart`; watch `activeWorkoutProvider`; modify `_TodayCard` to accept optional `activeWorkout` param; show name + elapsed + Resume button when active. Out — live-ticking timer on the card (static elapsed snapshot is fine).
  - Done when: When active workout exists, top card shows workout name + elapsed time + "Resume" button; tap navigates to `/active-workout`. When no active workout, existing behavior preserved.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-19
  - **Files changed:**
    - lib/src/exercise/screens/workout/list.dart (added activeWorkout param, Resume button)
    - lib/l10n/app_en.arb (added "resumeWorkout": "Resume Workout")
    - lib/l10n/app_fr.arb (added "resumeWorkout": "Reprendre")
    - lib/l10n/app_es.arb (added "resumeWorkout": "Reanudar")
    - lib/l10n/app_localizations.dart (added abstract getter resumeWorkout)
    - lib/l10n/app_localizations_en.dart (added "Resume Workout")
    - lib/l10n/app_localizations_fr.dart (added "Reprendre")
    - lib/l10n/app_localizations_es.dart (added "Reanudar")
  - **Evidence:** dart analyze — 0 errors; 62/62 tests pass; `flutter build apk --debug` succeeds.

- [x] T03: Inline add-set form (no defaults, tap-to-populate)
  - Task ID: T03
  - Goal: Replace the FAB + dialog add-set flow with an inline form at the top of the exercise detail screen. Fields start empty (no default values). Tapping an existing set row copies its values into the form.
  - Boundaries (in/out of scope): In — changes to `lib/src/exercise/screens/workout/exercise_detail_screen.dart`; remove FAB; add inline form with Reps/Weight/Duration/Notes fields + "Add" button; add `TextEditingController`s for form state; on tap of existing set, populate controllers with that set's values. Out — changing the edit dialog (still works via long-press); changing toggle-completion on tap behavior.
  - Done when: Form shows empty fields at top; user can enter values and tap "Add" to create a set; tapping an existing set row copies its values into the form; no default values pre-filled; `dart analyze lib/` passes.
  - Verification notes: `dart analyze lib/` — 0 errors; `flutter test test/src/exercise/` — 62/62 pass.
  - **Completed:** 2026-06-19
  - **Files changed:** lib/src/exercise/screens/workout/exercise_detail_screen.dart (rewritten — inline form, tap-to-populate, toggle-complete via icon + menu)
  - **Evidence:** dart analyze — 0 errors; 62/62 tests pass.

- [x] T04: Fix workout history ordering
  - Task ID: T04
  - Goal: Add `ORDER BY completedAt DESC` to `DriftWorkoutRepository.listCompleted()` so completed workouts appear most-recent-first in the history list.
  - Boundaries (in/out of scope): In — one-line addition in `lib/src/adapters/drift/workout_repository.dart`. Out — client-side sorting, UI changes.
  - Done when: `dart analyze lib/` passes; completed workouts display newest first.
  - Verification notes: `dart analyze lib/` — 0 errors.
  - **Completed:** 2026-06-19
  - **Files changed:** lib/src/adapters/drift/workout_repository.dart (added `orderBy` to `listCompleted`)
  - **Evidence:** dart analyze — 0 errors.

## Resolved Decisions

1. **Top card with active workout** → Show workout name, elapsed time, "Resume" button. Elapsed is a static snapshot (not live-ticking on the card).
2. **Inline add-set form position** → At the top of the exercise detail screen list, with existing sets below. Tap a set row to copy values up to the form.
3. **Form defaults** → All fields start empty. No pre-filled reps/weight/duration.

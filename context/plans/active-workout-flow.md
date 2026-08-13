# Plan: Active workout flow redesign (unique active view, rest per set, summary)

## Change Summary

Rework the workout interaction model around a **single dedicated active-workout view** and a
start → active → summary workflow, plus two diet/exercise-form UX changes:

1. **Meal tile (diet)**: no edit icon. One tap expands/collapses the ingredient list (dropdown);
   long-press opens the edit form.
2. **Workout form exercise picker**: search-first. No exercises are pre-listed; typing a query shows
   matches to select (multi-select preserved). Adding a set now requires **reps, weight AND rest
   time** (weightlifting) or **duration AND rest time** (cardio) — rest is mandatory for every set.
3. **Rest per set (schema v5)**: `exercise_sets` gains `rest_seconds` (planned rest, required at
   form level) and `actual_rest_seconds` (recorded when the rest period ends/cancels).
4. **Rest auto-start**: completing a set starts the rest timer automatically with that set's planned
   rest, **except** after the last remaining incomplete set. The actual rest taken is recorded back
   onto the set (fallback to planned when the timer runs to completion).
5. **One active-workout view**: new full-screen `ActiveWorkoutScreen` on a top-level route
   `/active-workout` (outside the shell, so the floating bar + NavigationBar are hidden while it is
   open). Workout list (active tap), the floating bar, the dashboard resume chip / continue card,
   and the notification all open **this same** view via `context.go(...)` (no stacked duplicates).
   `WorkoutDetailScreen` becomes the pending (planning) screen only; starting a workout redirects to
   the active view.
6. **Notification tap** opens the active-workout view (`notificationInitialRoute: '/active-workout'`
   + task-data callback when the app is already running).
7. **Completion → summary**: marking the active workout complete stops the notification, records any
   in-flight rest, and redirects to a new `WorkoutSummaryScreen` (route `/workout-summary/:id`).
   The summary shows, per exercise: **average rest time** (mean of recorded actual rest, falling back
   to planned), **total volume (Σ weight × reps)**, **max weight lifted**, and **total reps**
   (cardio: total duration/distance instead of volume/max-weight). The summary is **re-openable** by
   tapping a completed workout in the list (replaces the old completed read-only detail).

Decisions resolved with the user (2026-08-08): rest is **required** for every set; summary shows
**both** volume and max weight per exercise; rest auto-start **skips after the last set**; summary is
**re-openable from the completed list**.

## Success Criteria

- Meal list: tapping a meal expands the ingredients; long-pressing opens the edit form; no edit icon.
- Workout form: empty query shows no exercises; typing filters; each selected exercise's sets require
  reps/weight + rest (or duration + rest for cardio) and fail validation otherwise.
- Schema is v5; `exercise_sets.rest_seconds` + `actual_rest_seconds` round-trip through insert,
  delete+undo (snapshot restore), and detail loading.
- Completing a set in the active view saves actuals, auto-starts the rest timer with the set's planned
  rest (skipped after the last remaining set), and records the actual rest on the set.
- Exactly one active-workout view: bar / dashboard / list / notification all land on `/active-workout`;
  no stacked duplicates; the floating bar and NavigationBar are not visible on that view.
- Tapping the notification opens the active-workout view while a workout is active.
- Completing a workout redirects to the summary; the summary shows per-exercise avg rest, volume,
  max weight, total reps (cardio: duration/distance); tapping a completed workout reopens it.
- `flutter pub run build_runner build` — exit 0; `flutter gen-l10n` — exit 0; `dart analyze lib/` —
  zero errors; `flutter test` — passes; all new strings localized en/fr/es; `context/` synced.

## Constraints & Non-Goals

- **No new dependencies.** `fl_chart`, `shared_preferences`, `flutter_foreground_task` already present.
- Schema change is **one** bump to **v5** adding only `exercise_sets.rest_seconds` and
  `exercise_sets.actual_rest_seconds` (both nullable in DB; `rest_seconds` required at the form).
- No changes to the foreground notification's content/elapsed text beyond the tap routing (T06).
- No goals/targets, no coaching/analysis beyond the requested summary metrics.
- Manual UI verification deferred to the user (headless environment); deferred checks are recorded per
  task as in prior plans.
- Not in scope: editing planned sets after the workout is created (no edit-workout flow), exercise
  definitions management, cardio "volume" (duration/distance replaces it), anything outside the 7
  items above.

## Task stack

- [x] T01: `Schema v5 — set rest columns + repository support` (status:done)
  - Task ID: T01
  - Completed: 2026-08-08
  - Files changed: `lib/src/database/tables.dart` (`ExerciseSets.restSeconds` + `actualRestSeconds` `IntColumn?`, nullable in DB), `lib/src/database/app_database.dart` (schemaVersion 4→5; `if (from < 5)` step adds both columns), `lib/src/database/app_database.g.dart` (regenerated via build_runner), `lib/src/models/exercise_set.dart` (`restSeconds`, `actualRestSeconds` fields + constructor params), `lib/src/exercise/repositories/workout_repository.dart` (`insert` writes `restSeconds`; `restore` round-trips both columns; `_getExerciseBlocks` maps both; new `recordSetRest({setId, actualRestSeconds})`; `newPlannedSet` gains `restSeconds`)
  - Evidence: `flutter pub run build_runner build` exit 0 (6s, wrote 72 outputs); `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; grep `restSeconds|actualRestSeconds` present in tables.dart / model / repository / generated code
  - Goal: Add planned and actual rest to `exercise_sets` (schema v5) and thread both through the
    model, repository (insert/restore/load), and factory so every later task can read/write them.
  - Boundaries (in/out of scope):
    - In: `lib/src/database/tables.dart` (`ExerciseSets.restSeconds` IntColumn? +
      `actualRestSeconds` IntColumn?), `lib/src/database/app_database.dart` (schema version 4 → 5,
      `onUpgrade` step adding both nullable columns), `flutter pub run build_runner build`
      (regenerate `app_database.g.dart`), `lib/src/models/exercise_set.dart` (`restSeconds`,
      `actualRestSeconds` fields), `lib/src/exercise/repositories/workout_repository.dart`
      (`insert` writes `restSeconds`; `restore` round-trips both columns; `_getExerciseBlocks`
      maps both; new `recordSetRest(String setId, int actualRestSeconds)`), `newPlannedSet` gains
      `restSeconds`).
    - Out: UI, validation, rest-timer behavior, summary (later tasks).
  - Done when: `exercise_sets` has both columns; schema version is 5 with a v4→v5 migration; a set
    created with `restSeconds` persists and reloads; `recordSetRest` updates `actualRestSeconds`;
    delete+undo preserves both columns; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `flutter pub run build_runner build` — exit 0; `dart analyze lib/` — "No issues found!".
    - Grep: `restSeconds|actualRestSeconds` present in `tables.dart`, model, repository, factory.
    - `context/database/schema.md` updated to v5 in T08 (or here — keep for T08 to avoid churn).

---

- [x] T02: `Meal tile — tap expands, long-press edits` (status:done)
  - Task ID: T02
  - Completed: 2026-08-08
  - Files changed: `lib/src/diet/screens/meal_list.dart` (`_MealTile` trailing loses the edit `IconButton` — trailing is now just the `AnimatedRotation` chevron; the `ExpansionTile` is wrapped in a `GestureDetector(onLongPress: widget.onTap)` reusing the existing edit callback; doc comment updated)
  - Evidence: `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; grep `IconButton|onLongPress` in meal_list.dart — only the AppBar manage-ingredients IconButton remains (line 29), `onLongPress: widget.onTap` at line 233; `commonEdit` still referenced by `workout_detail.dart` so no ARB churn
  - Goal: Remove the trailing edit `IconButton` from `_MealTile`; one tap expands/collapses the
    ingredient breakdown, long-press opens the meal edit form.
  - Boundaries (in/out of scope):
    - In: `lib/src/diet/screens/meal_list.dart` only — `_MealTile` trailing loses the edit
      `IconButton` (keep the animated chevron as the expansion affordance); add `onLongPress` on
      the tile → `widget.onTap` (edit); keep swipe-to-delete and tap-to-expand intact.
    - Out: other screens, ARB changes, edit form behavior.
  - Done when: no edit icon renders; tapping expands/collapses; long-pressing opens `MealFormScreen`;
    `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "IconButton|onLongPress" lib/src/diet/screens/meal_list.dart` — no edit IconButton,
      `onLongPress` wired to the edit callback.
    - Manual (deferred): tap vs long-press on a meal row.

---

- [x] T03: `Workout form — search-first picker + required rest per set` (status:done)
  - Task ID: T03
  - Completed: 2026-08-08
  - Files changed: `lib/src/exercise/screens/workout_form.dart` (search-first exercise picker — empty query shows no results, typing filters case-insensitively; search result rows tap-to-add with a check-circle "added" state and a remove affordance on the selected exercise card (`workoutFormRemoveExercise`); `_PlannedSetEntry` gains `int? restSeconds`; set rows gained a rest field for weightlifting (reps/kg/rest) and cardio (duration/rest), entered in minutes → `_parseRestSeconds` converts ×60 to seconds; `_save` now validates every added set is complete (reps/weight or duration AND rest) with a `workoutFormSetIncomplete` SnackBar and maps `restSeconds` into `newPlannedSet`), `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_es.arb` (new `workoutFormSearchHint`, `workoutFormRestLabel`, `workoutFormSetIncomplete`, `workoutFormRemoveExercise`), `lib/l10n/app_localizations*.dart` (regenerated via gen-l10n)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; grep — all 4 new keys in all 3 ARBs, `restSeconds` wired entry → field → validation → `newPlannedSet`; `commonSearch` still used by `meal_form.dart` (no dead key)
  - Goal: Rework `WorkoutFormScreen` so exercises are found by search (nothing pre-listed) and every
    added set requires reps/weight + rest (weightlifting) or duration + rest (cardio).
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/workout_form.dart` — exercise section becomes a search field
      whose results appear only while the query is non-empty (case-insensitive name match); tapping a
      result adds it to a "selected exercises" list (multi-select preserved); selected exercises show
      per-set editors that now include a **rest** field alongside reps/weight (weightlifting) or
      duration (cardio); validation requires reps/weight (or duration) AND rest for every added set
      (an added-but-empty set fails save with a message); `_PlannedSetEntry` gains `restSeconds`;
      save maps rest into `newPlannedSet(restSeconds:)`; new ARB keys en/fr/es
      (`workoutFormSearchHint`, `workoutFormRestLabel`, maybe `workoutFormSetIncomplete`) +
      `flutter gen-l10n`.
    - Out: exercise creation in the form (still via Manage Exercises), editing sets after save.
  - Done when: with an empty query no exercises are listed; typing filters matches; selecting keeps
    the row in a chosen list; each set shows reps/weight (or duration) + rest; saving with an
    incomplete set or missing rest is blocked with a validation message; `flutter gen-l10n` exit 0;
    `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/exercise/screens/workout_form.dart` — clean.
    - Manual (deferred): open form → no list; search "bench" → matches; add sets with/without rest.

---

- [x] T04: `Dedicated active-workout screen + single /active-workout route` (status:done)
  - Task ID: T04
  - Completed: 2026-08-08
  - Files changed: `lib/src/exercise/screens/active_workout_screen.dart` (new — full-screen
    `ActiveWorkoutScreen` watching `activeWorkoutProvider` + `workoutDetailProvider`; 1 s ticker live
    elapsed; header Active badge + started-at; per-exercise `ExpansionTile` set lists whose planned
    column includes rest via `workoutDetailPlannedSetRest`; actuals-dialog flow; rest card; AppBar
    Complete → cancelRest → stop notification → `complete()` → `context.go('/exercise')` — T07
    replaces that redirect with the summary), `lib/src/app/router.dart` (top-level
    `GoRoute('/active-workout')` as a sibling of `StatefulShellRoute.indexedStack`, OUTSIDE the shell
    so the floating bar + NavigationBar do not render on it; `_ActiveWorkoutBar._openDetail` →
    `GoRouter.of(context).go('/active-workout')`; `workout_detail.dart` import removed),
    `lib/src/exercise/screens/workout_list.dart` (active tap → `context.go('/active-workout')`;
    pending/completed keep the imperative push), `lib/src/dashboard/screens/dashboard.dart` (quick
    chip active branch + `_LatestWorkoutCard._openDetail` active → `context.go('/active-workout')`),
    `lib/src/exercise/screens/workout_detail.dart` (pending-only: Start →
    start-notification → `repo.start()` → invalidations → pop-then-`router.go('/active-workout')`;
    Complete action, `_completeWorkout`, `_RestTimerCard`, and the active header/rest branches
    removed; `rest_timer.dart` import dropped), `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb`
    (new `workoutDetailPlannedSetRest`), `lib/l10n/app_localizations*.dart` (regenerated via
    gen-l10n)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!" (no go_router
    pub-cache noise — transient); `flutter test` 1/1 passed; `dart format --output=none
    --set-exit-if-changed lib test` exit 0 ("Formatted 66 files (0 changed)"); grep —
    `go('/active-workout')` present in all 4 files (router.dart:175, workout_list.dart:81,
    dashboard.dart:339+500, workout_detail.dart:173); `WorkoutDetailScreen` absent from router.dart;
    `_RestTimerCard|_completeWorkout|w.isActive|rest_timer` absent from workout_detail.dart
  - Goal: Introduce `ActiveWorkoutScreen` as the one view for a running workout, on a top-level
    GoRouter route `/active-workout` (outside the shell), and point every existing entry point at it.
  - Boundaries (in/out of scope):
    - In: new `lib/src/exercise/screens/active_workout_screen.dart` — watches `activeWorkoutProvider`
      (+ `workoutDetailProvider` for sets); full-screen Scaffold (no shell) showing workout name,
      live elapsed time (1 s ticker), per-exercise `ExpansionTile` set lists (planned columns now
      include rest; existing actuals-dialog flow for completing a set — the rest auto-start hookup is
      T05), and the existing `_RestTimerCard`-style rest UI + Complete action in the AppBar;
      `lib/src/app/router.dart` — top-level `GoRoute('/active-workout')` OUTSIDE the
      `StatefulShellRoute` (so the shell + floating bar + NavigationBar are not rendered on it);
      entry points switch from imperative `push(WorkoutDetailScreen)` to `context.go('/active-workout')`:
      `_ActiveWorkoutBar._openDetail` (router), workout list active-tap (`workout_list.dart`),
      dashboard resume chip + continue card (`dashboard.dart`); `workout_detail.dart` — pending-only:
      Start button now calls `context.go('/active-workout')` after `start()` (replacing the detail so
      there is no back to the planning view); remove the active-mode branches (Complete action, rest
      card) that moved to the active screen.
    - Out: rest auto-start (T05), notification tap (T06), summary (T07), completed-view removal
      (T08).
  - Done when: with an active workout there is exactly one view reachable from list / bar / dashboard
    / Start, all via `/active-workout`, with no stacked duplicates; the floating bar and
    NavigationBar are not visible on it; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "WorkoutDetailScreen|go('/active-workout')" lib/src/app/router.dart
      lib/src/exercise/screens/workout_list.dart lib/src/dashboard/screens/dashboard.dart
      lib/src/exercise/screens/workout_detail.dart` — active entry points use the route.
    - Manual (deferred): start → lands on active view; bar/dashboard taps don't stack another copy.

---

- [x] T05: `Set completion → auto-start rest + record actual rest` (status:done)
  - Task ID: T05
  - Completed: 2026-08-08
  - Files changed: `lib/src/notifications/rest_timer.dart` (`RestTimerState` gains `setId` +
    `plannedSeconds`; new prefs keys `rest_set_id` / `rest_planned_seconds`; `build()` restores both;
    `startRest(Duration, {setId})` persists the set context (or clears it for manual preset rests);
    `cancelRest()` centralizes recording — records `actual_rest_seconds` (planned − rounded
    remaining, clamped; expired ⇒ planned) via `workoutRepositoryProvider.recordSetRest` when a set
    context exists, then clears all three keys; new `workoutRepositoryProvider` import — verified no
    import cycle), `lib/src/notifications/active_workout_notifier.dart` (background handler's
    expired-rest branch now also removes `rest_set_id` / `rest_planned_seconds` so no stale set
    context survives a backgrounded expiry; notification text logic unchanged),
    `lib/src/exercise/screens/active_workout_screen.dart` (`_SetRow._editActuals` auto-starts the
    rest with the set's planned rest after saving actuals — when actuals were saved, another
    incomplete set remains (checked against the pre-invalidate cached detail), and
    `set.restSeconds != null`; manual preset chips and `_completeWorkout` intentionally unchanged —
    chips start a rest without a set target (not recorded), and `_completeWorkout` already calls
    `cancelRest()` first so the in-flight rest is recorded)
  - Evidence: `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format
    --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 66 files (0 changed)"); grep —
    `restSetIdKey|restPlannedSecondsKey|recordSetRest|startRest` present in rest_timer.dart /
    active_workout_notifier.dart / active_workout_screen.dart; record + 3-key clear inside
    `cancelRest`; `savedActuals|hasOtherIncomplete` at active_workout_screen.dart:492/498. Design
    decision (user-approved): recording centralized in `RestTimerNotifier.cancelRest()`.
  - Goal: When a set is completed in the active view, auto-start the rest timer with that set's
    planned rest (skipping the last remaining incomplete set) and record the actual rest taken onto
    the set.
  - Boundaries (in/out of scope):
    - In: `lib/src/notifications/rest_timer.dart` — `startRest` gains a set context (prefs key
      `rest_set_id` + planned duration); helper to compute "is this the last incomplete set" is
      evaluated at the call site (active screen) using the workout detail; `lib/src/exercise/screens/
      active_workout_screen.dart` — after saving actuals for a set: if incomplete sets remain and
      `set.restSeconds != null`, `startRest(Duration(seconds: restSeconds), setId: set.id)`;
      recording — when the rest expires (ticker), is cancelled, or the workout is completed, write
      `actual_rest_seconds` (elapsed if cancelled early, planned if expired) to the set via
      `WorkoutRepository.recordSetRest` and clear `rest_set_id`; completing the workout cancels +
      records first (used by T07's completion flow).
    - Out: summary (T07), notification text changes, manual rest chips (removal of the manual
      start chips is fine if they conflict — keep cancel only).
  - Done when: completing a set starts the timer with the set's planned rest; no rest starts after
    the last incomplete set; cancel/expiry records `actual_rest_seconds` on the correct set;
    `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "rest_set_id|recordSetRest|startRest" lib/src/notifications/rest_timer.dart
      lib/src/exercise/screens/active_workout_screen.dart` — wiring present.
    - Manual (deferred): complete set → timer runs; complete last set → no timer; cancel → recorded.

---

- [x] T06: `Notification tap → active-workout view` (status:done)
  - Task ID: T06
  - Completed: 2026-08-08
  - Files changed: `lib/src/notifications/active_workout_notifier.dart`
    (`ActiveWorkoutTaskHandler.onNotificationPressed()` override →
    `FlutterForegroundTask.sendDataToMain('active-workout')`; `startService(...)` now uses
    `notificationInitialRoute: '/active-workout'` — the `restartService()` branch is untouched
    because flutter_foreground_task 9.2.2's `restartService` takes no options, so the already-running
    service keeps the route stored at its own start), `lib/main.dart` (imports `src/app/router.dart` +
    `src/notifications/active_workout_notifier.dart`; registers
    `FlutterForegroundTask.addTaskDataCallback` after `SharedPreferences.getInstance()`, gated on
    `prefs.getString(activeWorkoutNameKey) != null`, navigating via `appRouter.go('/active-workout')`
    — deferred through `addPostFrameCallback` when the router navigator isn't mounted yet (cold start
    can deliver the signal before the first frame))
  - Evidence: `dart analyze lib/` "No issues found!"; `flutter test` 1/1 passed; `dart format
    --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 66 files (0 changed)"); grep —
    `notificationInitialRoute: '/active-workout'` present on `startService` only,
    `onNotificationPressed` → `sendDataToMain('active-workout')` in active_workout_notifier.dart,
    `addTaskDataCallback` wired in main.dart with the active-session gate + cold-start deferral
  - Goal: Tapping the ongoing workout notification opens `/active-workout` (both when the app is
    already running and on a cold launch).
  - Boundaries (in/out of scope):
    - In: `lib/src/notifications/active_workout_notifier.dart` — `startService(...)` uses
      `notificationInitialRoute: '/active-workout'`; `ActiveWorkoutTaskHandler.onNotificationPressed`
      sends a signal to the UI isolate (`FlutterForegroundTask.sendDataToMain(...)`); `lib/main.dart`
      — register `FlutterForegroundTask.addTaskDataCallback` and, when the signal arrives while a
      workout is active, navigate via the root navigator key to `/active-workout`; guard the cold
      start (workout active → initial location resolves to `/active-workout`).
    - Out: iOS parity changes beyond the existing best-effort notification, notification content.
  - Done when: tap signal is wired end-to-end (background handler → UI callback → route); cold-start
    route is set; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `rg -n "notificationInitialRoute|onNotificationPressed|addTaskDataCallback" lib/src` — present.
    - Manual (deferred, requires device): tap notification while running and after kill → active view.

---

- [x] T07: `Workout summary screen + completion flow` (status:done)
  - Task ID: T07
  - Completed: 2026-08-08
  - Files changed: `lib/src/exercise/screens/workout_summary_screen.dart` (new — `WorkoutSummaryScreen`
    (ConsumerWidget, `workoutId`), watches `workoutDetailProvider`; loading/error/not-found states with
    a back affordance that pops when possible else `go('/exercise')`; header card (name, completed
    `StatusBadge`, total duration via `workout.duration` + `formatRestDuration`); per-exercise card via
    `_ExerciseMetrics.fromBlock` — avg rest = mean of `actualRestSeconds` falling back to `restSeconds`
    (em-dash when none), volume Σ `set.totalVolume` (`effectiveReps × effectiveWeightKg`), max weight
    (max `effectiveWeightKg`), total reps Σ `effectiveReps`; cardio (any set with
    `durationMinutes`/`distanceMeters`) shows total duration Σ `durationMinutes ?? 0` + total distance
    Σ `distanceMeters ?? 0` instead of volume/max-weight/reps; `_formatNumber` = whole when no
    decimals else 1 decimal; tabular-figure value rows), `lib/src/app/router.dart` (top-level
    `GoRoute('/workout-summary/:id')` sibling of `/active-workout`, outside the shell, via
    `state.pathParameters['id']!`), `lib/src/exercise/screens/active_workout_screen.dart`
    (`_completeWorkout` final redirect `context.go('/exercise')` → `context.go('/workout-summary/$id')`;
    cancelRest → stopWorkoutNotification → complete → SnackBar → invalidate detail+list order
    unchanged), `lib/src/exercise/screens/workout_list.dart` (`_openDetail` gains a completed branch →
    `context.go('/workout-summary/${workout.id}')`; active stays `/active-workout`, pending keeps the
    imperative push + trailing list invalidate), `lib/l10n/app_en.arb` / `app_fr.arb` / `app_es.arb`
    (10 new `workoutSummary*` keys each: app bar title, duration label, avg rest, volume, max weight,
    total reps, total duration, total distance, `{value} kg` + `{distance} m` value formats),
    `lib/l10n/app_localizations*.dart` (regenerated via gen-l10n)
  - Evidence: `flutter gen-l10n` exit 0; `dart analyze lib/` "No issues found!" (go_router pub-cache
    noise transient in IDE diagnostics only, absent from analyze output); `flutter test` 1/1 passed;
    `dart format --output=none --set-exit-if-changed lib test` exit 0 ("Formatted 67 files (0
    changed)"); grep — route at router.dart:63 (`/workout-summary/:id`), redirect at
    active_workout_screen.dart:215 + workout_list.dart:85, `workoutSummary` keys ×12 in all 3 ARBs.
    Cardio-per-exercise rule: **any** set with duration/distance ⇒ cardio (documented in code).
    Note: dashboard `_LatestWorkoutCard._openDetail` (dashboard.dart:498-508) still pushes
    `WorkoutDetailScreen` for completed workouts — T08 should decide whether to route it to the
    summary (flagged, not changed here).
  - Goal: Add `WorkoutSummaryScreen` (route `/workout-summary/:id`), redirect to it on workout
    completion, and make completed workouts re-open it from the list.
  - Boundaries (in/out of scope):
    - In: new `lib/src/exercise/screens/workout_summary_screen.dart` — reads
      `workoutDetailProvider(workoutId)`; header (name, status, total duration); per exercise card:
      average rest time (mean of `actualRestSeconds`, falling back to `restSeconds` when unrecorded),
      total volume (Σ `effectiveWeightKg × effectiveReps`), max weight lifted (max
      `effectiveWeightKg`), total reps (Σ `effectiveReps`); cardio exercises show total
      duration/distance instead of volume/max-weight; `lib/src/app/router.dart` — top-level
      `GoRoute('/workout-summary/:id')` outside the shell; `active_workout_screen.dart` Complete →
      cancel+record rest, stop notification, then `context.go('/workout-summary/:id')`;
      `workout_list.dart` — completed workout tap → `context.go('/workout-summary/:id')` (active tap
      stays `/active-workout`); new ARB keys en/fr/es (summary title, per-metric labels) +
      `flutter gen-l10n`.
    - Out: charts/trends, editing, anything beyond the four requested metrics.
  - Done when: completing the active workout redirects to the summary; per-exercise avg rest, volume,
    max weight, and total reps render from real data (cardio: duration/distance); tapping a completed
    workout in the list opens the summary; `flutter gen-l10n` exit 0; `dart analyze lib/` zero errors.
  - Verification notes (commands or checks):
    - `flutter gen-l10n` — exit 0; `dart analyze lib/src/exercise/` — clean.
    - Manual (deferred): complete workout → summary values match the logged sets; reopen from list.

---

- [x] T08: `Final validation, cleanup, and context sync` (status:done)
  - Task ID: T08
  - Completed: 2026-08-08
  - Files changed: `lib/src/dashboard/screens/dashboard.dart` (`_LatestWorkoutCard._openDetail` —
    completed case now `context.go('/workout-summary/${workout.id}')`; the `WorkoutDetailScreen` push
    and its now-unused import removed — user-approved decision from the T07 review), `lib/src/exercise/
    screens/workout_detail.dart` (workout-level completed branches removed: status ternary → always
    `statusPending`/`outline` and the completed-duration row deleted; `FitFatColors` import kept —
    still used for set-level styling), context files synced (`architecture.md`,
    `exercise/workout-crud.md`, `context-map.md`; verified `database/schema.md` already v5,
    `notifications.md`, `diet/meal-crud.md`, `glossary.md`, `overview.md`), this plan (validation
    report below)
  - Evidence: full suite exit 0 — `flutter pub run build_runner build` (wrote 0 outputs), `flutter
    gen-l10n`, `dart analyze lib/` "No issues found!", `flutter test` 1/1 "All tests passed!",
    `dart format --output=none --set-exit-if-changed lib test` "Formatted 67 files (0 changed)";
    greps — `w.isCompleted|w.isActive|_RestTimerCard|_completeWorkout` absent from workout_detail.dart
    (set-level `set.isCompleted` strikethrough remains), dashboard → `/workout-summary/${id}`,
    all 4 summary entry points wired (router:63, active_workout_screen:215, workout_list:85,
    dashboard:503), `FitFatColors`/`DateFormats` invariants intact
  - Goal: Full verification suite, remove dead code (the completed/active branches left in
    `WorkoutDetailScreen`), sync `context/`, and run `sce-validation`.
  - Boundaries (in/out of scope):
    - In: verification commands; cleanup of dead branches in `workout_detail.dart` (completed state
      now lives in the summary, active in the active screen) and any orphaned helpers; context
      updates — `context/database/schema.md` (v5, two new columns), `context/exercise/workout-crud.md`
      (active screen, rest fields, summary, entry points), `context/notifications/notifications.md`
      (tap routing), `context/diet/meal-crud.md` (meal tile interaction), `context/glossary.md`
      (`ActiveWorkoutScreen`, `/active-workout`, summary, rest fields), `context/overview.md` and
      `context/architecture.md` (workflow + new top-level routes), `context/context-map.md` (this
      plan + any new domain docs); `sce-validation` report appended to the plan.
    - Out: new features, refactors beyond this plan, dependency changes, git commit.
  - Done when: `flutter pub run build_runner build` exit 0; `flutter gen-l10n` exit 0; `dart analyze
    lib/` zero errors; `flutter test` passes; grep checks clean (colors/date-format invariants);
    no dead active/completed branches in `workout_detail.dart`; context files read back accurate and
    ≤ 250 lines; validation report written.
  - Verification notes (commands or checks):
    - Full suite commands all exit 0; `rg -n "isActive|isCompleted" lib/src/exercise/screens/
      workout_detail.dart` — only pending/start logic remains.
    - Re-read synced context files against code.

---

## Open Questions

- None — all decisions resolved with the user (rest required per set; summary shows volume AND max
  weight; rest skipped after last set; summary re-openable from the list).
- Out of scope, noted for future: `pedometer`/`share_plus` unused deps; editing planned sets after a
  workout exists.

## Next Command

Plan complete — all 8 tasks done. `sce-validation` report below; the plan is disposable (not a
durable context source; final behavior lives in `context/`).

## Validation Report

### Commands run (2026-08-08, all from the project root)
- `flutter pub run build_runner build --delete-conflicting-outputs` -> exit 0 ("wrote 0 outputs" — no schema change pending)
- `flutter gen-l10n` -> exit 0 (idempotent; l10n.yaml notice only)
- `dart analyze lib/` -> exit 0 ("No issues found!")
- `flutter test` -> exit 0 (00:00 +1 — "All tests passed!", 1/1)
- `dart format --output=none --set-exit-if-changed lib test` -> exit 0 ("Formatted 67 files (0 changed)")
- Grep invariants:
  - `rg -n "isActive|isCompleted" lib/src/exercise/screens/workout_detail.dart` -> only set-level `set.isCompleted` (strikethrough styling) remains; no workout-level active/completed branches
  - `rg -n "WorkoutDetailScreen" lib/src/app/router.dart lib/src/exercise/screens/workout_list.dart lib/src/dashboard/screens/dashboard.dart` -> absent from router + dashboard; present only in workout_list (pending push)
  - `rg -n "workout-summary" lib/src/app/router.dart lib/src/exercise/screens/active_workout_screen.dart lib/src/exercise/screens/workout_list.dart lib/src/dashboard/screens/dashboard.dart` -> route (router:63) + all 3 entry points wired (active_workout_screen:215, workout_list:85, dashboard:503)
  - `rg -c "FitFatColors|DateFormats" lib/src/` -> invariants intact across ui/, dashboard, notifications, exercise, diet (colors/date-format single-path usage preserved)
  - `rg -n "w\.isCompleted|w\.isActive|workoutDetailBtnComplete|_RestTimerCard|_completeWorkout" lib/src/exercise/screens/workout_detail.dart` -> clean (no matches)

### Success-criteria verification (plan-level)
- [x] Meal list: tap expands / long-press edits, no edit icon -> T02; `context/diet/meal-crud.md` reads back accurate
- [x] Workout form: search-first picker + required rest per set -> T03; ARB keys en/fr/es regenerated
- [x] Schema v5: `exercise_sets.rest_seconds` + `actual_rest_seconds` round-trip -> T01; `context/database/schema.md` already documents v5 + migration
- [x] Set completion auto-starts rest (skipped after last set) and records actual rest -> T05 (recording centralized in `cancelRest()`, user-approved)
- [x] Exactly one active-workout view (`/active-workout`, outside the shell) for bar / dashboard / list / notification; no stacked duplicates -> T04 + T06
- [x] Notification tap opens `/active-workout` (warm via task-data callback, cold via `notificationInitialRoute`) -> T06
- [x] Completion redirects to the summary; per-exercise avg rest / volume / max weight / total reps (cardio: duration/distance) from real data; completed workouts reopen it from the list and dashboard -> T07 + T08
- [x] Full suite green (build_runner, gen-l10n, analyze, test, format all exit 0) -> evidence above
- [x] `context/` synced and accurate, all files ≤ 250 lines -> re-read against code this session

### Residual risks
- **Manual UI verification deferred** (headless environment — no `flutter run`). Untested by machine: notification tap on device (T06), rest auto-start timing (T05), summary values vs logged sets on real data (T07), back-navigation feel on `/active-workout` and `/workout-summary/:id` (both use `context.go`, so no back stack — the summary data-state AppBar has no explicit leading back; flag from T07 stands).
- **`ExerciseSet.actualDurationMinutes`** getter returns null with a stale comment (cardio actuals overwrite the `durationMinutes`/`distanceMeters` columns instead). Non-blocking; summary follows code truth. Future cleanup candidate.
- **Uncommitted tree** — all T01–T08 changes remain uncommitted by design (per session constraints); user will commit when ready.

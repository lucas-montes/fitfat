# Plan: Rest timer, data reset, catalog polish, instant startup, Notes

## Change Summary

Batch of user-requested improvements (decided with the user 2026-08-12; implemented on branch
`restart`). This file records the implemented scope:

1. **Instant startup** — `main.dart` no longer blocks the first frame on catalog import,
   foreground-task init, timezone setup, or notification init. `lib/src/app/app.dart` gained a
   `MaterialApp.builder` `_BackgroundStartup` that, post-first-frame, imports the catalog in the
   background (unawaited; batched into a single transaction), inits the foreground task service,
   sets the device timezone, initializes notifications via the new shared plugin, caches localized
   rest-alarm texts, and reschedules planner reminders.
2. **Rest timer counts up** — `rest_timer.dart` tracks rest start + elapsed and keeps running past
   the planned duration (no stop button, no auto-clear). Rest state is normalized again whenever
   any rest starts (the previous rest is finalized first). The active-workout screen shows a slim
   `_RestStrip` under the header instead of the old card with a stop control.
3. **Rest alarm notification** — new `rest_alarm.dart` schedules a one-shot zoned notification
   (exact, with inexact fallback) at `restStart + planned`, with sound + vibration toggled by new
   `restAlarmSound` / `restAlarmVibration` Settings toggles. Android gains `SCHEDULE_EXACT_ALARM`.
   Notifications for both planner reminders and rest alarms now share one plugin
   (`notification_plugin.dart`) with payload-routed tap handling.
4. **Reset all data** — `LIB/settings/services/data_reset.dart` wipes the app DB file, clear
   SharedPreferences, re-imports the catalog, cancels planner + rest notifications, and invalidates
   providers — inline, no app restart. Settings gains a destructive "Reset all data" row with a
   confirming dialog.
5. **Rest in history** — `exercise_detail_screen.dart` set rows now render `rest 1:30 · (took 1:45)`
   when planned/actual rest are recorded.
6. **Detail header + full image** — `_DetailView` became a `NestedScrollView` with a pinned
   collapsible `SliverAppBar` (parallax media header, bottom History|Details TabBar). The image now
   uses `BoxFit.contain` on a surface backdrop; tapping it opens a full-screen zoomable
   (`InteractiveViewer`) viewer.
7. **List thumbnails** — exercise list rows show a 48 px rounded thumbnail (`BoxFit.cover`) with a
   type-icon fallback.
8. **Workout-form picker** — exercise search now debounces (250 ms) and renders a height-bounded,
   50-row-capped lazy list; a persistent "＋ Create new exercise" row opens the exercise form
   prefilled with the typed query and auto-selects the created exercise on save.
9. **Notes tab** — new schema v9 `notes` table + `NoteRepository` + providers, a Notes screen
   (list, newest-first, FAB, empty state) and a create/edit/delete editor. Notes replaces Settings
   as the 5th bottom-nav tab; Settings is now a root `/settings` route (the dashboard gear opens it
   full-screen over the shell, like `/active-workout`).
10. **Summary Done** — the workout summary AppBar now has a Done action that lands on the Exercise
    tab (`context.go('/exercise')`), mirroring the back affordance.

## Success Criteria

- App opens instantly: first frame renders without awaiting DB import / foreground-task / tz /
  notification init (all moved to `_BackgroundStartup`).
- Rest strip counts up, keeps running past planned, no stop button; alarm fires as a zoned
  notification honoring the sound/vibrate toggles.
- "Reset all data" wipes data + settings, re-imports the catalog, works in place.
- Exercise detail: collapsible pinned header with `contain` image; tapping opens a zoomable viewer.
  List rows show thumbnails. Workout-form search is lazy + debounced with a working create row.
- Notes CRUD works against schema v9 (drift build_runner regenerated); Notes is the 5th tab;
  Settings reachable from the dashboard gear.
- Summary Done navigates to Exercise.
- l10n parity en/fr/es (343 keys, verified via key-set diff); `dart format` clean; `dart analyze lib test`
  "No issues found!"; full `flutter test` green (29 tests, incl. new `note_repository_test.dart`).

## Tasks

- [x] T1 — Reset all data (`data_reset.dart`, Settings destructive row + confirm dialog)
- [x] T2 — Rest count-up timer (`rest_timer.dart` rewrite, `_RestStrip`)
- [x] T3 — Rest alarm notification (`rest_alarm.dart`, shared `notification_plugin.dart`,
  sound/vibrate toggles, `SCHEDULE_EXACT_ALARM`)
- [x] T4 — Rest shown in history rows (`exercise_detail_screen.dart`)
- [x] T5 — Exercise-list thumbnails (`_ExerciseThumbnail`)
- [x] T6 — Collapsible detail header + full-screen zoomable image viewer
- [x] T7 — Workout-form picker: debounce, lazy capped list, create row + auto-select
- [x] T8 — Summary Done action → `/exercise` (+ `workoutSummaryDone` keys)
- [x] T9 — Instant startup (`main.dart` trims; `_BackgroundStartup`; transactional catalog import;
  self-constructing `taskReminderSchedulerProvider`)
- [x] T10 — Notes: schema v9 table + migration, model, repository, providers, screens, tab,
  build_runner regen, l10n keys
- [x] T11 — Bottom nav: Notes replaces Settings tab; Settings root `/settings` route; remove
  `settings_tab.dart`
- [x] T12 — l10n parity check en/fr/es (343 keys each) + `flutter gen-l10n`
- [x] T13 — Validation: `dart format .`, `dart analyze lib test`, `flutter test` (29 passed)
- [x] T14 — This plan file.

## Notes

- Schema v8 → v9 (new `notes` table only); `dart run build_runner build --delete-conflicting-outputs`
  run (required for the new table's generated code).
- Rest semantics change: rest is no longer cleared when it overruns the planned time; actual rest is
  capped nowhere (uncapped recording at finalize/cancel).
- Settings is no longer a bottom tab; reachable only from the dashboard gear (`/settings` root route).
- Tests need `LD_LIBRARY_PATH="/nix/store/0vpj29gvvl1z9fjwh4lk9fiyvkqf21px-sqlite-3.50.4/lib"` for
  sqlite3 native access on this machine.
- Catalog DB + media remain git-ignored; reset re-imports from the bundled `assets/exercises.db`.
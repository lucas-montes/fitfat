# Plan: task-carryover-notifications-fix

## Change summary

Fixes two linked planner defects: past pending tasks only appear on today after a manual create/edit (stale timeline / week / dashboard caches and rollover running after the reminder reschedule), and timed-task reminders never fire for carried-over tasks and are unreliable for newly timed tasks (startup/resume ordering, missing timezone init on toggle-on, and reminder lifecycle gaps on rollover/edit). This extends the existing `TaskRepository.rolloverPastTasks` + `TaskReminderScheduler` behavior in `lib/src/app/app.dart`, `lib/src/planner/`, and `lib/src/notifications/task_reminders.dart`; it does not replace the carry-over model (`Task.carryOver`) or the reminder channels.

Revision: per user request, untimed tasks also get a reminder at a Settings default time (default 09:00 local, same-day anchor, plus the configurable pre-reminder lead), and all task reminders switch from inexact to exact alarms (`AndroidScheduleMode.exactAllowWhileIdle` with `SCHEDULE_EXACT_ALARM` permission flow and silent inexact fallback when denied).

## Acceptance criteria

- [ ] AC1: A pending carry-over task from a past day appears on today after cold start and after resume without any manual create/edit.
  - Validate: `flutter test test/planner_repository_test.dart test/task_reminders_test.dart`; manual: seed a pending task yesterday, kill + relaunch, confirm it is on today; background the app past midnight, resume, confirm it moved.
- [ ] AC2: A carried-over timed task has live due-time + pre-reminders anchored to its new day, and tapping routes to Plan.
  - Validate: `flutter test test/task_reminders_test.dart`; manual on Android: carry a task with a future start time, check `scheduledTasksKey` registry + `adb shell dumpsys notification`, wait for pre/due or verify via `zonedSchedule` list, tap routes to `/plan`.
- [ ] AC3: Newly created/edited timed tasks schedule, update, and cancel reminders correctly (edit-away-time drops them, done/delete/cancel drops them, undo restores them).
  - Validate: `flutter test test/task_reminders_test.dart`; manual: add timed task → permission prompt → notification fires; edit time → old ids cancelled; mark done/delete → cancelled.
- [ ] AC4: A pending untimed task schedules a reminder at the Settings default time (default 09:00 local on its day, plus pre-reminder per lead setting) while still showing under Anytime with no time label change; changing the setting re-times future untimed reminders.
  - Validate: `flutter test test/task_reminders_test.dart` (untimed `plannerReminderTimes` with setting default + reschedule includes untimed); manual: add untimed task for tomorrow → registry contains id → fires at setting time / setting time minus lead (09:00 / 08:30 with defaults); change setting → reschedules; mark done → cancelled.
- [ ] AC5: Task reminders fire on time under Doze via exact alarms when permission is granted, and silently fall back to inexact without crashing or persistent nudge when denied or revoked.
  - Validate: `flutter test test/task_reminders_test.dart`; manual on Android 12+: grant `SCHEDULE_EXACT_ALARM` → `canScheduleExactAlarms` true → `exactAllowWhileIdle` path fires on time; deny/revoke → silent fallback path schedules with no banner; toggle-off/on and resume preserve this.

### Full validation

- `flutter test`
- `flutter analyze`

### Context sync

- context/planner/planner.md — Task model, TaskRepository, dayEntries/range providers, carry-over + rollover semantics, untimed default reminder rule
- context/notifications/notifications.md — TaskReminderScheduler lifecycle, startup/resume ordering, exact-alarm permission + fallback, timezone + permission path
- context/architecture.md — _BackgroundStartup ordering (rollover vs reschedule), provider invalidation map
- context/settings/settings.md — plannerNotifications + reminderLeadMinutes + untimedReminderMinutes (default 540) + silent exact fallback
- context/database/schema.md — tasks carryOver / startTimeMinutes reminder anchor if behavior changes

## Task context synchronization lifecycle

- **Task context synchronization:** every task carries `pending | synced | blocked`. A completed task must be `synced` before another task can start or the plan can finish.
- For `blocked`, record **Blocker**, **Required action**, and **Retry condition** beside the status. Never infer `synced` from conversation history; write every lifecycle transition to the plan file.

## Constraints and non-goals

- **In scope:** `lib/src/app/app.dart` (_BackgroundStartup/_rollover ordering + invalidation), `lib/src/planner/repositories/task_repository.dart` (rollover query + return shape), `lib/src/planner/providers/planner.dart` + `lib/src/planner/screens/planner_screen.dart` (invalidation coverage), `lib/src/notifications/task_reminders.dart` + `notification_plugin.dart` (schedule/cancel/reschedule, timezone, exact-alarm permission + silent fallback, settings-based untimed default), `lib/src/settings/screens/settings_screen.dart` + `lib/src/settings/providers/settings.dart` (toggle-on path, `untimedReminderMinutes` setting default 540 + `reminderLeadMinutes`, no exact-alarm nudge UI), `android/app/src/main/AndroidManifest.xml` (already declares `SCHEDULE_EXACT_ALARM`, verify), targeted tests.
- **Out of scope:** Experiment and goal reminders, active-workout foreground notification, server sync, UI redesign of the timeline, per-task custom default time.
- **Constraints:** Use `AndroidScheduleMode.exactAllowWhileIdle` with `canScheduleExactAlarms` check and silent inexact fallback when denied/revoked (no crash, no persistent nudge); keep deterministic FNV-1a notification ids + prefs registry; keep offline-first, no new dependencies; respect `plannerNotifications` toggle (off = cancelAll, on = reschedule); follow Android 12+ exact-alarm + Android 13+ `POST_NOTIFICATIONS` permission rules with user-initiated prompts only.
- **Non-goal:** Changing the carry-over policy itself (carry vs auto-cancel stays per-task `carryOver` flag).

## Assumptions

- "Carryover delay" means `rolloverPastTasks` moves the row in DB but the Day/Week/Month/Dashboard views keep stale data until the next manual mutation invalidates them.
- "Due tasks" includes untimed tasks per this revision: timed = `startTimeMinutes` anchor; untimed = `untimedReminderMinutes` Settings value (default 540 = 09:00 local) anchored on the task's day; `startTimeMinutes` stays null in DB, reminder time is computed.
- Exact alarms were explicitly requested for on-time firing under Doze; the plan switches the task-reminder path to exact with silent inexact fallback when denied/revoked (no nudge, per revision).
- Repro is on Android (planner_reminders channel); iOS best-effort path shares the scheduler logic (no exact-alarm concept).
- `flutter test` + `flutter analyze` are the runnable checks in this repo.

## Task stack

- [x] T01: `Reproduce carryover staleness and reminder miss` (status:done)
  - Task ID: T01
  - Scope: In — failing-first repo tests + startup ordering audit (`_run` reschedule-before-rollover, resume-only-rollover, toggle-on without timezone init, `_cancelReminder` gated on toggle). Out — any fix, UI changes.
  - Dependencies: none
  - Done when: A test proves a yesterday timed task is past-due at `reschedulePending` time then moved by `rolloverPastTasks` with no reminder rescheduled, and a test/manual trace proves today/week/dashboard providers stay stale after `_rollover` until a manual invalidate; ordering + invalidation gaps are logged in the test/file comments.
  - Verify: `flutter test test/carryover_reminder_repro_test.dart test/task_reminders_test.dart` — all 8 passed; `grep -n "reschedulePending\|rolloverPastTasks\|_initTimeZone" lib/src/app/app.dart` — confirmed reschedule (228) after timezone init (222) but before rollover (260), resume-only-rollover, toggle-on without tz; `flutter analyze test/carryover_reminder_repro_test.dart` — no issues. DB-backed planner_repository tests error locally on missing libsqlite3.so (pre-existing, same for existing tests).
  - Completed: 2026-09-30
  - Files changed: test/carryover_reminder_repro_test.dart
  - Result: Repro proves yesterday 23:30 task yields no reminder times before rollover but future times after moving to today, and documents startup/resume/toggle + provider invalidation gaps in file comments; no app code changed.
  - Context impact: planner + notifications ordering gaps documented; durable context repair deferred to plan Context sync.
  - Context synchronization: synced

- [x] T02: `Fix rollover ordering and provider refresh` (status:done)
  - Task ID: T02
  - Scope: In — `_BackgroundStartup._run` runs rollover before reminder reschedule, `_rollover` returns moved ids/days and invalidates all affected day keys (source days + today) + week/month/dashboard, resume path shares the same helper. Out — reminder scheduling logic itself.
  - Dependencies: T01
  - Done when: Seeding a pending task yesterday then cold-starting or resuming shows it on today with no manual create/edit; week/month/upcoming caches reflect the move; no duplicate rows or lost sort/tags.
  - Verify: `flutter analyze lib/src/app/app.dart` — no issues; manual code review: `_run` awaits `_rollover` before timezone/reschedule, trailing rollover removed, resume shares helper.
  - Completed: 2026-09-30
  - Files changed: lib/src/app/app.dart
  - Result: `_rollover` now returns moved count and invalidates all day/range/month families + dashboard; startup runs rollover before reschedule.
  - Context impact: architecture startup ordering + invalidation map changed; domain repair in final sync.
  - Context synchronization: synced

- [x] T03: `Reschedule reminders for rolled tasks and harden startup/toggle` (status:done)
  - Task ID: T03
  - Scope: In — `TaskReminderScheduler.reschedulePending` after rollover (cold start), resume-triggered resync for moved timed tasks (cancel stale + schedule new), `_initTimeZone` ensured before any `zonedSchedule` including settings toggle-on, toggle-on/off registry correctness. Out — untimed default (covered in T05), exact-alarm switch (covered in T06).
  - Dependencies: T02
  - Done when: A timed task carried to today has both due + pre reminders scheduled (registry contains id, `plannerReminderTimes` anchored to new day returns future instants); resume after rollover does the same; enabling the toggle from off schedules without timezone crash; disabling cancels all without killing the workout channel.
  - Verify: `flutter test test/task_reminders_test.dart test/carryover_reminder_repro_test.dart` — all passed; `flutter analyze` — only 2 pre-existing unused-element warnings in settings_screen.
  - Completed: 2026-09-30
  - Files changed: lib/src/app/app.dart, lib/src/settings/screens/settings_screen.dart
  - Result: Resume now chains rollover then silent timezone-aware reschedule; toggle-on ensures timezone before reschedule; toggle-off still cancelAll.
  - Context impact: startup/resume + toggle lifecycle changed; domain repair in final sync.
  - Context synchronization: synced

- [x] T04: `Fix reminder lifecycle on task mutations and permission` (status:done)
  - Task ID: T04
  - Scope: In — add/edit/done/cancel/delete/undo/scope-edit paths cancel-then-schedule correctly for timed tasks (cleared time drops reminders, undone restores them, series edits resync affected occurrences), user-initiated scheduling requests `POST_NOTIFICATIONS` permission, past-due/done/cancelled never schedule (untimed covered in T05). Out — experiment/goal schedulers, exact-alarm permission (covered in T06).
  - Dependencies: T03
  - Done when: Creating/editing a timed task prompts for permission once and schedules pre+due; clearing the time, marking done/cancelled, or deleting cancels both ids; undo re-schedules; recurring scope edits do not leave stale ids.
  - Verify: `flutter test test/task_reminders_test.dart test/carryover_reminder_repro_test.dart` — all 9 passed (incl. new cancelled case); `flutter analyze` — no issues in changed files. Mutation paths audited: planner_screen + detail both cancel-then-sync, done/cancelled drop, undo resyncs.
  - Completed: 2026-09-30
  - Files changed: lib/src/notifications/task_reminders.dart, test/task_reminders_test.dart
  - Result: `plannerReminderTimes` now rejects cancelled tasks in addition to done/past-due/untimed; mutation lifecycle verified correct for timed path.
  - Context impact: reminder never-schedule rule now includes cancelled; domain repair in final sync.
  - Context synchronization: synced

- [x] T05: `Add settings-based default reminder for untimed tasks` (status:done)
  - Task ID: T05
  - Scope: In — new `untimedReminderMinutes` Setting (prefs key, default 540 = 09:00, Advanced numeric field like `reminderLeadMinutes`), `plannerReminderTimes` fallback (`startTimeMinutes ?? prefs untimed default`), `getUpcomingWithStartTime` or new timed-or-untimed query for scheduler, setting change reschedules future untimed reminders, `_syncReminder` permission + schedule for untimed, timeline Anytime grouping unchanged. Out — exact-alarm mode (covered in T06), per-task custom default time.
  - Dependencies: T03
  - Done when: A pending untimed task on today/future schedules due (setting time) + pre (setting time minus lead, 09:00/08:30 with defaults) when future, past-day setting time never schedules, done/cancelled/deleted untimed cancels both ids, changing the setting re-times future untimed reminders, adding a start time later switches to the timed anchor without duplicate ids.
  - Verify: `flutter test test/task_reminders_test.dart test/carryover_reminder_repro_test.dart` — all 11 passed (untimed default + disabled cases); `flutter analyze` — no new issues (4 pre-existing in settings provider, 2 in settings screen); `flutter gen-l10n` regenerated en/fr/es.
  - Completed: 2026-09-30
  - Files changed: lib/src/settings/providers/settings.dart, lib/src/notifications/task_reminders.dart, lib/src/planner/repositories/task_repository.dart, lib/src/planner/screens/planner_screen.dart, lib/src/planner/screens/planner_item_detail.dart, lib/src/settings/screens/settings_screen.dart, lib/l10n/app_en.arb, lib/l10n/app_fr.arb, lib/l10n/app_es.arb, lib/l10n/app_localizations*.dart (generated), test/task_reminders_test.dart
  - Result: Untimed tasks anchor to settings default 540 with lead; scheduler query includes untimed; setting change reschedules silently; Anytime grouping untouched.
  - Context impact: new setting + scheduler semantics; domain repair in final sync.
  - Context synchronization: synced

- [x] T06: `Switch task reminders to exact alarms with silent fallback` (status:done)
  - Task ID: T06
  - Scope: In — `zonedSchedule` with `exactAllowWhileIdle` + `canScheduleExactAlarms` check and silent inexact fallback, `requestExactAlarmsPermission` on user-initiated schedule only (startup/resume/toggle resync never prompts, no persistent nudge), revoked-permission resync handling, manifest verification. Out — experiment/goal/rest schedulers, exact-alarm nudge UI.
  - Dependencies: T05
  - Done when: With permission granted reminders use exact and fire on time under Doze; with denied/revoked they silently fall back to inexact without exception or banner; startup/resume never prompts in background.
  - Verify: `flutter test test/task_reminders_test.dart test/carryover_reminder_repro_test.dart` — all 11 passed; `flutter analyze` on changed files — no issues; manifest declares `SCHEDULE_EXACT_ALARM`.
  - Completed: 2026-09-30
  - Files changed: lib/src/notifications/task_reminders.dart, lib/src/planner/screens/planner_screen.dart, lib/src/planner/screens/planner_item_detail.dart
  - Result: Scheduler resolves exact when granted else silent inexact; user-initiated paths request exact permission; bulk paths never prompt.
  - Context impact: exact-alarm mode + silent fallback; domain repair in final sync.
  - Context synchronization: synced

## Open questions

- None. Untimed default is a Setting defaulting to 09:00 and exact denial silently stays on inexact fallback, per revision.

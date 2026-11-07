# Plan: Notification timers — event-driven refresh + resume resync

## Change Summary

The ongoing active-workout notification's elapsed and rest timers occasionally
freeze; user repro (2026-08-17): both stopped updating and resumed after toggling
network in quick settings — i.e. the background `onRepeatEvent` callback stalls
under Doze / OEM battery optimization, not a text-logic bug. Mitigation: make the
notification refresh **from the UI isolate** whenever a session/rest/set event
happens and when the app resumes, so it is always current at interaction points
even if the background tick stalls.

## Success Criteria

- The notification text builder is shared between the background handler and the
  main isolate.
- The notification updates immediately on rest start/cancel (`rest_timer.dart`)
  and on set-actuals save, and on `AppLifecycleState.resumed`.
- The 1 s background tick still refreshes when the process is healthy (unchanged).
- `dart analyze lib/` clean; `flutter test` passes.

## Constraints & Non-Goals

- No new dependencies; no schema change.
- Full parity on aggressive OEMs stays best-effort (documented).
- Non-goal: changing planner-reminder paths, notification tap routing.

## Task Stack

- [x] T01: `Shared notification-text builder` (status:done)
  - Task ID: T01
  - Goal: Extract the `_updateNotification` text construction from
    `ActiveWorkoutTaskHandler` into a reusable, isolate-safe helper.
  - Boundaries (in/out of scope):
    - In: `lib/src/notifications/active_workout_notifier.dart` — a top-level (or
      static) function `buildActiveWorkoutNotificationText(prefs) => (title, text)`
      reading the persisted keys (elapsed, rest, popup-fire side effects stay in
      the handler); ensure `prefs.reload()` is called first by callers.
    - Out: UI wiring (T02), popup logic.
  - Done when: helper produces identical strings from the same prefs; handler uses
    it; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/notifications/active_workout_notifier.dart`.

- [x] T02: `UI-driven updates on events` (status:done)
  - Task ID: T02
  - Goal: Push `FlutterForegroundTask.updateService(...)` from the UI isolate on
    rest start/cancel and after saving set actuals.
  - Boundaries (in/out of scope):
    - In: `lib/src/notifications/rest_timer.dart` (`RestTimerNotifier.startRest` /
      `cancelRest` — after prefs writes, call the shared builder + `updateService`,
      gated on `Platform.isAndroid` and an active session), `lib/src/exercise/
      screens/active_workout_screen.dart` (`_editActuals` likewise). Keep the
      updates best-effort (try/catch, unawaited).
    - Out: background tick changes.
  - Done when: notification reflects rest start/cancel + set-save immediately;
    `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/`.

- [x] T03: `Resume resync` (status:done)
  - Task ID: T03
  - Goal: Recompute + refresh the notification when the app returns to foreground.
  - Boundaries (in/out of scope):
    - In: `lib/src/exercise/screens/active_workout_screen.dart` — a
      `WidgetsBindingObserver` on the active-workout screen (or `_ElapsedText`)
      whose `didChangeAppLifecycleState(resumed)` triggers the shared-builder +
      `updateService` when a workout is active.
    - Out: cold-start behaviours.
  - Done when: resuming the app updates the notification within ~1 s;
    `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/`.

- [x] T04: `Validation and context sync` (status:done)
  - Task ID: T04
  - Goal: Full checks + `context/notifications/notifications.md` sync + validation
    report.
  - Boundaries (in/out of scope): in — analyze/test/format, context; out — commit.
  - Done when: suite green; context reads back accurate.
  - Verification notes (commands or checks):
    - `dart analyze lib/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`.
  - Notes: device-level verification is deferred (headless env); the user repro
    (network toggle) should be re-tested on device.

## Validation Report

- **T01 — shared builder**: `buildActiveWorkoutNotificationText(prefs)` (top-level,
  isolate-safe, null when no active session) + `refreshActiveWorkoutNotification()`
  (Android-only, try/catch best-effort) added to `active_workout_notifier.dart`;
  `ActiveWorkoutTaskHandler._updateNotification` now builds via the shared helper and
  keeps only the "rest is over" popup side effect. `dart analyze lib/` clean.
- **T02 — event-driven updates**: `RestTimerNotifier.startRest`/`cancelRest` and
  `_SetRow._editActuals` (set-actuals save) each `unawaited(refreshActiveWorkoutNotification())`
  after their prefs/DB writes. `dart analyze lib/` clean.
- **T03 — resume resync**: `_ActiveWorkoutScreenState` is now a
  `WidgetsBindingObserver`; `didChangeAppLifecycleState(resumed)` refreshes the
  notification when `activeWorkoutProvider` is non-null. `dart analyze lib/` clean.
- `flutter analyze lib/` → **No issues found**. `dart format` on edited files → clean.
- `flutter test` → `+39 -4`; the 4 failures are the pre-existing DB-backed tests that
  cannot load `libsqlite3.so` in this env (unrelated). Device-level verification of
  the original repro (toggle network in quick settings) is deferred — headless env.
- Context: `context/notifications/notifications.md` — new "Event-driven refresh"
  bullet + updated flowchart (rest_started_at + UI/resume → refresh).

## Next Command

/next-task notification-timers T04
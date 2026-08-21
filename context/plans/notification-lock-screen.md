# Plan: Rest-timer notifications on the lock screen (Phase NT)

## Change Summary

**Q (review 2026-08-19):** "Why doesn't the timer notification appear on the
lock screen even though all phone notification settings are allowed?"

**Root-cause hypothesis:** neither timer notification pins its content to the
lock screen:

- The **rest-over popup** posts with `importance: high` / `priority: high`
  but **no `visibility`** and **no `category`**
  (`active_workout_notifier.dart` `_fireRestOverPopup`); `AndroidNotificationDetails`
  defaults `visibility` to private, so on a secure lock screen the content is
  redacted/hidden.
- The **ongoing active-workout foreground notification** (`FlutterForegroundTask.init`
  `AndroidNotificationOptions` in `app.dart`) likewise has no public visibility,
  and a foreground-service notification is otherwise easy for the OS to hide.

## Success Criteria

- Rest-over popup and the active-workout foreground notification both show on
  the lock screen (content visible) when the user's device settings allow
  notifications.
- Notification tap behavior unchanged (rest popup → `/active-workout`,
  ongoing → `/active-workout`).
- No effect on other notification types (planner/experiment reminders unchanged).
- Device verification on Android: lock the screen while a workout is active and
  during a rest; the popup is visible on the lock screen.
- `flutter analyze lib/` clean; `flutter test` `+39 -4` (pre-existing sqlite env
  failures).

## Constraints & Non-Goals

- No schema changes, no new dependencies.
- Not trying to bypass the user's own "hide sensitive notifications" OS setting.
- Non-goal: reworking notification channels, iOS parity (best-effort iOS path
  unchanged), full-screen intent behavior changes beyond an explicit opt-in.

## Task Stack

- [ ] T01: `Investigate + reproduce lock-screen suppression` (status:todo)
  - Task ID: T01
  - Goal: Confirm which notification is hidden and why before changing code.
  - Boundaries (in/out of scope):
    - In: reproduce on an Android device/emulator (workout active → lock screen;
      rest running → locked); capture `dumpsys notification` / channel info;
      confirm `FlutterForegroundTask` notification and `flutter_local_notifications`
      defaults (visibility private, category default); record findings in the
      plan before editing.
    - Out: any code change in this task.
  - Done when: root cause confirmed (documented here): missing
    `visibility: public` (+ `category`) on both notifications, or a distinct
    cause found and recorded.
  - Verification notes (commands or checks):
    - `adb shell dumpsys notification --noredact | grep -A15 'fitfat'`;
      lock-screen screenshot before/after a rest popup.

- [ ] T02: `Set visibility + category (rest popup + foreground service)` (status:todo)
  - Task ID: T02
  - Goal: Make both timer notifications lock-screen visible.
  - Boundaries (in/out of scope):
    - In: `active_workout_notifier.dart` `_fireRestOverPopup` — add
      `visibility: NotificationVisibility.public` and
      `category: AndroidNotificationCategory.alarm` to the `AndroidNotificationDetails`;
      `app.dart` `FlutterForegroundTask.init` `AndroidNotificationOptions` —
      add `visibility: NotificationVisibility.public` (keep `onlyAlertOnce`),
      with the ongoing notification marked appropriately (e.g. service
      category) so it remains a foreground notification; verify channel
      importance is high so it can alert while locked.
    - Out: other notification sources, changing channel ids.
  - Done when: both notifications render content on a locked screen; tap still
    routes to `/active-workout`; `dart analyze lib/` clean.
  - Verification notes (commands or checks):
    - `dart analyze lib/src/notifications/ lib/src/app/app.dart`;
      device: locked screen during workout + during rest shows both; tap opens
      the workout.

- [ ] T03: `Validation and context sync` (status:todo)
  - Task ID: T03
  - Goal: Full checks + document the lock-screen behavior and its OS caveat.
  - Boundaries (in/out of scope): in — analyze/format/tests,
    `context/notifications/notifications.md` update (lock-screen section,
    "depends on OS 'show on lock screen' permission"); out — commit.
  - Done when: `flutter analyze lib` clean; `flutter test` `+39 -4`; context
    accurate.
  - Verification notes (commands or checks):
    - `flutter analyze lib`; `flutter test`;
      `dart format --output=none --set-exit-if-changed lib/src/notifications`.

## Open Questions

- Should the rest-over popup also wake the screen via `fullScreenIntent` when
  the screen is off? Default no (keep alerts non-intrusive); recorded for a
  future settings toggle.

## Next Command

/next-task notification-lock-screen T01
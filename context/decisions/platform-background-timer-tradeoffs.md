# Platform tradeoffs for background timers & notifications

Created: 2026-05-19

Purpose
-------
Explain the differences, tradeoffs and recommended approaches for implementing a "Current Seance" background timer, ongoing notification and lock-screen presence on Android and iOS. This is intended to help pick a platform priority and an implementation strategy. The Flutter docs for background processes ("Background processes" guide) highlight three relevant patterns: isolates (background Dart execution), scheduled/background workers (WorkManager-like), and platform foreground services. This file summarizes how those map to our seance timer requirements.

Summary recommendation
----------------------
- Implement Android-first using a foreground service (via a Flutter plugin or thin native bridge) and provide a graceful iOS fallback using local notifications and an in-app indicator. This delivers the most reliable running-timer UX quickly and keeps iOS behavior consistent where platform limits apply.

Why Android-first
------------------
- Android supports long-running foreground services which allow a persistent notification with live content (elapsed time) and actionable buttons (Stop). This can run reliably while the app is backgrounded or the device is locked.
- Android also exposes better lock-screen notification controls and media-style/ongoing notifications which map well to an active workout timer.
- Implementing the foreground service approach delivers the strongest UX with predictable lifecycle control, and fewer platform-specific workarounds.

Key approaches called out in the Flutter docs
-------------------------------------------
The Flutter background-processes guide mentions the following patterns; here's how they map to our needs.

1) Isolates (Dart background execution)
  - Description: Isolates let you run Dart code off the UI thread and can be used with a callback dispatcher for background tasks.
  - Use case fit: Good for CPU-bound background work or short-lived background callbacks (geofencing, periodic processing). Not a reliable way to keep a timer running while the OS suspends the app.
  - Pros: Keep logic in Dart, easy to unit-test, no (or minimal) native code for the logic itself.
  - Cons: OS suspension still stops execution; isolates don't bypass platform background limits.

2) Scheduled/background workers (WorkManager)
  - Description: Plugins like `workmanager` schedule durable tasks that survive restarts and can run at system-determined times.
  - Use case fit: Good for periodic, deferrable tasks (e.g., upload logs, periodic sync). Not suitable for accurate, continuous elapsed-time timers.

3) Foreground service / ongoing notification (recommended for timer)
  - Description: Use a foreground service on Android (via `flutter_foreground_task` or a native service bridge) to keep the app alive and show an ongoing notification with actions.
  - Use case fit: Best fit for a continuous timer that must run reliably while the device is locked or the user switches apps.

Note: The Flutter docs and linked articles emphasize that isolates and scheduled workers are powerful tools but do not replace the need for a platform-level foreground service when you need continuous execution while the OS may suspend normal app processes.

Android-specific options
------------------------
1) Flutter plugin with foreground service support (recommended)
  - Examples: `flutter_foreground_task`. Keeps most logic in Dart and uses a native bridge for the service lifecycle.
  - Pros: Faster to implement, community-tested; reduces native code surface.
  - Cons: Plugin maintenance and device-specific battery-killer issues.

2) Native foreground service with a thin MethodChannel bridge
  - Implement a persistent Android `ForegroundService` written in Kotlin/Java; expose start/stop and elapsed-time updates via MethodChannel or EventChannel.
  - Pros: Maximum control, stable behavior, easy to integrate custom notification UI and lock-screen extras.
  - Cons: More initial native work and CI complexity.

3) WorkManager / scheduled tasks
  - Not suitable for continuous timers; use only for deferrable periodic work.

Android considerations and risks
-----------------------------
- Manifest & runtime: add service declarations to `AndroidManifest.xml` and request WAKE_LOCK when needed.
- Foreground service requires showing a persistent notification; follow Play Store policies for long-running services.
- Battery optimization / OEM task killers: some devices may kill background services; document and test on target devices.

iOS capabilities and limitations
--------------------------------
- iOS intentionally restricts arbitrary background execution. Continuous background timers are not allowed except for specific background modes (audio, location, VOIP) — none are appropriate for a workout timer unless you accept workarounds and App Store review risk.
- Acceptable iOS patterns:
  - Local notifications: schedule local notifications and use `flutter_local_notifications` to show actionable notifications. These do not keep Dart code running continuously in background, but can alert the user.
  - Background fetch: unreliable for sub-minute timing and not suitable for continuous elapsed-time updates.
  - Background audio hack: play a silent audio track to keep the app alive — discouraged and likely to fail App Store review.

The docs make the same point: an isolate or background callback can run Dart code in the background but cannot defeat iOS lifecycle rules. For a user-visible continuous timer, iOS requires a different UX (best-effort notifications + in-app indicator) and clear documentation to users.

Cross-platform UX notes
-----------------------
- AppBar indicator: implement a global, lightweight AppBar widget that subscribes to the active seance Provider and displays an icon + elapsed time. This is platform-independent and will always be visible while the app is running.
- Notification Stop action: wire the notification action to call into the same shared provider via platform channel (Android) or by opening the app and applying the action (iOS local notification action).
- Timer format: use MM:SS under 1h and HH:MM:SS over 1h; ensure the notification and AppBar use the same formatting helper.

Implementation complexity & rough estimates
-----------------------------------------
- Android-first (using `flutter_foreground_task`) — small-medium effort (2–4 days): add plugin, implement service start/stop, hook notification action to provider, add manifest entries, test on several devices.
- Native foreground service bridge — medium effort (3–6 days): write Kotlin service, MethodChannel plumbing, testing and polishing notification UI.
- Using isolates for background callbacks — small effort (1–2 days) to wire background callbacks and test edge cases, but note this does not replace a foreground service for continuous timers.
- iOS fallback (local notifications + in-app indicator) — small effort (1–2 days): add `flutter_local_notifications`, implement notification creation, actions and handler; document limits.
- Full parity (attempting continuous timers on iOS) — high effort and high risk (likely blocked by App Store review): not recommended.

Permissions, manifest & infra changes
------------------------------------
- Android: add `FOREGROUND_SERVICE` permission, declare the `Service` in `AndroidManifest.xml`, add permission rationale (if needed), and update Play Store listing if service runs long.
- iOS: configure `UNUserNotificationCenter` permissions, request notification authorization and add relevant entitlements if using special background modes (not recommended).

Testing guidance
----------------
- Android: test on Pixel, Samsung and at least one OEM-known-aggressive device (Xiaomi/Huawei/OnePlus) to evaluate behavior under battery optimization.
- iOS: test on iPhone with app backgrounded and device locked; verify local notifications appear and tapping notification resumes app to the seance.
- Unit/Widget tests: simulate provider state changes and ensure AppBar indicator updates, notification actions call through correctly.

Fallback UX and user messaging
-----------------------------
- Make it clear in the UI that continuous background timing is best-effort on iOS. Show a tooltip or small help text in the Current Seance screen explaining when the timer may pause/lose accuracy if the app is backgrounded.
- For Android, after first run, show a short onboarding that requests the user to disable battery optimizations for better reliability (explain how to do that on popular OEM skins).

Recommended next step
---------------------
- Proceed Android-first using `flutter_foreground_task` (or a native service if you prefer tight control) and implement iOS fallback with `flutter_local_notifications`. This gives reliable UX quickly and keeps the codebase manageable.

Quick mapping to the plan tasks
------------------------------
- T01/T04 (Current Seance lifecycle & background execution): implement foreground service on Android + local notification fallback on iOS. Use isolates only for short, background callbacks (not for continuous timer). Use WorkManager for any periodic sync tasks that must survive reboot.

References
----------
- Flutter docs: Background processes — https://docs.flutter.dev/packages-and-plugins/background-processes
- Medium article: Executing Dart in the Background with Flutter Plugins and Geofencing (linked from the docs)

Recorded user decisions
-----------------------
- Clone behavior: when cloning a seance, copy everything the seance contains. If the original seance included planned sets/rest metadata, keep it; if the seance only had exercises, copy exercises only.
- Strength goals: user picks a specific exercise and a weight target (metric units). UI should allow selecting an exercise (e.g., Bench/Squat/Deadlift or any custom exercise) and entering a numeric kg target and target date.

File path: `context/decisions/platform-background-timer-tradeoffs.md`

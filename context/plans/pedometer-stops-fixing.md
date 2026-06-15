# Plan: Fix pedometer stops tracking after some time

## Change summary

The `StepTrackerNotifier` pedometer subscription stops working some time after the user starts walking. Two root causes:

1. **Provider disposed on tab switch** — `StepTrackerNotifier` is a plain `Notifier`. When the user navigates to the Settings tab (or any view that doesn't watch `stepTrackerProvider`), Riverpod auto-disposes it. `ref.onDispose` cancels the pedometer subscription. On return, a new subscription is created but the sensor may not re-deliver events reliably.

2. **Silent stream death** — The pedometer stream's `onError` handler is empty (`onError: (_) {}`), so any error from the sensor terminates the subscription permanently with no recovery mechanism.

Fix:
1. Call `ref.keepAlive()` in `build()` so the provider survives tab switches and the pedometer stream stays registered continuously.
2. Replace empty `onError` with a reconnection strategy: log the error, cancel the old subscription, and retry `_initPedometer()` after a short delay.
3. Add an `onDone` handler that also reconnects.

Bonus: Add a periodic cumulative-step sanity check (every 30s via `Stream.periodic`) to detect when the sensor silently stopped delivering events. If no event was received in the last 30s, query the latest cumulative value via `Pedometer.stepCountStream` with a single-shot async get.

## Success criteria

- Steps increment continuously on the dashboard while walking, even after switching to Settings tab and back.
- Steps increment after the phone's screen turns off and on again.
- `flutter analyze` reports 0 errors.
- `dart format` clean.

## Constraints and non-goals

- **In scope**: `StepTrackerNotifier` lifetime, stream error recovery, stream completion recovery, periodic sanity check.
- **Out of scope**: Health Connect integration, background service for step tracking, iOS-specific fixes, UI changes.
- **Constraint**: Should not repeatedly re-request permission on tab switches.

## Task stack

### T01: Fix pedometer stream lifetime, error recovery, and periodic sanity check

- [x] T01: Fix pedometer stream lifetime, error recovery, and periodic sanity check (status:done)
  - Task ID: T01
  - Goal: Make `StepTrackerNotifier` keep the pedometer stream alive across tab switches, recover from stream errors, and periodically verify the sensor is still delivering events.
  - Boundaries:
    - In — `lib/src/dashboard/providers/dashboard.dart` only.
    - Out — UI changes, new packages, iOS config, Android manifest changes.
  - Done when:
    1. ✅ `StepTrackerNotifier` uses `ref.keepAlive()` to survive Riverpod disposal.
    2. ✅ Pedometer stream `onError` and `onDone` both trigger a reconnection attempt after a delay.
    3. ✅ A 30-second periodic timer checks if sensors stalled >45s and triggers re-sync.
    4. ✅ `_permissionGranted` flag prevents re-request loops on reconnect.
    5. ✅ `flutter analyze` 0 errors.
  - Verification notes: `flutter analyze` reports 0 errors; `dart format .` reports 0 changes; code review confirms the three fix patterns are present.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/providers/dashboard.dart`

### T02: Validation and context sync

- [x] T02: Run flutter analyze, dart format, and sync context (status:done)
  - Task ID: T02
  - Goal: Final validation pass and context synchronization.
  - Boundaries: In — validation commands, context sync. Out — functional changes.
  - Done when: `flutter analyze` 0 errors; `dart format` clean; context synced.
  - Verification notes: Standard validation output.
  - **Status:** done
  - **Evidence:**
    - `flutter analyze` → 0 errors, 0 warnings, 9 pre-existing info hints
    - `dart format` → 86 files formatted, 0 changed
    - Context verified: overview.md, architecture.md, context-map.md unchanged (verify-only change)

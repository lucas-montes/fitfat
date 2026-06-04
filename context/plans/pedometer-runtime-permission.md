# Pedometer: runtime permission fix

## Change summary

The pedometer step tracking on the dashboard doesn't work on Android 10+ because the `ACTIVITY_RECOGNITION` permission is declared in the manifest but never requested at runtime. On Android 10+ (API 29+), this is a **dangerous permission** and must be granted by the user via a runtime prompt before `Pedometer.stepCountStream` will return data.

The fix:
1. Add `permission_handler: ^11.3.1` dependency to `pubspec.yaml`.
2. Before subscribing to `Pedometer.stepCountStream`, request `Permission.activityRecognition()` at runtime.
3. If the user denies, show a one-time explanatory snackbar and keep steps at 0 (graceful fallback — no crash loops, no re-prompt spam).
4. If the user permanently denies, direct them to system settings once (one-time snackbar).

## Success criteria

- Step count increments on the dashboard card after granting the permission prompt on a real Android 10+ device.
- Permission denied → steps show 0, no crash, no infinite re-prompt loop.
- `flutter analyze` reports 0 errors.
- `dart format` clean.

## Constraints and non-goals

- **In scope**: Runtime permission request + graceful denial handling.
- **Out of scope**: Health Connect integration (already explicitly out of scope per the original plan).
- **Out of scope**: Manual step editing.
- **Out of scope**: iOS permission handling (can be added later; `permission_handler` already supports it).
- **Constraint**: Permission should only be requested once per app session unless the user explicitly re-triggers it.
- **Constraint**: The `permission_handler` package on Android also requires the `activity_recognition` query element — already present in the manifest.

## Task stack

### T01: Add permission_handler dependency and wire runtime permission request

- [x] T01: Add permission_handler package and request runtime ACTIVITY_RECOGNITION permission (status:done)
  - Task ID: T01
  - Goal: Add `permission_handler: ^11.3.1` to `pubspec.yaml`, run `flutter pub get`. In `StepTrackerNotifier._initPedometer()`, request `Permission.activityRecognition()` before subscribing to `Pedometer.stepCountStream`. Handle grant/denied/permanentlyDenied states. Show a snackbar explaining why step tracking needs the permission if denied.
  - Boundaries: In — `pubspec.yaml`, `lib/src/dashboard/providers/dashboard.dart`. Out — iOS config, Android manifest changes (already done in original plan T01).
  - Done when: On a real Android device, a permission dialog appears and steps start tracking after grant. On denial, steps stay at 0 with a snackbar explanation. `flutter analyze` reports 0 errors.
  - Verification notes: `flutter analyze` passes; code review confirms permission request before pedometer subscription.
  - **Status:** done
  - **Files changed:** `pubspec.yaml`, `lib/src/dashboard/providers/dashboard.dart`, `lib/src/dashboard/screens/status_cards.dart`

### T02: Validation and cleanup

- [x] T02: Run flutter analyze, dart format, and sync context (status:done)
  - Task ID: T02
  - Goal: Final validation pass — `flutter analyze`, `dart format`, and `sce-context-sync` to keep context files current.
  - Boundaries: In — validation commands, context sync. Out — functional changes.
  - Done when: `flutter analyze` 0 errors; `dart format` clean; context synced.
  - Verification notes: Standard validation output.
  - **Status:** done
  - **Evidence:**
    - `flutter analyze` → 0 errors, 0 warnings, 3 pre-existing info hints
    - `dart format` → 70 files formatted, 0 changed

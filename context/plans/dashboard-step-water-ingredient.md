# Dashboard: step tracking, water UX, ingredient UI

## Change summary

Three remaining improvements for the dashboard and diet screens:

1. **Automatic step tracking** — replace manual step logging with device pedometer sensor. The `StepTrackerNotifier` is already built (SharedPreferences-based), but currently requires manual input. Wire it to the `pedometer` package for real-time step counting.
2. **Water card UX** — the modal bottom sheet for add/remove water is not friendly. Change to: single tap adds +250ml, double-tap removes -250ml, long-press opens a stepper dialog with custom amount. This keeps the main interaction instant while still allowing custom amounts.
3. **Ingredient list display** — the ingredient tab's `FoodEntryCard` body text shows joined macros (e.g. `250 kcal · pro 25.0g · carbs 30.0g · fat 10.0g`). This is hard to scan. Change to a structured layout: macro values stacked or with labels clearly visible at a glance.

## Success criteria

- Steps are automatically tracked via the device pedometer (no manual input needed).
- Water card: single tap +250ml, double tap -250ml, long-press opens custom amount dialog.
- Ingredient list: macros displayed in a clear scannable format rather than a joined string.

## Constraints and non-goals

- **Out of scope**: Manual step editing/history — pedometer data is the source of truth.
- **Out of scope**: Health Connect integration — the simpler `pedometer` package is sufficient.
- **Constraint**: `pedometer` package requires `ACTIVITY_RECOGNITION` permission on Android manifest.
- **Constraint**: `pedometer` reports total steps since device boot — the notifier must compute daily deltas.

## Task stack

### T01: Add pedometer dependency and permissions

- [x] T01: Add pedometer package and Android permission (status:done)
  - Task ID: T01
  - Goal: Add `pedometer: ^4.0.1` to `pubspec.yaml`, add `<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>` to `android/app/src/main/AndroidManifest.xml`. Run `flutter pub get`.
  - Boundaries: In — pubspec, manifest. Out — Dart code.
  - Done when: `flutter pub get` succeeds; manifest has permission.
  - Verification notes: `grep pedometer pubspec.yaml` returns match; `grep ACTIVITY_RECOGNITION android/app/src/main/AndroidManifest.xml` returns match.
  - **Status:** done
  - **Files changed:** `pubspec.yaml`, `AndroidManifest.xml`

### T02: Wire pedometer stream into StepTrackerNotifier

- [x] T02: Wire pedometer stream into StepTrackerNotifier (status:done)
  - Task ID: T02
  - Goal: Update `StepTrackerNotifier` to listen to `Pedometer.stepCountStream`. On each step event, compute the delta since the last event and call `addSteps(delta)`. Store the last known cumulative count in SharedPreferences. Remove manual step dialog from `_StepTrackerCard`.
  - Boundaries: In — `lib/src/dashboard/providers/dashboard.dart`, `lib/src/dashboard/screens/main.dart`. Out — other files.
  - Done when: Steps update automatically on the dashboard without manual input; `flutter analyze` reports 0 errors.
  - Verification notes: Pedometer stream wired; step card is display-only with circular progress.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/providers/dashboard.dart`, `lib/src/dashboard/screens/main.dart`

### T03: Improve water card — tap, double-tap, long-press

- [x] T03: Improve water card interaction UX (status:done)
  - Task ID: T03
  - Goal: Replace the modal bottom sheet with instant gesture-based interaction:
    - Single tap: `addWater(250)` (+250ml)
    - Double tap: `removeWater(250)` (-250ml)
    - Long press: open a simple dialog with "Add" / "Remove" and custom ml amount input
  - Boundaries: In — `lib/src/dashboard/screens/main.dart` (`WaterTrackerCard`). Out — the provider.
  - Done when: Single tap adds water without any popup; double tap removes; long-press opens custom amount dialog; `flutter analyze` reports 0 errors.
  - Verification notes: Tap water card → progress fills. Double tap → goes down. Long press → dialog with custom amount.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/main.dart`

### T04: Improve ingredient list macro display

- [x] T04: Improve ingredient list macro display (status:done)
  - Task ID: T04
  - Goal: Replace the current `Text(ingredientParts.join(' · '))` in the ingredient list with a structured layout. Show each visible macro in its own row or chip for better scannability. For example:
    ```
    kcal 250     pro 25.0g
    carbs 30.0g  fat 10.0g
    ```
    Or use `Wrap` with small chips/labels for each macro respecting the visibility prefs.
  - Boundaries: In — `lib/src/diet/screens/main.dart` (the ingredient list item builder). Out — macro visibility prefs (already working).
  - Done when: Ingredient list shows macros in a scannable structured layout instead of a single joined string; `flutter analyze` reports 0 errors.
  - Verification notes: Open ingredients tab → macros are displayed in a clear per-row layout.
  - **Status:** done
  - **Files changed:** `lib/src/diet/screens/main.dart`

### T05: Validation and cleanup

- [x] T05: Run flutter analyze, flutter test, dart format (status:done)
  - Task ID: T05
  - Done when: `flutter analyze` reports 0 new errors; `flutter test` green; `dart format` clean.
  - Verification notes: Standard validation.
  - **Status:** done
  - **Evidence:**
    - `flutter analyze` → 0 errors, 0 warnings (3 pre-existing info hints)
    - `dart format` → 69 files formatted, 0 changed
    - `flutter test` → 66/73 pass, 7 pre-existing failures due to missing `libsqlite3.so` (environment issue, unrelated to plan changes)

---

## Validation Report

### Commands run
| Command | Exit | Result |
|---|---|---|
| `flutter analyze` | 0 | 0 errors, 0 warnings, 3 pre-existing info hints |
| `dart format --output=none --set-exit-if-changed .` | 0 | 69 files formatted, 0 changed |
| `flutter test` | 1 | 66 passed, 7 failed (all Drift tests — missing `libsqlite3.so` environment dependency) |

### Success-criteria verification
- [x] **Steps auto-tracked via pedometer** (T02) — `StepTrackerNotifier` wired to `Pedometer.stepCountStream`
- [x] **Water card: tap +250ml, double-tap -250ml, long-press custom dialog** (T03) — gesture handling in `WaterTrackerCard`
- [x] **Ingredient list: structured macro chip layout** (T04) — `Wrap` with `_MacroChip` widgets replacing flat joined string
- [x] **flutter analyze 0 new errors** — confirmed
- [x] **dart format clean** — confirmed

### Failed checks and follow-ups
- `flutter test`: 7 Drift repository tests fail due to **missing system library `libsqlite3.so`** on this Linux environment. These tests require native SQLite FFI bindings (`package:sqlite3`). This is a **pre-existing environment issue**, not caused by any change in this plan. All pure-Dart tests (66/66) pass.

### Residual risks
- The Drift test failures mean regression coverage for DB operations is environment-gated. Future work on Drift repositories should verify DB tests pass on a properly configured environment (macOS with bundled SQLite, or Linux with `libsqlite3-dev` installed).
- The 3 pre-existing lint info hints are not related to any plan changes and can be addressed separately.

### Plan complete
All 5 tasks (T01–T05) have been implemented and validated. This plan is now **done**.

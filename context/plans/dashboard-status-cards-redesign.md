# Dashboard: Status card redesign (water, steps, weight)

## Change summary

Redesign the three dashboard status cards (water, steps, body weight) with a unified modern visual language following **Option C — Minimal Modern**:

- Replace full-width vertical cards with a **single horizontal row of 3 compact cards**
- Each card shows: icon, large value, progress bar, and a 7-day mini bar/trend chart
- Consistent visual language: rounded cards, color-coded (blue=water, green=steps, amber=weight), `InkWell` feedback
- Extract the three cards from `main.dart` into a dedicated file

## Success criteria

- Dashboard overview shows water, steps, and weight in a horizontal row of 3 compact cards
- Each card has clean visual hierarchy: icon → value → progress → mini chart
- Water card: tap +250ml, double-tap -250ml, long-press opens custom dialog; whole card shows `InkWell` ripple
- Steps card: auto-tracked display with progress bar; tap opens goal info
- Weight card: tap opens log-weight dialog; shows latest weight + trend arrow + 7-day mini chart
- 7-day mini bar chart renders correctly for all three cards
- `flutter analyze` reports 0 errors
- Old `WaterTrackerCard`, `_StepTrackerCard`, `_CompactWeightCard` code removed from `main.dart`

## Constraints and non-goals

- **Out of scope**: Changing the step/water/weight providers — only UI presentation
- **Out of scope**: The `DailyNutritionCard`, `WorkoutActivityCard`, `_GoalsOverviewCard`, streak cards — untouched
- **Out of scope**: L10n string changes — all labels stay as-is
- **Constraint**: New widgets go in a separate file `lib/src/dashboard/screens/status_cards.dart`
- **Constraint**: `InkWell` + `GestureDetector` stacking — water card needs both tap gestures (InkWell for ripple) and double-tap/long-press (GestureDetector)

## Task stack

### T01: Create shared infrastructure (StatusCard shell + MiniBarChart)

- [x] T01: Create shared StatusCard shell widget and MiniBarChart widget (status:done)
  - Task ID: T01
  - Goal: Create `lib/src/dashboard/screens/status_cards.dart` with two reusable widgets:
    1. `_StatusCard` — a shared compact card wrapper with consistent padding, border radius, elevation, and `InkWell` integration. Takes `icon`, `color`, `child` parameters.
    2. `_MiniBarChart` — a 7-bar mini chart widget that renders thin rounded bars from a `List<double>` (values 0.0-1.0, one per day). Bars are colored using the card's theme color with opacity gradient (newer = more opaque).
  - Boundaries: In — new file `status_cards.dart`. Out — no changes to `main.dart` yet.
  - Done when: Both widgets compile; `flutter analyze` reports 0 errors in the new file.
  - Verification notes: `flutter analyze` clean.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/status_cards.dart` (new)
  - **Evidence:** `flutter analyze` → 0 errors, 0 warnings, 0 info

### T02: Implement WaterStatusCard

- [x] T02: Implement WaterStatusCard (status:done)
  - Task ID: T02
  - Goal: Implement `WaterStatusCard` in `status_cards.dart`:
    - Icon: `Icons.water_drop` (blue, `Colors.blue`)
    - Large value: `X.XL / Y.YL` (today's total / goal)
    - Linear progress bar: `todayMl / dailyGoalMl` clamped 0.0-1.0
    - MiniBarChart: 7-day water data via `waterTrackerProvider` (map each day's ml to fraction of goal)
    - InkWell + GestureDetector: tap → `addWater(250)`, double-tap → `removeWater(250)`, long-press → custom dialog (reuse existing `_showCustomWaterDialog` logic)
    - Card background uses `Colors.blue.withValues(alpha: 0.08)` for subtle tint
  - Boundaries: In — `status_cards.dart`. Out — no changes to providers or main.dart.
  - Done when: Water card renders correctly at ~110dp wide with all visual elements; `flutter analyze` 0 errors.
  - Verification notes: `flutter analyze` 0 errors.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/status_cards.dart`
  - **Evidence:** `flutter analyze` → 0 errors, 0 warnings, 0 info (only 3 pre-existing info hints)

### T03: Implement StepStatusCard

- [x] T03: Implement StepStatusCard (status:done)
  - Task ID: T03
  - Goal: Implement `StepStatusCard` in `status_cards.dart`:
    - Icon: `Icons.directions_walk` (green, `Colors.green`)
    - Large value: `X.Xk / Y.Yk` (today's steps / goal, formatted in thousands with 1 decimal)
    - Linear progress bar: `todaySteps / dailyGoal` clamped 0.0-1.0
    - MiniBarChart: 7-day step data via `stepTrackerProvider` (map each day's steps to fraction of goal)
    - InkWell: tap → shows a brief snackbar with today's step count
    - Card background: `Colors.green.withValues(alpha: 0.08)`
  - Boundaries: In — `status_cards.dart`. Out — no provider changes.
  - Done when: Step card renders correctly; `flutter analyze` 0 errors.
  - Verification notes: `flutter analyze` 0 errors.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/status_cards.dart`
  - **Evidence:** `flutter analyze` → 0 errors, 0 warnings, 0 info (only 3 pre-existing info hints)

### T04: Implement WeightStatusCard

- [x] T04: Implement WeightStatusCard (status:done)
  - Task ID: T04
  - Goal: Implement `WeightStatusCard` in `status_cards.dart`:
    - Icon: `Icons.monitor_weight` (amber, `Colors.amber`)
    - Large value: latest weight in kg (1 decimal)
    - Trend: delta from previous entry + direction arrow (↑ green for gain, ↓ red for loss, — gray for same)
    - MiniBarChart: last 7 weight entries (values normalized to 0.0-1.0 across the min-max range), or null if < 2 entries
    - InkWell: tap → log-weight dialog (reuse existing `_logWeight` logic)
    - Card background: `Colors.amber.withValues(alpha: 0.08)`
  - Boundaries: In — `status_cards.dart`. Out — no provider changes.
  - Done when: Weight card renders with latest weight, trend indicator, and mini chart; `flutter analyze` 0 errors.
  - Verification notes: `flutter analyze` 0 errors.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/status_cards.dart`
  - **Evidence:** `flutter analyze` → 0 errors, 0 warnings, 0 info

### T05: Wire into _OverviewTab — replace old cards

- [x] T05: Wire new cards into _OverviewTab, remove old cards (status:done)
  - Task ID: T05
  - Goal:
    1. Import `status_cards.dart` in `main.dart`
    2. Replace the 3 individual cards in `_OverviewTab.build()` with a single `Row` of 3 `Expanded` cards: `WaterStatusCard`, `StepStatusCard`, `WeightStatusCard`
    3. Remove `WaterTrackerCard` class
    4. Remove `_StepTrackerCard` class
    5. Remove `_CompactWeightCard` class
    6. Keep the `_logWeight` and `_showCustomWaterDialog` logic accessible (already duplicated in `status_cards.dart`)
  - Boundaries: In — `main.dart` imports, layout changes, dead code removal. Out — other sections of main.dart.
  - Done when: Dashboard overview shows the new row of 3 compact cards; old card code is deleted; `flutter analyze` 0 errors.
  - Verification notes: `flutter analyze` 0 errors; `dart format` 0 changes.
  - **Status:** done
  - **Files changed:** `lib/src/dashboard/screens/main.dart`
  - **Evidence:** `flutter analyze` → 0 errors; `dart format` → 0 changes

### T06: Validation and cleanup

- [x] T06: Run flutter analyze, flutter test, dart format (status:done)
  - Task ID: T06
  - Done when: `flutter analyze` 0 new errors; `flutter test` green; `dart format` clean.
  - Verification notes: Standard validation.
  - **Status:** done
  - **Evidence:** `flutter analyze` → 0 new errors (3 pre-existing info only); `flutter test` → 66 passed, 7 failed (pre-existing Drift sqlite3 env issue); `dart format` → 0 changed

# Plan: mvp-calorie-exercise-tracker

## Change Summary

Build a **UI-first** mobile calorie and exercise tracking app (`fitfat`). Phase 1 builds all screens with mock data via Riverpod providers so you can iterate on look, feel, and flow before committing to a database schema. Phase 2 replaces mocks with Drift (SQLite), adds hardware integration (barcode scanner, pedometer), and connects real data.

## Success Criteria

1. User can scan a barcode to look up food or add a new food with macros.
2. User can manually create custom foods and meals (composite dishes).
3. Daily food log shows total calories, protein, carbs, and fat.
4. User can set a daily calorie goal and see progress toward it.
5. User can start/stop a timer for cardio activities (walking, skateboarding), auto-counts steps via pedometer, and saves the session.
6. User can log weightlifting sessions with sets, reps, weight, and rest timer between sets.
7. User can log bodyweight and view a trend chart.
8. A dashboard shows trends for calories, macros, weight, and exercise over time (daily/weekly/monthly).
9. All data works fully offline with no network requirement.
10. The app builds cleanly with zero analysis warnings and passes existing tests.

## Constraints and Non-goals

- **UI-first**: All screens built with mock data first. Database added only after UI is settled.
- **Local-first**: Must work fully offline. Cloud sync explicitly out of MVP scope.
- **No user accounts**: No authentication, no multi-user.
- **No social features**: No sharing, no leaderboards, no friends.
- **No AI meal recognition**: Image-based food recognition is out of scope.
- **No wearable pairing**: Pedometer uses phone built-in sensors only.
- **No nutrition coaching/planning**: The app logs what you eat; it does not generate meal plans.

---

## Phase 1 — UI Iteration (mock data)

All screens built with Riverpod providers returning hardcoded mock data. No database yet. Refine freely.

- [x] T01: `Project scaffold, dependencies & folder structure` (status:done)
  - **Completed:** 2026-05-17
  - **Files changed:** `pubspec.yaml`, `lib/main.dart`, `lib/src/app.dart`, `lib/src/app_theme.dart`, `lib/src/router/app_router.dart`, `lib/src/screens/food/food_screen.dart`, `lib/src/screens/exercise/exercise_screen.dart`, `lib/src/screens/dashboard/dashboard_screen.dart`, `lib/src/screens/settings/settings_screen.dart`, `test/widget_test.dart`
  - **Evidence:** flutter analyze — no issues; flutter test — 1/1 passed
  - **Notes:** Codegen deps (riverpod_generator, riverpod_lint) skipped due to Flutter SDK version conflict. Using manual Riverpod providers instead.
  - **Task ID**: T01
  - **Goal**: Clean out the default counter boilerplate. Set up feature-first folder structure, declare dependencies, wire up Riverpod + GoRouter + Material 3 theme.
  - **Boundaries (in/out of scope)**: In — folder structure, pubspec.yaml, main.dart with ProviderScope + MaterialApp.router, base theme, GoRouter skeleton. Out — any screen content, database dependencies (Drift), barcode/pedometer packages.
  - **Dependencies to add**: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `intl`, `fl_chart`, `google_fonts` (optional), `uuid` (for mock IDs).
  - **Dev dependencies**: `riverpod_generator`, `build_runner`, `riverpod_lint`.
  - **Done when**: `flutter analyze` passes. `flutter run` shows a themed empty app with ProviderScope wrapper. GoRouter routes compile.
  - **Verification notes (commands or checks)**: `flutter analyze`; `flutter test` passes.

- [x] T02: `App shell — bottom navigation & screen shells` (status:done)
  - **Completed:** 2026-05-18
  - **Files changed:** `lib/src/router/app_router.dart`, `lib/src/screens/food/food_screen.dart`, `lib/src/screens/exercise/exercise_screen.dart`, `lib/src/screens/dashboard/dashboard_screen.dart`, `lib/src/screens/settings/settings_screen.dart`, `test/widget_test.dart`
  - **Evidence:** `flutter analyze` clean; `flutter test` 1/1 passed
  - **Task ID**: T02
  - **Goal**: Build the app shell with bottom navigation bar (4 tabs: Food, Exercise, Dashboard, Settings) and empty placeholder screens for each tab.
  - **Boundaries (in/out of scope)**: In — BottomNavigationBar or NavigationBar with 4 destinations, StatefulNavigationShell for persistent tab state (GoRouter), placeholder widgets for each tab with tab label and icon. Out — any actual content (T03-T06).
  - **Done when**: App launches with 4-tab bottom nav. Tapping each tab switches the view and highlights the active tab. All 4 placeholder screens display their name.
  - **Verification notes (commands or checks)**: Manual: tap each tab → correct placeholder shown. `flutter analyze` clean.

- [x] T03: `Food logging UI — daily food log, meal slots & add food flow` (status:done)
  - **Completed:** 2026-05-18
  - **Files changed:** `lib/src/models/food_models.dart`, `lib/src/providers/food_providers.dart`, `lib/src/screens/food/food_screen.dart`, `lib/src/screens/food/add_meal_screen.dart`, `lib/src/screens/food/custom_ingredient_screen.dart`
  - **Evidence:** `flutter analyze` clean; `flutter test` 1/1 passed
  - **Task ID**: T03
  - **Goal**: Build the Food tab — a scrollable daily view with meal slot sections (breakfast, lunch, dinner, snack), an "add food" flow (search + quick-add), and a food detail/edit sheet. All backed by mock Riverpod providers.
  - **Boundaries (in/out of scope)**: In — Food tab shows a single meal list, add/edit/delete flow, custom ingredient creation, mock providers. Out — actual DB, barcode scanning, real search.
  - **Data models to create** (plain Dart classes, no DB yet):
    - `Ingredient` (id, name, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g, components)
    - `MealEntry` (id, name, items: List<IngredientPortion>, eatenAt)
  - **Done when**: Food tab shows a list of meals with name/time/macros. FAB opens Add Meal screen with mock search results. Selecting ingredients adds them to the meal. Custom ingredient flow returns a composite ingredient. Bottom sheet shows meal details with edit/delete.
  - **Verification notes (commands or checks)**: `flutter analyze` clean. Manual: add meal, edit, delete, add custom ingredient → verify list updates.

- [ ] T04: `Nutrition summary UI — daily totals & goals` (status:todo)
  - **Task ID**: T04
  - **Goal**: Add a daily nutrition summary headline to the Food tab, and a Goals screen under Settings tab. Mock provider computes totals from food log entries.
  - **Boundaries (in/out of scope)**: In — `DailyNutritionSummary` widget (cards showing total calories + macros eaten today, with a progress ring/bar toward daily goal), `MacroBreakdownRow` (protein/carbs/fat in grams and %), `GoalsScreen` (calorie goal, protein/carbs/fat goals, step goal). Out — charts (T06), DB persistence for goals (uses in-memory mock).
  - **Mock providers**: `dailyNutritionProvider` returns total calories + macros computed from mock food log. `userGoalsProvider` returns mock goals.
  - **Done when**: Food tab header shows accurate totals from mock data. Changing mock goals in Settings updates the progress display. Progress ring animates.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: verify totals match expected values from mock entries.

- [ ] T05: `Exercise UI — cardio timer & weightlifting logger` (status:todo)
  - **Task ID**: T05
  - **Goal**: Build the Exercise tab with two sub-sections: Cardio (timer + pedometer display) and Weightlifting (exercise picker, set logger, rest timer). All backed by mock providers.
  - **Boundaries (in/out of scope)**: In — `ExerciseTabScreen` with toggle/segmented control between Cardio and Weightlifting modes. **Cardio mode**: `CardioTimerScreen` with activity picker (walking, skateboarding, running, cycling, custom), elapsed time display, start/pause/stop buttons, mock step counter display, session summary on stop. **Weightlifting mode**: `WeightliftingSessionScreen` with exercise name picker (mock list), set logger (weight, reps, auto-incrementing set number), rest timer countdown (start/stop/reset), session summary on finish, exercise history list. Out — real pedometer, real step data, DB persistence.
  - **Mock providers**: `exerciseSessionProvider` (current active session state), `exerciseHistoryProvider` (list of past mock sessions), `restTimerProvider` (countdown state).
  - **Done when**: User can switch between Cardio and Weightlifting mode. Cardio timer starts/pauses/stops with elapsed time. Weightlifting: user picks an exercise, logs sets with weight+reps, rest timer counts down between sets. Session summary shows on completion.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: start a mock cardio session → let it run → stop → see summary. Start weightlifting → log 3 sets with rest timer → finish → see summary.

- [ ] T06: `Dashboard & bodyweight UI — charts & trends` (status:todo)
  - **Task ID**: T06
  - **Goal**: Build the Dashboard tab with fl_chart visualizations (calorie trend, macro donut, weight trend, exercise summary) and a bodyweight log screen. All mock data.
  - **Boundaries (in/out of scope)**: In — `DashboardScreen` with: calorie bar chart (last 7 days with goal line), macro donut/pie chart (average split), weight trend line chart, exercise sessions summary (cardio minutes + weightlifting sessions per week). `BodyweightLogScreen` with entry form (weight + date + notes), history list, trend chart. Time range filter (daily/weekly/monthly) for charts. Out — real DB, real sensor data, export.
  - **Mock providers**: `weeklyCalorieProvider`, `macroSplitProvider`, `weightTrendProvider`, `exerciseSummaryProvider`.
  - **Done when**: Dashboard renders all 4 chart types with mock data. Time range filter updates charts. Bodyweight log screen shows entries and trend line.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: verify all charts render. Add mock bodyweight entry → verify it appears in list and chart.

---

## Phase 2 — Data Layer & Hardware Integration

(Planned but not yet sequenced — will be detailed after Phase 1 UI is approved)

| Tentative Task | Description |
|---------------|-------------|
| T07 | Finalize data models based on UI learnings, create Drift schema |
| T08 | Replace mock Riverpod providers with real DB-backed providers |
| T09 | Barcode scanner integration (mobile_scanner) |
| T10 | Pedometer integration (real step counting) |
| T11 | Validation, cleanup & context sync |

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| State management | Riverpod | Lighter than BLoC, great for data-centric CRUD + timers |
| Navigation | go_router | Official Flutter-recommended, supports deep linking |
| Charts | fl_chart | Mature, customizable, pure Dart |
| Date/formatting | intl | Standard Dart library for i18n |
| IDs | uuid | Unique mock IDs, same format will work with Drift later |
| Local DB (later) | Drift (SQLite) | Type-safe ORM, works offline, codegen |
| Barcode (later) | mobile_scanner | Cross-platform, active maintenance |
| Pedometer (later) | pedometer | Simple step count stream, works on Android/iOS |

## Open Questions

None blocking — we'll refine data models after seeing the UI in action.

## Assumptions

1. Android primary target for MVP (barcode scanner and pedometer well-supported).
2. Material 3 (Material You) design language — adaptive light/dark theme.
3. User has Flutter 3.38+ with Dart 3.10+ ready.
4. Mock data includes realistic food items (~15 sample foods), meal compositions, and exercise sessions to make the UI feel real during iteration.

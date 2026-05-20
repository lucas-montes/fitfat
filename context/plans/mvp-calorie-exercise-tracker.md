# [SUPERSEDED] Plan: mvp-calorie-exercise-tracker

> **Superseded by** `context/plans/unified-roadmap.md` (2026-05-20).
> Tasks carried forward into the unified roadmap. Do not implement from this file.

## Change Summary

Build a **UI-first** mobile calorie and exercise tracking app (`fitfat`). Phase 1 builds all screens with mock data via Riverpod providers so you can iterate on look, feel, and flow before committing to a database schema. Phase 2 replaces mocks with Drift (SQLite), adds hardware integration (barcode scanner, pedometer), and connects real data.

## Success Criteria

1. Bottom navigation has three tabs: Diet, Exercise, Dashboard.
2. Each main tab uses a top TabBar for subsections (Diet: Meals/Ingredients; Exercise: Exercises/Seances).
3. Meals and Ingredients have CRUD flows.
4. Exercises list is available (selection only; no edit), and Seance supports exercises with reps + weight, timer, and rest tracking.
5. Dashboard shows calories/macros summary plus basic charts for strength and bodyweight.
6. Dashboard includes daily + monthly calorie/macro goals with simple editing.
7. All data works fully offline with no network requirement.
8. The app builds cleanly with zero analysis warnings and passes existing tests.

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

- [x] T04: `Navigation update — Diet tab, remove Settings, add top TabBars` (status:done)
  - **Completed:** 2026-05-18
  - **Files changed:** `lib/src/router/app_router.dart`, `lib/src/screens/diet/diet_screen.dart`, `lib/src/screens/food/food_screen.dart`, `lib/src/screens/exercise/exercise_screen.dart`, `lib/src/screens/dashboard/dashboard_screen.dart`, `test/widget_test.dart`
  - **Evidence:** `flutter analyze` clean; `flutter test` 1/1 passed
  - **Task ID**: T04
  - **Goal**: Update bottom navigation to 3 tabs (Diet, Exercise, Dashboard) and add top TabBar subsections for Diet (Meals, Ingredients) and Exercise (Exercises, Seances).
  - **Boundaries (in/out of scope)**: In — rename Food tab to Diet, remove Settings tab, introduce TabBar + TabBarView for Diet and Exercise. Out — any new data behaviors (handled in T05+).
  - **Done when**: Bottom nav shows Diet/Exercise/Dashboard. Diet tab shows Meals/Ingredients tabs. Exercise tab shows Exercises/Seances tabs.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: switch bottom tabs and top tabs → correct views shown.

- [ ] T05: `Diet CRUD — meals & ingredients` (status:todo)
  - **Task ID**: T05
  - **Goal**: Complete CRUD for Meals and Ingredients under the Diet tab, aligned with Meals/Ingredients tabs.
  - **Boundaries (in/out of scope)**: In — create/update/delete meals, create/update/delete ingredients (including composite ingredients), basic list and detail UI. Out — barcode scanning, real search, DB persistence.
  - **Mock providers**: Extend existing food providers to support updates/deletes.
  - **Done when**: Meals and Ingredients tabs both support add/edit/delete; meal list reflects updates.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: add/edit/delete meal and ingredient → list updates.

- [ ] T06: `Exercise — exercises list & seance flow` (status:todo)
  - **Task ID**: T06
  - **Goal**: Build Exercises list (select only) and Seance flow with timer, exercise entries, reps, weight, and rest tracking.
  - **Boundaries (in/out of scope)**: In — exercises list (non-editable), seance start/stop, chrono timer, add exercises with reps + weight, calculate rest time between sets. Out — persistent notification/lockscreen controls (optional future), DB persistence.
  - **Mock providers**: `exerciseListProvider`, `activeSeanceProvider`, `seanceHistoryProvider`, `restTimerProvider` (mocked state).
  - **Done when**: User can start a seance, add exercises with reps/weight, see elapsed time and rest durations, and stop to see a summary.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: start seance → add 2 exercises with sets → stop → summary appears.

- [ ] T07: `Dashboard — nutrition, goals, and basic charts` (status:todo)
  - **Task ID**: T07
  - **Goal**: Show calorie/macro summary plus basic charts for strength and bodyweight. Add daily + monthly goals editing on the Dashboard.
  - **Boundaries (in/out of scope)**: In — summary cards, simple charts (mock), goals editor (daily + monthly). Out — advanced chart filters, DB persistence.
  - **Mock providers**: `dailyNutritionProvider`, `monthlyNutritionProvider`, `goalProvider`, `strengthTrendProvider`, `weightTrendProvider`.
  - **Done when**: Dashboard shows summaries and charts. Goals can be edited and summary updates.
  - **Verification notes (commands or checks)**: `flutter analyze`. Manual: edit goals → summary updates.

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

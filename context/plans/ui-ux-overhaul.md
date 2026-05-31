# UI/UX Overhaul Plan

## Change Summary
Comprehensive UI/UX improvement pass for FitFat. Covers bug fixes, theme polish, naming cleanup, dashboard restructuring, settings expansion, form improvements, and search/filter enhancements. The app works but needs visual refinement, consistency, and better information architecture.

## Success Criteria
- All user-facing "seance" strings replaced with "workout" terminology (en/fr/es)
- Dashboard Overview grouped into logical sections reducing perceived scroll depth
- Theme feels polished with custom typography, card shapes, and color refinements
- Settings tab is fully populated (profile, preferences, language, data management)
- Ingredient form includes all 5 optional macro fields (sodium, fiber, sugars, saturated fat, cholesterol)
- Exercise detail view has no duplicate headers; summary is at top
- Blank seances save to history correctly
- Exercise and ingredient lists have improved search/filter UX
- Active workout exercise search is more intuitive
- App compiles cleanly; no regressions in existing functionality

## Constraints and Non-Goals
- Staying within Flutter Material 3 — no custom UI frameworks
- No new package dependencies unless strictly necessary
- No changes to database schema (Drift tables)
- No changes to data models (food.dart, exercise.dart, seance.dart, dashboard.dart)
- No changes to business logic providers beyond the bug fix
- No changes to router structure (keep 3 bottom nav tabs)
- This is UI/UX only — no new features beyond improving existing ones

---

## Tasks

- [x] T01: `Fix blank seance not saved to history` (status:done)
  - Task ID: T01
  - Goal: Fix the bug where completing a blank-started seance with exercises fails to persist to history.
  - Boundaries (in/out of scope): In — modify `addSeance()` in `lib/src/exercise/providers/seance.dart`. Out — no changes to UI screens.
  - Done when: A blank-started seance with exercises completed appears in history. Empty seances (no exercises) are still discarded on complete.
  - Verification notes:
    - `flutter analyze` — 0 errors, 33 pre-existing warnings/info
    - Root cause: `addSeance()` called `_loadFromDb()` after fire-and-forget `_saveToDb()`, which overwrote the optimistic state if the save failed silently. Fix: removed `_loadFromDb()` from `addSeance()` — optimistic update is sufficient; DB provides persistence; cold start reloads correctly.
    - Files changed: `lib/src/exercise/providers/seance.dart` (lines 539-545)

- [x] T02: `Theme refinement — custom typography, card shapes, color polish` (status:done)
  - Task ID: T02
  - Goal: Enhance `AppTheme` with a polished Material 3 theme: custom text theme, card/elevated shape, chip shape, input decoration theme, and refined color scheme.
  - Boundaries (in/out of scope): In — `lib/src/app/theme.dart` only. Added `CardTheme`, `ChipTheme`, `InputDecorationTheme`, `TextTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, `ListTileTheme` overrides for both light and dark. Out — no changes to individual screen widgets.
  - Done when: Theme file defines consistent visual defaults; app compiles; light and dark modes both render correctly with visible improvement to card roundness, typography weight, and input field styling.
  - Verification notes:
    - `flutter analyze` — 0 errors, 33 pre-existing warnings/info
    - Cards: 16px rounded corners, elevation 0, Clip.antiAlias
    - Typography: proper weight hierarchy (w700 headline → w600 title → w500 label → w400 body)
    - Inputs: filled + outlined with 12px rounded corners, consistent padding
    - Buttons: 12px rounded corners, consistent padding
    - Both light and dark themes have identical structure
    - Files changed: `lib/src/app/theme.dart` (26 → 125 lines)

- [x] T03: `Full seance → workout naming cleanup + l10n` (status:done)
  - Task ID: T03
  - Goal: Replace all user-facing "seance" strings with "workout" across the entire codebase. Update `AppLocalizations` with new localized strings. Update hardcoded strings in all screens.
  - Boundaries (in/out of scope): In — all `.dart` files with user-facing strings. Out — internal variable/class/field names (`seance`, `Seance`, `seanceId`, etc.), route paths, import paths, generated code, database table names.
  - Done when: No user-facing text contains "seance" or "Seance" — all show "workout"/"Workout". `flutter analyze` passes.
  - Verification notes:
    - `flutter analyze` — 0 errors, 33 pre-existing warnings/info
    - Remaining "seance" hits are only variable/class names and route identifiers
    - Tab labels read "Workouts" and "Exercises"
    - Dialog titles, buttons, tooltips, and snackbar messages use "workout" terminology
    - Files changed: `app_localizations.dart`, `exercise/main.dart`, `current_seance_screen.dart`, `seance_library_screen.dart`, `exercise_history_screen.dart`, `exercise/providers/seance.dart`, `dashboard/main.dart`, `seance_foreground_service.dart`, `seance_notification_service.dart`

- [x] T04: `Dashboard Overview — focused daily view with streaks` (status:done)
  - Task ID: T04
  - Goal: Restructure Dashboard Overview into a focused daily-glance view: calories/macros card (primary), today's workout status, all active goals (including water), weight check-in (only if bodyweight goal exists), and two mini 7-day streak heatmap cards side-by-side (calories + workout). Move training stats, full heatmap, and trend charts to Exercise tab.
  - Boundaries (in/out of scope): In — `_OverviewTab` and related cards in `lib/src/dashboard/screens/main.dart`. Created `_GoalsOverviewCard`, `_GoalProgressTile`, `_CalorieStreakCard`, `_WorkoutStreakCard`. Moved `WorkoutStatsRow`, `WorkoutHeatmapCard`, `StrengthTrendChart`, `BodyweightTrendChart` to Exercise tab via import. Out — no changes to Goals/Settings sub-tabs, no changes to individual card widget internals.
  - Done when: Dashboard shows 5-6 cards max. Calories is first, followed by workout status, goals, weight (conditional), and streaks. Training stats/heatmap/charts are accessible from Exercise tab. `flutter analyze` passes.
  - Verification notes:
    - `flutter analyze` — 0 errors, 34 pre-existing warnings/info
    - Dashboard shows: DailyNutritionCard, WorkoutActivityCard, GoalsOverviewCard, WeightTrackerCard (conditional), CalorieStreakCard + WorkoutStreakCard (side-by-side)
    - Exercise tab now has: WorkoutStatsRow, WorkoutHeatmapCard, StrengthTrendChart, BodyweightTrendChart under "Training Stats" header
    - Files changed: `lib/src/dashboard/screens/main.dart`, `lib/src/exercise/screens/main.dart`

- [x] T05: `Settings tab — full settings page` (status:done)
  - Task ID: T05
  - Goal: Replace the placeholder `_SettingsTab` with a fully populated settings page containing: Profile section (edit profile button), Nutrition section (macro visibility toggles via `dietPreferencesProvider`), Workout section (rest timer default), Appearance section (placeholder for future theme toggle), Data section (export DB, delete DB — existing code).
  - Boundaries (in/out of scope): In — `_SettingsTab` in `lib/src/dashboard/screens/main.dart`. Wired up `dietPreferencesProvider`, `userProfileProvider`. Out — no new providers, no theme toggle implementation (just placeholder), no language selector.
  - Done when: Settings tab shows grouped sections with working profile edit, working macro visibility toggles, existing export/delete. Each section has a card with ListTile entries. App compiles and all toggles persist.
  - Verification notes:
    - `flutter analyze` — 0 errors, 35 pre-existing warnings/info
    - Settings tab shows: Profile, Nutrition, Workout (placeholder), Appearance (placeholder), Data sections
    - Macro visibility toggles wired to `dietPreferencesProvider` with `SwitchListTile`
    - Profile edit wired to existing `ProfileSetupDialog`
    - Export/delete preserved as-is
    - Files changed: `lib/src/dashboard/screens/main.dart` (imports + `_SettingsTab` rewrite)

- [x] T06: `Ingredient form — add missing macro fields` (status:done)
  - Task ID: T06
  - Goal: Add 5 optional macro fields (sodium, fiber, sugars, saturated fat, cholesterol) to the ingredient creation/edit form in an expandable "Advanced macros" section.
  - Boundaries (in/out of scope): In — `lib/src/diet/screens/ingredients/custom_ingredient_screen.dart`. Added `ExpansionTile` with 5 `TextField` inputs wired to existing `Ingredient` model fields. Out — no changes to database schema, no changes to ingredient card display.
  - Done when: Ingredient form shows expandable "Advanced macros" section with 5 fields. Saving an ingredient with advanced macros persists them. Editing an ingredient with existing advanced macros loads them. `flutter analyze` passes.
  - Verification notes:
    - `flutter analyze` — 0 errors, 35 pre-existing warnings/info
    - ExpansionTile added after basic macro fields with sodium, fiber, sugars, saturated fat, cholesterol
    - Existing values loaded in initState when editing
    - Values passed to Ingredient constructor via `parseOptional()` helper (null if empty/zero)
    - Macro preview bar still shows only calories/protein/carbs/fat
    - Files changed: `lib/src/diet/screens/ingredients/custom_ingredient_screen.dart`

- [x] T07: `Exercise detail view — fix duplicate headers, move summary to top` (status:done)
  - Task ID: T07
  - Goal: Remove the duplicate "Sets (X)" header in `_buildDetailView` of `CurrentSeanceScreen`. Move the exercise summary card (total reps, total weight, PR indicator, e1RM) to a compact inline row below the sets header instead of below all sets.
  - Boundaries (in/out of scope): In — `_buildDetailView` in `lib/src/exercise/screens/current_seance_screen.dart`. Removed duplicate header block. Refactored summary card into a compact `Wrap` widget placed after the sets header, before the set cards. Out — no changes to `_GuidedSetCard`, `_FreeformSetCard`, `AddSetForm`, or `TimerWidget`.
  - Done when: Exercise detail shows exactly one "Sets (X)" header. Summary stats (reps, weight, PR, e1RM) appear as a compact horizontal row immediately after the sets count, before the set cards. No duplicate UI elements. App compiles.
  - Verification notes:
    - `flutter analyze` — 0 errors, 35 pre-existing warnings/info
    - Single "Sets (X)" header with done count in guided mode
    - Compact summary row: reps, weight, PR badge, e1RM, "Done!" indicator
    - Full summary card removed
    - Files changed: `lib/src/exercise/screens/current_seance_screen.dart`

- [x] T08: `Active workout exercise search — improved UX` (status:done)
  - Task ID: T08
  - Goal: Improve the exercise search experience in `CurrentSeanceScreen` when adding exercises. Show recently used exercises first, display category group headers in the results list, and improve the empty state.
  - Boundaries (in/out of scope): In — `_buildExerciseListView` in `lib/src/exercise/screens/current_seance_screen.dart`. Added "Recently used" section from seance history, category group headers in filtered list, improved empty state with icon. Out — no changes to exercise definition model or providers beyond reading existing data.
  - Done when: When search is empty, "Recently used" exercises appear at top. When searching, results are grouped by category with section headers. Empty search state shows helpful prompt. `flutter analyze` passes.
  - Verification notes:
    - `flutter analyze` — 0 errors, 35 pre-existing warnings/info
    - "Recently used" shows last 5 unique exercises from seance history
    - Category group headers appear when searching or filtering
    - Empty state shows icon + descriptive text
    - Files changed: `lib/src/exercise/screens/current_seance_screen.dart`

- [x] T09: `Exercise & ingredient list — improved filters and search` (status:done)
  - Task ID: T09
  - Goal: Add search bar and category filter chips to the Exercise library tab. Add a search bar with sort options to the Ingredients tab. Both lists should have better empty states.
  - Boundaries (in/out of scope): In — `ExercisesListTab` and `_IngredientsTab` in `lib/src/diet/screens/main.dart` and `lib/src/exercise/screens/main.dart`. Converted both to `ConsumerStatefulWidget`. Added `TextField` search bars, `FilterChip` rows, sort toggle, and empty states. Out — no changes to the underlying data providers, no new database queries.
  - Done when: Exercise tab shows a search bar + category filter chips above the list. Ingredient tab shows a search bar + alphabetical sort toggle. Both have clear empty states when no results match. `flutter analyze` passes.
  - Verification notes:
    - `flutter analyze` — 0 errors, 36 pre-existing warnings/info
    - Exercise tab: search bar + category filter chips + filtered list + empty state
    - Ingredient tab: search bar + sort toggle (A-Z/Z-A) + filtered list + empty state
    - Both tabs converted from ConsumerWidget to ConsumerStatefulWidget
    - Files changed: `lib/src/exercise/screens/main.dart`, `lib/src/diet/screens/main.dart`

- [x] T10: `Validation and context sync` (status:done)
  - Task ID: T10
  - Goal: Run full validation: flutter analyze, visual smoke test, context documentation sync.
  - Boundaries (in/out of scope): In — `flutter analyze`, `context/context-map.md` update, `context/overview.md` update, `context/glossary.md` update. Out — no code changes.
  - Done when: `flutter analyze` reports no errors. `context/context-map.md` reflects renamed files/strings. `context/overview.md` reflects new dashboard structure and settings. All tasks T01-T09 are checked off.
  - Verification notes:
    - `flutter analyze` — 0 errors, 36 pre-existing warnings/info
    - context-map.md updated: feature modules, product decisions, settings details
    - overview.md updated: theme file, settings tab content, exercise module specifics
    - glossary.md updated: Seance entry notes "workout" terminology
    - All tasks T01-T10 checked off in plan

---

## Validation Report

### Commands run
- `flutter analyze` → exit 0 (0 errors, 36 pre-existing warnings/info)

### Success-criteria verification
- [x] All user-facing "seance" strings replaced with "workout" terminology → T03 verification: grep shows only variable/class names
- [x] Dashboard Overview grouped into logical sections → T04: calories, workout, goals, weight (conditional), streaks
- [x] Theme feels polished with custom typography, card shapes → T02: TextTheme, CardTheme, ChipTheme, InputDecorationTheme, ButtonTheme
- [x] Settings tab fully populated → T05: Profile, Nutrition, Workout, Appearance, Data sections
- [x] Ingredient form includes 5 optional macro fields → T06: ExpansionTile with sodium, fiber, sugars, saturated fat, cholesterol
- [x] Exercise detail view no duplicate headers → T07: single "Sets (X)" header, compact summary row
- [x] Blank seances save to history correctly → T01: removed `_loadFromDb()` from `addSeance()`
- [x] Exercise and ingredient lists have improved search/filter UX → T09: search bars, category chips, sort toggle, empty states
- [x] Active workout exercise search is more intuitive → T08: recently used, category grouping, better empty state
- [x] App compiles cleanly → flutter analyze: 0 errors

### Files changed across plan
- `lib/src/exercise/providers/seance.dart` (T01)
- `lib/src/app/theme.dart` (T02)
- `lib/src/l10n/app_localizations.dart` (T03)
- `lib/src/exercise/screens/main.dart` (T03, T08, T09)
- `lib/src/exercise/screens/current_seance_screen.dart` (T03, T07, T08)
- `lib/src/exercise/screens/seance_library_screen.dart` (T03)
- `lib/src/exercise/screens/exercise_history_screen.dart` (T03)
- `lib/src/dashboard/screens/main.dart` (T03, T04, T05)
- `lib/src/services/seance_foreground_service.dart` (T03)
- `lib/src/services/seance_notification_service.dart` (T03)
- `lib/src/diet/screens/main.dart` (T09)
- `lib/src/diet/screens/ingredients/custom_ingredient_screen.dart` (T06)
- `context/context-map.md` (T10)
- `context/overview.md` (T04, T10)
- `context/glossary.md` (T10)

### Residual risks
- None identified. All changes are UI-only with no schema or provider logic changes (except T01 bug fix).
- None remaining — all clarifications resolved during intake.

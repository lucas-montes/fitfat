# Context Map

## Core files
- `README.md`: current high-level architecture diagram.
- `lib/main.dart`: app bootstrap, logging, and foreground task callback.
- `lib/src/app/router.dart`: route graph and bottom navigation shell.
- `context/ui/navigation.md`: bottom navigation localization notes (navDiet, navDashboard, navExercise)
- `lib/src/app/main.dart`: `MaterialApp.router` wrapper and theme wiring.

## Data and persistence
- `lib/src/database/tables.dart`: Drift schema for ingredients, meals, seances, templates, goals, and profile.
- `lib/src/database/providers.dart`: production and dev database providers.
- `lib/src/adapters/drift/`: database-backed repositories/adapters.

## Domain models
- `lib/src/models/enums.dart`: shared enums (`Gender`, with `GenderLabel` extension).
- `context/exercise/seance-persistence.md`: seance save/load flow — DB schema, domain model hierarchy, save transaction, load queries, SharedPreferences for active seance, race condition guard.
- `lib/src/models/food.dart`: ingredients, meal entries, and macro calculations.
- `lib/src/models/exercise.dart`: exercise definitions, entries, sets, and active seance model.
- `lib/src/models/dashboard.dart`: user profile, goals, computed macros, chart periods.
- `lib/src/models/seance.dart`: workout templates and history data structures.

## Feature modules
- `lib/src/diet/`: meal log, ingredient editor (with advanced macros section), ingredient management (archive/restore), and related providers.
- `lib/src/dashboard/`: focused daily glance (calories, workout status, goals, streaks), Goals sub-tab, Settings sub-tab (profile, nutrition toggles, data export/delete).
- `lib/src/exercise/`: active workout flow, exercise history, templates, workout library (with search + category filters), training stats, heatmap, and trend charts.
- `lib/src/app/theme.dart`: Material 3 theme with custom typography, card shapes, input decoration, and button styles.

## Product decisions
- The app is single-user and offline-first.
- Training and nutrition are equally important.
- User-facing terminology uses `workout` (not `seance`). Internal class/variable names retain `Seance` for backward compatibility.
- Settings live in the Dashboard tab as a sub-tab (Profile, Nutrition, Workout, Appearance, Data).
- Dashboard is a focused daily glance: calories/macros first, then workout status, goals, weight (conditional), and 7-day streaks.
- Exercise tab contains training stats, heatmap, and trend charts (moved from dashboard).
- Refactors should prioritize readability, testability, and bug reduction.

## Diet-specific notes
- Ingredients will track a `creator` (who added them) and an `isArchived`/hidden flag instead of immediate deletion.
- Support two ingredient kinds: atomic (single food items) and composite (recipes made from other ingredients). Composite ingredients are local by default and need not be shared.
- Ingredients should store a broad set of macros (sodium, fiber, sugars, saturated fat, cholesterol, etc.). The UI will show only the user-selected relevant macros.
- Meal list: month view with infinite scroll loading older meals as the user scrolls.
- Meals are grouped by day and show daily totals; detailed progress and graphs live on the dashboard (optionally a diet graphs tab can be added later).
- There will be a shared/common ingredient database concept for supermarket ingredients (design pending — likely optional download/sync while keeping app offline-first).
- User-selectable macro visibility is preferred; the initial visible set can stay small and user-configurable.
- `creatorId` should not depend on a brittle hardware identifier; use a local installation UUID or a future user/profile id for attribution.

## Localization
- **ARB-based generated localization** via `flutter gen-l10n`.
- `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb` — string definitions.
- `lib/l10n/app_localizations.dart` — generated `AppLocalizations` class (do not edit).
- Configured via `l10n.yaml` at project root.
- Also uses `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations` delegates.
- The old manual `lib/src/l10n/app_localizations.dart` will be removed once all strings are migrated.

## Diet preferences
- `lib/src/diet/providers/diet_preferences.dart`: `dietPreferencesProvider` and `DietPreferencesNotifier` — persisted macro visibility toggles backed by `SharedPreferences`.

## Active plans
- `context/plans/profile-gender-uuid-fix.md`: extract shared Gender enum, rename sex→gender column, derive weight from BodyWeightEntries, use UUID v7 for profile ID. ✅ Done
- `context/plans/exercise-workout-fixes.md`: fix compile errors in DriftSeanceRepository, seance provider, and current_seance_screen.
- `context/plans/ui-ux-overhaul.md`: comprehensive UI/UX pass — theme, naming, dashboard, settings, forms, search/filters, bug fix.
- `context/plans/i18n-arb-migration.md`: migrate from manual `_t()` localization to Flutter standard ARB-based generated localization across all 10 source files.

## Supporting docs
- `doc/simple_db_example.md`: example database context.
- `doc/riverpod_crud_example.md`: example Riverpod CRUD pattern.

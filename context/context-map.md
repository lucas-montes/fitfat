# Context Map

## Core files
- `README.md`: current high-level architecture diagram.
- `lib/main.dart`: app bootstrap, logging, and foreground task callback.
- `lib/src/app/router.dart`: route graph and bottom navigation shell.
- `lib/src/app/main.dart`: `MaterialApp.router` wrapper and theme wiring.

## Data and persistence
- `lib/src/database/tables.dart`: Drift schema for ingredients, meals, seances, templates, goals, and profile.
- `lib/src/database/providers.dart`: production and dev database providers.
- `lib/src/adapters/drift/`: database-backed repositories/adapters.

## Domain models
- `lib/src/models/food.dart`: ingredients, meal entries, and macro calculations.
- `lib/src/models/exercise.dart`: exercise definitions, entries, sets, and active seance model.
- `lib/src/models/dashboard.dart`: user profile, goals, computed macros, chart periods.
- `lib/src/models/seance.dart`: workout templates and history data structures.

## Feature modules
- `lib/src/diet/`: meal log, ingredient editor, and related providers.
- `lib/src/dashboard/`: overview, goals, profile, and chart screens/providers.
- `lib/src/exercise/`: active workout flow, exercise history, templates, and workout library.
- `lib/src/settings/`: standalone settings screen currently represented in the codebase; may move into the dashboard tab.

## Product decisions
- The app is single-user and offline-first.
- Training and nutrition are equally important.
- User-facing terminology should prefer localized `workout` language over `seance`.
- Settings are currently expected to live under the dashboard.
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

## Supporting docs
- `doc/simple_db_example.md`: example database context.
- `doc/riverpod_crud_example.md`: example Riverpod CRUD pattern.

# Diet Module Architecture Decisions

## Status: Accepted

## Context
The diet module handles ingredients (atomic and composite), meals, and user macro display preferences. The key architectural choices are persistence, state management, and localization strategy.

## Decisions

### 1) Database: Drift (SQLite)
- All ingredient, meal, and component data is stored in a local SQLite database via Drift.
- Schema: `Ingredients` table with per-100g macro columns; `IngredientComponents` junction table (composite ingredients); `Meals` and `MealIngredients` junction table.
- Migration strategy: additive schema changes only; no destructive migrations in initial version.
- Seed data: `_seedIngredients()` in `AppDatabase` populates a small set of bundled atomic ingredients on first launch.

### 2) State management: Riverpod
- `ingredientsProvider` (`NotifierProvider<IngredientsController, List<Ingredient>>`): loads all ingredients from Drift, supports CRUD and archive/restore.
- `dietPreferencesProvider` (`NotifierProvider<DietPreferencesNotifier, DietPreferences>`): manages macro visibility.
- Repository pattern: `DriftIngredientRepository` wraps database access and is injected via `ingredientRepositoryProvider`.

### 3) Macro visibility: SharedPreferences
- User's preferred visible macros are serialized as JSON and persisted to `SharedPreferences` under `macro_display_preference`.
- Why not Drift: preferences are a simple key-value map that does not need relational queries, and avoiding a DB round-trip for every UI build is simpler.
- Default: calories, protein, carbs, and fat are visible.
- `DietPreferences.toggleMacro(key)` updates state and persists immediately.

### 4) Composite ingredient pattern
- Composite ingredients use `IngredientComponents` junction table linking `ingredientId` → `componentId` with a `grams` amount.
- Per-100g macros for a composite are computed at construction via `Ingredient.fromComponents()`: sum all component macros at their gram amounts, then scale to 100g.
- Composite ingredients are local-only by default (no `creatorId` distinction — all user-created ingredients use a local installation UUID).
- UI: a "Build from ingredients" toggle in the ingredient editor switches between atomic (direct macro entry) and composite (component picker) modes.

### 5) Archive/restore
- Deleting an ingredient sets `isArchived = true` rather than removing the row, preserving historical meal references.
- Archived ingredients are hidden from normal pickers (`isArchived = false` filter in `getAll()`).
- A dedicated "Archived Ingredients" view allows restore (set `isArchived = false`) or permanent delete (remove from DB).
- Hard delete is allowed from the archived view regardless of meal references; no cascade rewrite is performed.

### 6) Localization
- Manual `AppLocalizations` class with inline en/fr/es strings.
- No `.arb` files or Flutter Intl tooling — translations are maintained by hand in a single file.
- `_t(en, fr, es)` helper uses a simple `switch` on `localeName`.
- Supported locales: `en`, `fr`, `es`. Falls back to `en`.

### 7) Dataset import flow
- On first launch, `AppDatabase._seedIngredients()` inserts a small set of bundled ingredients (name, calories, protein, carbs, fat).
- Bundled ingredients have `creatorId = null` — this distinguishes them from user-created items.
- A future shared/common ingredient database (optional download/sync) is planned but not implemented. It would be additive: import read-only datasets into the local DB while preserving offline-first behavior.
- No CSV/JSON import/export exists in the current version.

### 8) `creatorId` strategy
- Uses a local installation UUID (generated via `uuid` package) to tag user-created ingredients.
- `null` creatorId = system/bundled ingredient.
- Avoids hardware-based identifiers for privacy and portability reasons.
